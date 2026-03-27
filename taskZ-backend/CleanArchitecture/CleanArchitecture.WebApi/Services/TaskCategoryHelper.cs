using System;
using System.Collections.Generic;
using System.Linq;

namespace CleanArchitecture.WebApi.Services
{
    public static class TaskCategoryHelper
    {
        public const string Frontend = "frontend";
        public const string Backend = "backend";
        public const string UiBug = "ui_bug";
        public const string ApiBug = "api_bug";
        public const string Mobile = "mobile";
        public const string Qa = "qa_test";
        public const string Infra = "infra_devops";
        public const string Data = "data";
        public const string Other = "other";

        private static readonly Dictionary<string, string> NormalizationMap = new(StringComparer.OrdinalIgnoreCase)
        {
            { "frontend", Frontend },
            { "front-end", Frontend },
            { "ui", Frontend },
            { "backend", Backend },
            { "back-end", Backend },
            { "api", Backend },
            { "ui_bug", UiBug },
            { "uibug", UiBug },
            { "ux_bug", UiBug },
            { "api_bug", ApiBug },
            { "apibug", ApiBug },
            { "bug", ApiBug },
            { "mobile", Mobile },
            { "ios", Mobile },
            { "android", Mobile },
            { "qa", Qa },
            { "test", Qa },
            { "qa_test", Qa },
            { "infra", Infra },
            { "devops", Infra },
            { "infra_devops", Infra },
            { "ops", Infra },
            { "data", Data },
            { "database", Data },
            { "db", Data },
            { "other", Other }
        };

        public static IReadOnlyList<string> Categories { get; } = new[]
        {
            Frontend,
            Backend,
            UiBug,
            ApiBug,
            Mobile,
            Qa,
            Infra,
            Data,
            Other
        };

        public static string Normalize(string category)
        {
            if (string.IsNullOrWhiteSpace(category))
            {
                return Other;
            }

            var normalized = category.Trim().ToLowerInvariant().Replace(" ", "_").Replace("-", "_");
            if (NormalizationMap.TryGetValue(normalized, out var mapped))
            {
                return mapped;
            }

            return Categories.Contains(normalized) ? normalized : Other;
        }
    }
}
