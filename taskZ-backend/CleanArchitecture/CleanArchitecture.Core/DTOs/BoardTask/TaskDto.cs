// ... existing code ...
    public class CreateTaskRequest
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public string Priority { get; set; }
        public DateTime? DueDate { get; set; }
        public string AssigneeId { get; set; }
        public int? StatusId { get; set; }  // Optional status ID
    }
// ... existing code ...