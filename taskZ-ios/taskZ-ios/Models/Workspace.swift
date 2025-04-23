import Foundation

struct Workspace: Codable {
    let id: Int
    var name: String
    var userId: String
    var username: String
    var createdBy: String
    var createdByUsername: String
    var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userId = "userId"
        case username
        case createdBy = "createdBy"
        case createdByUsername = "createdByUsername"
        case created = "created"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
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
    }
} 