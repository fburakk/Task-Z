import Foundation

enum TaskPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct Task: Codable {
    let id: Int
    let boardId: Int
    var statusId: Int
    var title: String
    var description: String
    var priority: TaskPriority
    var dueDate: Date?
    var assigneeId: String?
    var position: Int
    let createdBy: String
    let created: Date
    let lastModifiedBy: String
    let lastModified: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "boardId"
        case statusId = "statusId"
        case title
        case description
        case priority
        case dueDate = "dueDate"
        case assigneeId = "assigneeId"
        case position
        case createdBy = "createdBy"
        case created
        case lastModifiedBy = "lastModifiedBy"
        case lastModified = "lastModified"
    }
} 