import Foundation

struct Task: Codable {
    let id: Int
    let boardId: Int
    let statusId: Int
    let title: String
    let description: String
    let priority: TaskPriority
    let dueDate: Date?
    let assigneeId: Int?
    let position: Int
    let createdBy: String
    let created: Date
    let lastModifiedBy: String?
    let lastModified: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case statusId = "status_id"
        case title
        case description
        case priority
        case dueDate = "due_date"
        case assigneeId = "assignee_id"
        case position
        case createdBy = "created_by"
        case created
        case lastModifiedBy = "last_modified_by"
        case lastModified = "last_modified"
    }
}

enum TaskPriority: String, Codable {
    case low
    case medium
    case high
} 