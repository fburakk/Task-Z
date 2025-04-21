import Foundation
import UIKit

enum TaskPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var color: UIColor {
        switch self {
        case .low:
            return .systemGreen
        case .medium:
            return .systemOrange
        case .high:
            return .systemRed
        }
    }
}

struct Task: Codable {
    let id: Int
    let boardId: Int
    let statusId: Int
    var title: String
    var description: String
    var priority: TaskPriority
    var dueDate: Date?
    var assigneeId: String?
    var position: Int
    let createdBy: String
    let created: Date
    let lastModifiedBy: String?
    let lastModified: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case boardId
        case statusId
        case title
        case description
        case priority
        case dueDate
        case assigneeId
        case position
        case createdBy
        case created
        case lastModifiedBy
        case lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        boardId = try container.decode(Int.self, forKey: .boardId)
        statusId = try container.decode(Int.self, forKey: .statusId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        assigneeId = try container.decodeIfPresent(String.self, forKey: .assigneeId)
        position = try container.decode(Int.self, forKey: .position)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        created = try container.decode(Date.self, forKey: .created)
        lastModifiedBy = try container.decodeIfPresent(String.self, forKey: .lastModifiedBy)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified)
    }
} 