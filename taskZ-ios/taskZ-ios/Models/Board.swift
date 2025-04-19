import Foundation

struct Board: Codable {
    let id: String
    var name: String
    var workspaceId: String
    var background: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case workspaceId = "workspace_id"
        case background
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct BoardUser: Codable {
    let id: String
    let boardId: String
    let username: String
    var role: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case username
        case role
    }
}

struct BoardStatus: Codable {
    let id: String
    let boardId: String
    var title: String
    var position: Int
    var color: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case boardId = "board_id"
        case title
        case position
        case color
    }
} 