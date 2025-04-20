import Foundation

struct Workspace: Codable {
    let id: Int
    var name: String
    var userId: String
    var createdBy: String
    var created: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userId = "userId"
        case createdBy = "createdBy"
        case created = "created"
    }
} 