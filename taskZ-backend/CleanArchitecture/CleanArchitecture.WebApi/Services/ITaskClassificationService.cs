using System.Threading;
using System.Threading.Tasks;

namespace CleanArchitecture.WebApi.Services
{
    public interface ITaskClassificationService
    {
        Task<TaskClassificationResult> ClassifyAsync(string title, string description, CancellationToken cancellationToken = default);
    }

    public class TaskClassificationResult
    {
        public string Category { get; set; } = TaskCategoryHelper.Other;
        public double Confidence { get; set; }
        public string Source { get; set; } = "fallback";
    }
}
