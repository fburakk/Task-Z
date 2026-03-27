using System;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using CleanArchitecture.WebApi.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace CleanArchitecture.WebApi.Services
{
    public class OllamaTaskClassificationService : ITaskClassificationService
    {
        private static readonly string[] UiSignals =
        {
            "ui", "ux", "frontend", "css", "html", "style", "theme", "color", "layout", "screen", "page",
            "button", "modal", "navbar", "sidebar", "pixel", "responsive"
        };

        private static readonly string[] ApiSignals =
        {
            "api", "endpoint", "controller", "service", "swagger", "postman", "request", "response",
            "payload", "status code", "http", "json", "jwt", "auth", "token", "database", "sql", "query",
            "timeout", "gateway", "500", "401", "403", "404"
        };

        private static readonly string[] BugSignals =
        {
            "bug", "fix", "broken", "error", "issue", "does not work", "not working", "incorrect"
        };
        private static readonly string[] MobileSignals = { "mobile", "ios", "android", "swift", "xcode", "kotlin", "react native", "flutter" };
        private static readonly string[] QaSignals = { "qa", "test", "e2e", "integration test", "regression", "smoke test", "unit test" };
        private static readonly string[] InfraSignals = { "infra", "devops", "deploy", "docker", "kubernetes", "ci", "pipeline", "helm", "terraform" };
        private static readonly string[] DataSignals = { "data", "etl", "warehouse", "report", "dashboard", "dataset", "analytics", "bi" };

        private readonly HttpClient _httpClient;
        private readonly TaskClassificationSettings _settings;
        private readonly ILogger<OllamaTaskClassificationService> _logger;

        public OllamaTaskClassificationService(
            HttpClient httpClient,
            IOptions<TaskClassificationSettings> settings,
            ILogger<OllamaTaskClassificationService> logger)
        {
            _httpClient = httpClient;
            _settings = settings.Value;
            _logger = logger;
        }

        public async Task<TaskClassificationResult> ClassifyAsync(string title, string description, CancellationToken cancellationToken = default)
        {
            if (TryFastPathClassify(title, description, out var fastPath))
            {
                return fastPath;
            }

            var fallback = ApplyHeuristicOverrides(
                title,
                description,
                FallbackClassify(title, description, "fallback"));

            if (!_settings.Enabled || string.IsNullOrWhiteSpace(_settings.BaseUrl) || string.IsNullOrWhiteSpace(_settings.Model))
            {
                fallback.Source = "disabled";
                return fallback;
            }

            try
            {
                _httpClient.BaseAddress = new Uri(_settings.BaseUrl.TrimEnd('/') + "/");
                _httpClient.Timeout = TimeSpan.FromSeconds(Math.Max(3, _settings.TimeoutSeconds));

                var prompt = BuildPrompt(title, description);
                var payload = new OllamaGenerateRequest
                {
                    Model = _settings.Model,
                    Prompt = prompt,
                    Stream = false,
                    Format = "json",
                    Options = new OllamaGenerateOptions
                    {
                        Temperature = _settings.Temperature
                    }
                };

                var json = JsonSerializer.Serialize(payload);
                using var content = new StringContent(json, Encoding.UTF8, "application/json");
                using var response = await _httpClient.PostAsync("api/generate", content, cancellationToken);
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Ollama task classification failed with status {StatusCode}", response.StatusCode);
                    return fallback;
                }

                var raw = await response.Content.ReadAsStringAsync(cancellationToken);
                var ollamaResponse = JsonSerializer.Deserialize<OllamaGenerateResponse>(raw);
                var modelText = ollamaResponse?.Response;
                if (string.IsNullOrWhiteSpace(modelText))
                {
                    return fallback;
                }

                var extracted = ExtractJsonObject(modelText);
                if (string.IsNullOrWhiteSpace(extracted))
                {
                    return fallback;
                }

                var modelResult = JsonSerializer.Deserialize<TaskClassificationModelResult>(
                    extracted,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (modelResult == null)
                {
                    return fallback;
                }

                var category = TaskCategoryHelper.Normalize(modelResult.Category ?? modelResult.WorkCategory);
                var confidence = ParseConfidence(modelResult.Confidence);
                if (category == TaskCategoryHelper.Other && fallback.Category != TaskCategoryHelper.Other)
                {
                    return fallback;
                }

                var modelClassification = new TaskClassificationResult
                {
                    Category = category,
                    Confidence = confidence,
                    Source = "ollama"
                };

                return ApplyHeuristicOverrides(title, description, modelClassification);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Ollama task classification failed, fallback classification will be used.");
                return fallback;
            }
        }

        private static string BuildPrompt(string title, string description)
        {
            var categories = string.Join(", ", TaskCategoryHelper.Categories.Select(c => $"\"{c}\""));
            return $@"You are a strict task classifier.
Classify the task into exactly one category from this list: [{categories}].
Use these rules:
- UI/visual/theme/style/page/button/screen issues => frontend or ui_bug.
- API/request/response/endpoint/service/auth/database issues => backend or api_bug.
- If text is a bug/fix for UI, use ui_bug (NOT api_bug).
- If text is a bug/fix for API/backend, use api_bug.
Return ONLY valid JSON (no markdown), format:
{{
  ""category"": ""<one-category>"",
  ""confidence"": <number-between-0-and-1>
}}
Task title: {title}
Task description: {description}";
        }

        private static bool TryFastPathClassify(string title, string description, out TaskClassificationResult result)
        {
            var text = $"{title} {description}".ToLowerInvariant();
            var hasUiSignals = ContainsAny(text, UiSignals);
            var hasApiSignals = ContainsAny(text, ApiSignals);
            var hasBugSignals = ContainsAny(text, BugSignals);

            if (hasUiSignals && !hasApiSignals)
            {
                result = new TaskClassificationResult
                {
                    Category = hasBugSignals ? TaskCategoryHelper.UiBug : TaskCategoryHelper.Frontend,
                    Confidence = 0.9,
                    Source = "heuristic_fast_ui"
                };
                return true;
            }

            if (hasApiSignals && !hasUiSignals)
            {
                result = new TaskClassificationResult
                {
                    Category = hasBugSignals ? TaskCategoryHelper.ApiBug : TaskCategoryHelper.Backend,
                    Confidence = 0.88,
                    Source = "heuristic_fast_api"
                };
                return true;
            }

            if (ContainsAny(text, MobileSignals))
            {
                result = new TaskClassificationResult
                {
                    Category = TaskCategoryHelper.Mobile,
                    Confidence = 0.86,
                    Source = "heuristic_fast_mobile"
                };
                return true;
            }

            if (ContainsAny(text, QaSignals))
            {
                result = new TaskClassificationResult
                {
                    Category = TaskCategoryHelper.Qa,
                    Confidence = 0.84,
                    Source = "heuristic_fast_qa"
                };
                return true;
            }

            if (ContainsAny(text, InfraSignals))
            {
                result = new TaskClassificationResult
                {
                    Category = TaskCategoryHelper.Infra,
                    Confidence = 0.84,
                    Source = "heuristic_fast_infra"
                };
                return true;
            }

            if (ContainsAny(text, DataSignals))
            {
                result = new TaskClassificationResult
                {
                    Category = TaskCategoryHelper.Data,
                    Confidence = 0.84,
                    Source = "heuristic_fast_data"
                };
                return true;
            }

            result = new TaskClassificationResult
            {
                Category = TaskCategoryHelper.Other,
                Confidence = 0.35,
                Source = "heuristic_fast_none"
            };
            return false;
        }

        private static TaskClassificationResult ApplyHeuristicOverrides(
            string title,
            string description,
            TaskClassificationResult result)
        {
            var text = $"{title} {description}".ToLowerInvariant();
            var hasUiSignals = ContainsAny(text, UiSignals);
            var hasApiSignals = ContainsAny(text, ApiSignals);
            var hasBugSignals = ContainsAny(text, BugSignals);

            if (hasUiSignals && !hasApiSignals)
            {
                var forcedCategory = hasBugSignals ? TaskCategoryHelper.UiBug : TaskCategoryHelper.Frontend;
                if (!string.Equals(result.Category, forcedCategory, StringComparison.OrdinalIgnoreCase))
                {
                    result.Category = forcedCategory;
                    result.Confidence = Math.Max(result.Confidence, 0.82);
                    result.Source = $"{result.Source}+heuristic_ui";
                }

                return result;
            }

            if (hasApiSignals && !hasUiSignals)
            {
                var forcedCategory = hasBugSignals ? TaskCategoryHelper.ApiBug : TaskCategoryHelper.Backend;
                if (!string.Equals(result.Category, forcedCategory, StringComparison.OrdinalIgnoreCase))
                {
                    result.Category = forcedCategory;
                    result.Confidence = Math.Max(result.Confidence, 0.8);
                    result.Source = $"{result.Source}+heuristic_api";
                }
            }

            return result;
        }

        private static string ExtractJsonObject(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
            {
                return null;
            }

            var text = input.Trim();
            if (text.StartsWith("```", StringComparison.Ordinal))
            {
                var firstNewLine = text.IndexOf('\n');
                var lastFence = text.LastIndexOf("```", StringComparison.Ordinal);
                if (firstNewLine >= 0 && lastFence > firstNewLine)
                {
                    text = text.Substring(firstNewLine + 1, lastFence - firstNewLine - 1).Trim();
                }
            }

            if (TryParse(text))
            {
                return text;
            }

            var start = text.IndexOf('{');
            var end = text.LastIndexOf('}');
            if (start >= 0 && end > start)
            {
                var candidate = text.Substring(start, end - start + 1);
                if (TryParse(candidate))
                {
                    return candidate;
                }
            }

            return null;
        }

        private static bool TryParse(string json)
        {
            try
            {
                using var _ = JsonDocument.Parse(json);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static double ParseConfidence(JsonElement? confidence)
        {
            if (confidence == null)
            {
                return 0.5;
            }

            var value = confidence.Value;
            double parsed;
            if (value.ValueKind == JsonValueKind.Number && value.TryGetDouble(out parsed))
            {
                return Clamp01(parsed);
            }

            if (value.ValueKind == JsonValueKind.String &&
                double.TryParse(value.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out parsed))
            {
                return Clamp01(parsed);
            }

            return 0.5;
        }

        private static double Clamp01(double value)
        {
            if (value < 0)
            {
                return 0;
            }

            if (value > 1)
            {
                return 1;
            }

            return value;
        }

        private static TaskClassificationResult FallbackClassify(string title, string description, string source)
        {
            var text = $"{title} {description}".ToLowerInvariant();
            var category = TaskCategoryHelper.Other;

            if (ContainsAny(text, "frontend", "css", "html", "react", "vue", "ui", "ux", "button", "layout"))
            {
                category = TaskCategoryHelper.Frontend;
            }
            else if (ContainsAny(text, "backend", "api", "endpoint", "service", "controller", "auth", "jwt", "database", "sql", "request", "response", "payload"))
            {
                category = TaskCategoryHelper.Backend;
            }
            else if (ContainsAny(text, "bug", "fix", "broken", "error", "issue"))
            {
                category = ContainsAny(text, "ui", "screen", "modal", "button", "css")
                    ? TaskCategoryHelper.UiBug
                    : TaskCategoryHelper.ApiBug;
            }
            else if (ContainsAny(text, "ios", "android", "swift", "xcode", "mobile"))
            {
                category = TaskCategoryHelper.Mobile;
            }
            else if (ContainsAny(text, "qa", "test", "e2e", "regression"))
            {
                category = TaskCategoryHelper.Qa;
            }
            else if (ContainsAny(text, "devops", "infra", "deploy", "docker", "kubernetes", "ci", "pipeline"))
            {
                category = TaskCategoryHelper.Infra;
            }
            else if (ContainsAny(text, "etl", "warehouse", "analytics", "report", "dataset"))
            {
                category = TaskCategoryHelper.Data;
            }

            return new TaskClassificationResult
            {
                Category = category,
                Confidence = category == TaskCategoryHelper.Other ? 0.35 : 0.6,
                Source = source
            };
        }

        private static bool ContainsAny(string value, params string[] probes)
        {
            return probes.Any(p => value.Contains(p, StringComparison.Ordinal));
        }

        private class OllamaGenerateRequest
        {
            [JsonPropertyName("model")]
            public string Model { get; set; }

            [JsonPropertyName("prompt")]
            public string Prompt { get; set; }

            [JsonPropertyName("stream")]
            public bool Stream { get; set; }

            [JsonPropertyName("format")]
            public string Format { get; set; }

            [JsonPropertyName("options")]
            public OllamaGenerateOptions Options { get; set; }
        }

        private class OllamaGenerateOptions
        {
            [JsonPropertyName("temperature")]
            public double Temperature { get; set; }
        }

        private class OllamaGenerateResponse
        {
            [JsonPropertyName("response")]
            public string Response { get; set; }
        }

        private class TaskClassificationModelResult
        {
            [JsonPropertyName("category")]
            public string Category { get; set; }

            [JsonPropertyName("workCategory")]
            public string WorkCategory { get; set; }

            [JsonPropertyName("confidence")]
            public JsonElement? Confidence { get; set; }
        }
    }
}
