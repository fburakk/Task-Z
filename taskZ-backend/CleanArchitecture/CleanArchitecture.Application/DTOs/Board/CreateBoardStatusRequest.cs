using System.ComponentModel.DataAnnotations;

namespace CleanArchitecture.Core.DTOs.Board
{
    public class CreateBoardStatusRequest
    {
        [Required]
        [StringLength(50)]
        public string Title { get; set; }

        [Required]
        [Range(0, int.MaxValue)]
        public int Position { get; set; }
    }
} 