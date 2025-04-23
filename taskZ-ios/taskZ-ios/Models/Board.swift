import Foundation

struct Board: Codable {
    let id: Int
    var name: String
    var workspaceId: Int
    var background: String
    var isArchived: Bool
    let createdBy: String
    let createdByUsername: String
    let created: Date
    let lastModifiedBy: String?
    let lastModifiedByUsername: String?
    let lastModified: Date?
    var users: [BoardUser]
    var statuses: [BoardStatus]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case workspaceId = "workspaceId"
        case background
        case isArchived = "isArchived"
        case createdBy = "createdBy"
        case createdByUsername = "createdByUsername"
        case created = "created"
        case lastModifiedBy = "lastModifiedBy"
        case lastModifiedByUsername = "lastModifiedByUsername"
        case lastModified = "lastModified"
        case users
        case statuses
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        workspaceId = try container.decode(Int.self, forKey: .workspaceId)
        background = try container.decode(String.self, forKey: .background)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdByUsername = try container.decode(String.self, forKey: .createdByUsername)
        
        // Use ISO8601DateFormatter for decoding dates
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
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
        
        users = try container.decodeIfPresent([BoardUser].self, forKey: .users) ?? []
        statuses = try container.decodeIfPresent([BoardStatus].self, forKey: .statuses) ?? []
    }
}

struct BoardUser: Codable {
    let id: Int
    let userId: String
    let username: String
    var role: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userId"
        case username
        case role
    }
}

struct BoardStatus: Codable {
    let id: Int
    let title: String
    let position: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case position
    }
} 