import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:5001/api"
    private let session = URLSession.shared
    private let jsonDecoder: JSONDecoder
    
    private init() {
        print("APIService: Initializing with baseURL: \(baseURL)")
        jsonDecoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - Helper Methods
    private func makeRequest(_ endpoint: String, method: String, body: Data? = nil) -> URLRequest? {
        print("\nAPIService makeRequest:")
        print("- Endpoint: \(endpoint)")
        print("- Method: \(method)")
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ Failed to create URL from: \(baseURL + endpoint)")
            return nil
        }
        print("✓ Created URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaultsManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✓ Added Authorization header: Bearer \(token)")
        } else {
            print("❌ No auth token available")
        }
        
        if let body = body {
            request.httpBody = body
            if let bodyString = String(data: body, encoding: .utf8) {
                print("✓ Added request body: \(bodyString)")
            }
        }
        
        print("\nFinal request details:")
        print("- URL: \(request.url?.absoluteString ?? "nil")")
        print("- Method: \(request.httpMethod ?? "nil")")
        print("- Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        return request
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, completion: @escaping (Result<T, APIError>) -> Void) {
        print("\nAPIService performRequest:")
        print("- URL: \(request.url?.absoluteString ?? "nil")")
        print("- Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            print("\nResponse received:")
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(APIError.handleError(error)))
                return
            }
            print("✓ No network error")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                completion(.failure(APIError.invalidResponse))
                return
            }
            print("✓ Got HTTP response")
            
            print("\nResponse details:")
            print("- Status code: \(httpResponse.statusCode)")
            print("- Headers: \(httpResponse.allHeaderFields)")
            
            if let data = data {
                print("- Data length: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("- Response body: \(responseString)")
                }
            } else {
                print("- No response data")
            }
            
            switch httpResponse.statusCode {
            case 204:
                // For 204 No Content, create an empty instance if it's EmptyResponse, otherwise fail
                if T.self == EmptyResponse.self {
                    completion(.success(EmptyResponse() as! T))
                } else {
                    completion(.failure(APIError.invalidResponse))
                }
                return
                
            case 200...299:
                guard let data = data else {
                    print("❌ No data in successful response")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                do {
                    print("\nAttempting to decode response as \(T.self)")
                    let decodedResponse = try self?.jsonDecoder.decode(T.self, from: data)
                    guard let decodedResponse = decodedResponse else {
                        print("❌ Self was deallocated during decoding")
                        return
                    }
                    print("✓ Successfully decoded response")
                    completion(.success(decodedResponse))
                } catch {
                    print("❌ Decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("- Key not found: \(key)")
                            print("- Context: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("- Type mismatch: \(type)")
                            print("- Context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("- Value not found for type: \(type)")
                            print("- Context: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("- Data corrupted")
                            print("- Context: \(context.debugDescription)")
                        @unknown default:
                            print("- Unknown decoding error")
                        }
                    }
                    completion(.failure(APIError.unknown("Failed to decode response: \(error.localizedDescription)")))
                }
                
            case 401:
                print("\n⚠️ Unauthorized - attempting token refresh")
                AuthService.shared.refreshToken { [weak self] result in
                    guard let self = self else {
                        print("❌ Self was deallocated during token refresh")
                        return
                    }
                    
                    switch result {
                    case .success(_):
                        print("✓ Token refresh successful")
                        var newRequest = request
                        if let token = UserDefaultsManager.shared.authToken {
                            print("✓ Using new token: \(token)")
                            newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        }
                        print("Retrying request with new token")
                        self.performRequest(newRequest, completion: completion)
                        
                    case .failure(let error):
                        print("❌ Token refresh failed: \(error)")
                        completion(.failure(APIError.unauthorized))
                    }
                }
                
            case 400...499:
                print("\n❌ Client error (\(httpResponse.statusCode))")
                if let data = data {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        print("- Error message: \(errorResponse.message)")
                        completion(.failure(APIError.serverError(errorResponse.message)))
                    } catch {
                        if let errorMessage = String(data: data, encoding: .utf8) {
                            print("- Raw error message: \(errorMessage)")
                            completion(.failure(APIError.serverError("Client error: \(errorMessage)")))
                        } else {
                            print("- No readable error message")
                            completion(.failure(APIError.serverError("Client error with status: \(httpResponse.statusCode)")))
                        }
                    }
                } else {
                    print("- No error data provided")
                    completion(.failure(APIError.serverError("Client error with status: \(httpResponse.statusCode)")))
                }
                
            case 500...599:
                print("\n❌ Server error (\(httpResponse.statusCode))")
                if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    print("- Error details: \(errorMessage)")
                    completion(.failure(APIError.serverError("Server error (\(httpResponse.statusCode)): \(errorMessage)")))
                } else {
                    print("- No error details provided")
                    completion(.failure(APIError.serverError("Server error: \(httpResponse.statusCode)")))
                }
                
            default:
                print("\n❌ Unexpected status code: \(httpResponse.statusCode)")
                completion(.failure(APIError.unknown("Unexpected status code: \(httpResponse.statusCode)")))
            }
        }
        
        print("\nStarting request...")
        task.resume()
    }
    
    // MARK: - Workspace Endpoints
    func getAllWorkspaces(completion: @escaping (Result<[Workspace], APIError>) -> Void) {
        guard let request = makeRequest("/workspace", method: "GET") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request, completion: completion)
    }
    
    func getWorkspace(id: Int, completion: @escaping (Result<Workspace, APIError>) -> Void) {
        guard let request = makeRequest("/workspace/\(id)", method: "GET") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request, completion: completion)
    }
    
    func createWorkspace(name: String, completion: @escaping (Result<Workspace, APIError>) -> Void) {
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "name": name
            ])
            guard let request = makeRequest("/workspace", method: "POST", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func updateWorkspace(id: Int, name: String?, completion: @escaping (Result<Workspace, APIError>) -> Void) {
        do {
            var updateData: [String: Any] = [:]
            if let name = name { updateData["name"] = name }
            
            let body = try JSONSerialization.data(withJSONObject: updateData)
            guard let request = makeRequest("/workspace/\(id)", method: "PUT", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func deleteWorkspace(id: Int, completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let request = makeRequest("/Workspace/\(id)", method: "DELETE") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request) { (result: Result<EmptyResponse, APIError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Board Endpoints
    func getBoardsInWorkspace(workspaceId: Int, completion: @escaping (Result<[Board], APIError>) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL + "/Board") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "workspaceId", value: String(workspaceId))
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let token = UserDefaultsManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Log the request for debugging
        print("Fetching boards for workspace \(workspaceId)")
        print("Request URL: \(request.url?.absoluteString ?? "")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        performRequest(request) { (result: Result<[Board], APIError>) in
            switch result {
            case .success(let boards):
                print("Successfully decoded \(boards.count) boards")
                completion(.success(boards))
            case .failure(let error):
                print("API error: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func getBoard(id: Int, completion: @escaping (Result<Board, APIError>) -> Void) {
        print("\ngetBoard called with id: \(id)")
        
        // Verify token
        if let token = UserDefaultsManager.shared.authToken {
            print("✓ Current token: \(token)")
        } else {
            print("❌ No token available")
            completion(.failure(APIError.unauthorized))
            return
        }
        
        guard let request = makeRequest("/Board/\(id)", method: "GET") else {
            print("❌ Failed to create request")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        print("\nExecuting board request:")
        print("- URL: \(request.url?.absoluteString ?? "nil")")
        print("- Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        performRequest(request) { (result: Result<Board, APIError>) in
            switch result {
            case .success(let board):
                print("✓ Successfully retrieved board: \(board.name)")
                completion(.success(board))
            case .failure(let error):
                print("❌ Failed to get board: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func createBoard(name: String, workspaceId: Int, background: String, completion: @escaping (Result<Board, APIError>) -> Void) {
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "workspaceId": workspaceId,
                "name": name,
                "background": background
            ])
            guard let request = makeRequest("/board", method: "POST", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func updateBoard(id: Int, name: String, background: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        print("\nupdateBoard called with:")
        print("- id: \(id)")
        print("- name: \(name)")
        print("- background: \(background)")
        
        // Validate input
        guard name.count <= 100 else {
            completion(.failure(APIError.unknown("Name must be 100 characters or less")))
            return
        }
        
        guard background.matches(regex: "^#[0-9A-Fa-f]{6}$") else {
            completion(.failure(APIError.unknown("Background must be a valid hex color (e.g., #FF0000)")))
            return
        }
        
        do {
            let updateData: [String: String] = [
                "name": name,
                "background": background
            ]
            
            let body = try JSONSerialization.data(withJSONObject: updateData)
            guard let request = makeRequest("/Board/\(id)", method: "PUT", body: body) else {
                print("❌ Failed to create request URL")
                completion(.failure(APIError.invalidURL))
                return
            }
            
            print("\nSending request to: \(request.url?.absoluteString ?? "nil")")
            print("Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyString = String(data: body, encoding: .utf8) {
                print("Body: \(bodyString)")
            }
            
            let task = session.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("\n❌ Network error: \(error)")
                    completion(.failure(APIError.handleError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("\n❌ Invalid response type")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                print("\nResponse received:")
                print("- Status code: \(httpResponse.statusCode)")
                print("- Headers: \(httpResponse.allHeaderFields)")
                
                switch httpResponse.statusCode {
                case 204:
                    print("\n✓ Board updated successfully")
                    completion(.success(()))
                case 400:
                    print("\n❌ Bad Request: Invalid input")
                    completion(.failure(APIError.serverError("Invalid input. Please check name and background color format.")))
                case 404:
                    print("\n❌ Not Found: Board doesn't exist or no access")
                    completion(.failure(APIError.serverError("Board not found or you don't have access")))
                case 401:
                    print("\n❌ Unauthorized")
                    completion(.failure(APIError.unauthorized))
                default:
                    print("\n❌ Unexpected status code: \(httpResponse.statusCode)")
                    completion(.failure(APIError.unknown("Unexpected status code: \(httpResponse.statusCode)")))
                }
            }
            
            task.resume()
        } catch {
            print("\n❌ Failed to encode request:")
            print("- Error: \(error.localizedDescription)")
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func deleteBoard(id: Int, completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let request = makeRequest("/Board/\(id)", method: "DELETE") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(APIError.handleError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                completion(.success(()))
            case 401:
                completion(.failure(APIError.unauthorized))
            case 400...499:
                completion(.failure(APIError.serverError("Client error with status: \(httpResponse.statusCode)")))
            case 500...599:
                completion(.failure(APIError.serverError("Server error: \(httpResponse.statusCode)")))
            default:
                completion(.failure(APIError.unknown("Unexpected status code: \(httpResponse.statusCode)")))
            }
        }
        
        task.resume()
    }
    
    func toggleBoardArchive(id: Int, archived: Bool, completion: @escaping (Result<Board, APIError>) -> Void) {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["isArchived": archived])
            guard let request = makeRequest("/board/\(id)/archive", method: "PUT", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    // MARK: - Board Status Endpoints
    func getBoardStatuses(boardId: Int, completion: @escaping (Result<[BoardStatus], APIError>) -> Void) {
        guard let request = makeRequest("/Board/\(boardId)/statuses", method: "GET") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request, completion: completion)
    }
    
    func createBoardStatus(boardId: Int, title: String, completion: @escaping (Result<BoardStatus, APIError>) -> Void) {
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "boardId": boardId,
                "name": title
            ])
            guard let request = makeRequest("/BoardStatus", method: "POST", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func updateBoardStatus(boardId: Int, statusId: Int, title: String?, completion: @escaping (Result<BoardStatus, APIError>) -> Void) {
        do {
            var updateData: [String: Any] = [:]
            if let title = title {
                updateData["title"] = title
            }
            
            let body = try JSONSerialization.data(withJSONObject: updateData)
            guard let request = makeRequest("/board/\(boardId)/status/\(statusId)", method: "PUT", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func deleteBoardStatus(boardId: Int, statusId: Int, completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let request = makeRequest("/BoardStatus/\(statusId)", method: "DELETE") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request) { (result: Result<EmptyResponse, APIError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func reorderBoardStatuses(boardId: Int, statusIds: [Int], completion: @escaping (Result<[BoardStatus], APIError>) -> Void) {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["status_ids": statusIds])
            guard let request = makeRequest("/BoardStatus/Reorder", method: "PUT", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    // MARK: - Task Endpoints
    func getBoardTasks(boardId: Int, completion: @escaping (Result<[Task], APIError>) -> Void) {
        guard let request = makeRequest("/task/board/\(boardId)", method: "GET") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request, completion: completion)
    }
    
    func getStatusTasks(statusId: Int, completion: @escaping (Result<[Task], APIError>) -> Void) {
        guard let request = makeRequest("/task/status/\(statusId)", method: "GET") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request, completion: completion)
    }
    
    func createTask(boardId: Int, title: String, description: String, priority: String, dueDate: String?, assigneeId: Int?, completion: @escaping (Result<Task, APIError>) -> Void) {
        do {
            var taskData: [String: Any] = [
                "title": title,
                "description": description,
                "priority": priority
            ]
            if let dueDate = dueDate { taskData["dueDate"] = dueDate }
            if let assigneeId = assigneeId { taskData["assigneeId"] = assigneeId }
            
            let body = try JSONSerialization.data(withJSONObject: taskData)
            guard let request = makeRequest("/task/board/\(boardId)", method: "POST", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func updateTask(id: Int, title: String?, description: String?, priority: String?, dueDate: String?, assigneeId: Int?, statusId: Int?, position: Int?, completion: @escaping (Result<Task, APIError>) -> Void) {
        do {
            var updateData: [String: Any] = [:]
            if let title = title { updateData["title"] = title }
            if let description = description { updateData["description"] = description }
            if let priority = priority { updateData["priority"] = priority }
            if let dueDate = dueDate { updateData["dueDate"] = dueDate }
            if let assigneeId = assigneeId { updateData["assigneeId"] = assigneeId }
            if let statusId = statusId { updateData["statusId"] = statusId }
            if let position = position { updateData["position"] = position }
            
            let body = try JSONSerialization.data(withJSONObject: updateData)
            guard let request = makeRequest("/task/\(id)", method: "PUT", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func deleteTask(id: Int, completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let request = makeRequest("/task/\(id)", method: "DELETE") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request) { (result: Result<EmptyResponse, APIError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Board Users Endpoints
    func getBoardUsers(boardId: Int, completion: @escaping (Result<[BoardUser], APIError>) -> Void) {
        guard let request = makeRequest("/Board/\(boardId)/users", method: "GET") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request, completion: completion)
    }
    
    func addUserToBoard(boardId: Int, username: String, role: String = "viewer", completion: @escaping (Result<BoardUser, APIError>) -> Void) {
        print("\naddUserToBoard called with:")
        print("- boardId: \(boardId)")
        print("- username: \(username)")
        print("- role: \(role)")
        
        // Validate role
        guard ["viewer", "editor"].contains(role.lowercased()) else {
            print("❌ Invalid role: \(role)")
            completion(.failure(APIError.unknown("Invalid role. Must be either 'viewer' or 'editor'.")))
            return
        }
        
        do {
            let requestBody: [String: Any] = [
                "username": username,
                "role": role.lowercased()
            ]
            print("\nRequest body:")
            print(requestBody)
            
            let body = try JSONSerialization.data(withJSONObject: requestBody)
            guard let request = makeRequest("/Board/\(boardId)/users", method: "POST", body: body) else {
                print("❌ Failed to create request URL")
                completion(.failure(APIError.invalidURL))
                return
            }
            
            print("\nSending request to: \(request.url?.absoluteString ?? "nil")")
            print("Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let bodyString = String(data: body, encoding: .utf8) {
                print("Body: \(bodyString)")
            }
            
            performRequest(request) { (result: Result<BoardUser, APIError>) in
                switch result {
                case .success(let boardUser):
                    print("\n✓ Successfully added user to board:")
                    print("- User ID: \(boardUser.userId)")
                    print("- Username: \(boardUser.username)")
                    print("- Role: \(boardUser.role)")
                    completion(.success(boardUser))
                case .failure(let error):
                    print("\n❌ Failed to add user to board:")
                    print("- Error: \(error)")
                    completion(.failure(error))
                }
            }
        } catch {
            print("\n❌ Failed to encode request:")
            print("- Error: \(error.localizedDescription)")
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func updateBoardUserRole(boardId: Int, username: String, role: String, completion: @escaping (Result<BoardUser, APIError>) -> Void) {
        // Validate role
        guard ["viewer", "editor"].contains(role.lowercased()) else {
            completion(.failure(APIError.unknown("Invalid role. Must be either 'viewer' or 'editor'.")))
            return
        }
        
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "role": role.lowercased()
            ])
            guard let request = makeRequest("/Board/\(boardId)/users/\(username)", method: "PUT", body: body) else {
                completion(.failure(APIError.invalidURL))
                return
            }
            performRequest(request, completion: completion)
        } catch {
            completion(.failure(APIError.unknown("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func removeUserFromBoard(boardId: Int, username: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        guard let request = makeRequest("/Board/\(boardId)/users/\(username)", method: "DELETE") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        performRequest(request) { (result: Result<EmptyResponse, APIError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private var statuses: [BoardStatus] = []
}

// Helper struct for empty responses
private struct EmptyResponse: Decodable {}

// Helper extension for hex color validation
private extension String {
    func matches(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
} 
