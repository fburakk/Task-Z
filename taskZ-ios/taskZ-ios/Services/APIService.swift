import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:5001/api"
    private let session = URLSession.shared
    private let jsonDecoder: JSONDecoder
    
    private init() {
        jsonDecoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - Helper Methods
    private func makeRequest(_ endpoint: String, method: String, body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: baseURL + endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try jsonDecoder.decode(T.self, from: data)
                } catch {
                    throw APIError.unknown("Failed to decode response: \(error.localizedDescription)")
                }
            case 401:
                throw APIError.unauthorized
            case 400...499:
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw APIError.serverError("Client error: \(errorMessage)")
                }
                throw APIError.serverError("Client error: \(httpResponse.statusCode)")
            case 500...599:
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
            default:
                throw APIError.unknown("Unexpected status code: \(httpResponse.statusCode)")
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.handleError(error)
        }
    }
    
    // MARK: - Workspace Endpoints
    func getAllWorkspaces() async throws -> [Workspace] {
        guard let request = makeRequest("/workspace", method: "GET") else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func getWorkspace(id: String) async throws -> Workspace {
        guard let request = makeRequest("/workspace/\(id)", method: "GET") else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func createWorkspace(name: String, ownerId: String) async throws -> Workspace {
        let body = try JSONSerialization.data(withJSONObject: [
            "name": name,
            "owner_id": ownerId
        ])
        guard let request = makeRequest("/workspace", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func updateWorkspace(id: String, name: String?) async throws -> Workspace {
        var updateData: [String: Any] = [:]
        if let name = name { updateData["name"] = name }
        
        let body = try JSONSerialization.data(withJSONObject: updateData)
        guard let request = makeRequest("/workspace/\(id)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func deleteWorkspace(id: String) async throws {
        guard let request = makeRequest("/workspace/\(id)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        let _: EmptyResponse = try await performRequest(request)
    }
    
    // MARK: - Board Endpoints
    func getBoardsInWorkspace(workspaceId: String) async throws -> [Board] {
        guard let request = makeRequest("/board/workspace/\(workspaceId)", method: "GET") else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func getBoard(id: String) async throws -> Board {
        guard let request = makeRequest("/board/\(id)", method: "GET") else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func createBoard(name: String, workspaceId: String, background: String) async throws -> Board {
        let body = try JSONSerialization.data(withJSONObject: [
            "name": name,
            "workspace_id": workspaceId,
            "background": background
        ])
        guard let request = makeRequest("/board", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func updateBoard(id: String, name: String?, background: String?) async throws -> Board {
        var updateData: [String: Any] = [:]
        if let name = name { updateData["name"] = name }
        if let background = background { updateData["background"] = background }
        
        let body = try JSONSerialization.data(withJSONObject: updateData)
        guard let request = makeRequest("/board/\(id)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func deleteBoard(id: String) async throws {
        guard let request = makeRequest("/board/\(id)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        let _: EmptyResponse = try await performRequest(request)
    }
    
    func toggleBoardArchive(id: String, archived: Bool) async throws -> Board {
        let body = try JSONSerialization.data(withJSONObject: ["is_archived": archived])
        guard let request = makeRequest("/board/\(id)/archive", method: "PATCH", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    // MARK: - Board Users Endpoints
    func getBoardUsers(boardId: String) async throws -> [BoardUser] {
        guard let request = makeRequest("/board/\(boardId)/users", method: "GET") else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func addUserToBoard(boardId: String, username: String, role: String) async throws -> BoardUser {
        let body = try JSONSerialization.data(withJSONObject: [
            "username": username,
            "role": role
        ])
        guard let request = makeRequest("/board/\(boardId)/users", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func updateBoardUserRole(boardId: String, username: String, role: String) async throws -> BoardUser {
        let body = try JSONSerialization.data(withJSONObject: ["role": role])
        guard let request = makeRequest("/board/\(boardId)/users/\(username)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func removeUserFromBoard(boardId: String, username: String) async throws {
        guard let request = makeRequest("/board/\(boardId)/users/\(username)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        let _: EmptyResponse = try await performRequest(request)
    }
    
    // MARK: - Board Status Endpoints
    func getBoardStatuses(boardId: String) async throws -> [BoardStatus] {
        guard let request = makeRequest("/board/\(boardId)/statuses", method: "GET") else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func createBoardStatus(boardId: String, title: String, color: String) async throws -> BoardStatus {
        let body = try JSONSerialization.data(withJSONObject: [
            "title": title,
            "color": color,
            "position": statuses.count
        ])
        guard let request = makeRequest("/board/\(boardId)/statuses", method: "POST", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func updateBoardStatus(boardId: String, statusId: String, title: String?, color: String?) async throws -> BoardStatus {
        var updateData: [String: Any] = [:]
        if let title = title { updateData["title"] = title }
        if let color = color { updateData["color"] = color }
        
        let body = try JSONSerialization.data(withJSONObject: updateData)
        guard let request = makeRequest("/board/\(boardId)/statuses/\(statusId)", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    func deleteBoardStatus(boardId: String, statusId: String) async throws {
        guard let request = makeRequest("/board/\(boardId)/statuses/\(statusId)", method: "DELETE") else {
            throw APIError.invalidURL
        }
        let _: EmptyResponse = try await performRequest(request)
    }
    
    func reorderBoardStatuses(boardId: String, statusIds: [String]) async throws -> [BoardStatus] {
        let body = try JSONSerialization.data(withJSONObject: ["status_ids": statusIds])
        guard let request = makeRequest("/board/\(boardId)/statuses/reorder", method: "PUT", body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request)
    }
    
    private var statuses: [BoardStatus] = []
}

// Helper struct for empty responses
private struct EmptyResponse: Decodable {} 
