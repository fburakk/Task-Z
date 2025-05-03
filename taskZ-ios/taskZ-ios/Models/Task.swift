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
    var title: String?
    var description: String?
    var priority: TaskPriority?
    var dueDate: Date?
    var assigneeId: String?
    var assigneeUsername: String?
    var position: Int
    let createdBy: String
    let createdByUsername: String
    let created: Date
    let lastModifiedBy: String?
    let lastModifiedByUsername: String?
    let lastModified: Date?
    
    // Request body for creating a task
    struct CreateRequest: Codable {
        let title: String?
        let description: String?
        let priority: TaskPriority
        let dueDate: Date?
        let assigneeId: String?
        let statusId: Int?
        
        enum CodingKeys: String, CodingKey {
            case title
            case description
            case priority
            case dueDate
            case assigneeId
            case statusId
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(description, forKey: .description)
            try container.encode(priority, forKey: .priority)
            
            // Use ISO8601DateFormatter for encoding dates
            if let dueDate = dueDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                let dateString = formatter.string(from: dueDate)
                try container.encode(dateString, forKey: .dueDate)
            }
            
            try container.encodeIfPresent(assigneeId, forKey: .assigneeId)
            try container.encodeIfPresent(statusId, forKey: .statusId)
        }
    }
    
    // Request body for updating a task
    struct UpdateRequest: Codable {
        var title: String?
        var description: String?
        var priority: TaskPriority?
        var dueDate: Date?
        var assigneeId: String?
        var statusId: Int?
        var position: Int?
        
        enum CodingKeys: String, CodingKey {
            case title
            case description
            case priority
            case dueDate
            case assigneeId
            case statusId
            case position
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(title, forKey: .title)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encodeIfPresent(priority, forKey: .priority)
            
            // Use ISO8601DateFormatter for encoding dates
            if let dueDate = dueDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                let dateString = formatter.string(from: dueDate)
                try container.encode(dateString, forKey: .dueDate)
            }
            
            try container.encodeIfPresent(assigneeId, forKey: .assigneeId)
            try container.encodeIfPresent(statusId, forKey: .statusId)
            try container.encodeIfPresent(position, forKey: .position)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case boardId
        case statusId
        case title
        case description
        case priority
        case dueDate
        case assigneeId
        case assigneeUsername
        case position
        case createdBy
        case createdByUsername
        case created
        case lastModifiedBy
        case lastModifiedByUsername
        case lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        boardId = try container.decode(Int.self, forKey: .boardId)
        statusId = try container.decode(Int.self, forKey: .statusId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority)
        
        // Use ISO8601DateFormatter for decoding dates
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let dueDateString = try container.decodeIfPresent(String.self, forKey: .dueDate) {
            dueDate = formatter.date(from: dueDateString)
        } else {
            dueDate = nil
        }
        
        assigneeId = try container.decodeIfPresent(String.self, forKey: .assigneeId)
        assigneeUsername = try container.decodeIfPresent(String.self, forKey: .assigneeUsername)
        position = try container.decode(Int.self, forKey: .position)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdByUsername = try container.decode(String.self, forKey: .createdByUsername)
        
        if let createdString = try container.decodeIfPresent(String.self, forKey: .created) {
            created = formatter.date(from: createdString) ?? Date()
        } else {
            created = Date()
        }
        
        lastModifiedBy = try container.decodeIfPresent(String.self, forKey: .lastModifiedBy)
        lastModifiedByUsername = try container.decodeIfPresent(String.self, forKey: .lastModifiedByUsername)
        
        if let lastModifiedString = try container.decodeIfPresent(String.self, forKey: .lastModified) {
            lastModified = formatter.date(from: lastModifiedString)
        } else {
            lastModified = nil
        }
    }
} 
