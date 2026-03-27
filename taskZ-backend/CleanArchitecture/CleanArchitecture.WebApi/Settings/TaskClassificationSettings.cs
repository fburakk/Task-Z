namespace CleanArchitecture.WebApi.Settings
{
    public class TaskClassificationSettings
    {
        public bool Enabled { get; set; } = true;
        public string BaseUrl { get; set; } = "http://localhost:11434";
        public string Model { get; set; } = "llama3:8b";
        public int TimeoutSeconds { get; set; } = 12;
        public double Temperature { get; set; } = 0.1;
    }
}
