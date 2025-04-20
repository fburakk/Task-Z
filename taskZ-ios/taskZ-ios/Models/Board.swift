import Foundation

struct Board: Codable {
    let id: Int
    var name: String
    var workspaceId: Int
    var background: String
    var isArchived: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case workspaceId = "workspaceId"
        case background
        case isArchived = "isArchived"
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