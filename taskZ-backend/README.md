# TaskZ Backend API Documentation

## Getting Started

### Prerequisites
- Docker
- Docker Compose

### Running the Application

#### First Time Setup or Rebuild
1. Build the Docker images:
```bash
docker compose build --no-cache
```

2. Start the application:
```bash
docker compose up -d
```

#### Regular Usage
1. Start the application:
```bash
docker compose up -d
```

2. Stop the application:
```bash
docker compose down
```

The API will be available at `http://localhost:5001`

## API Documentation

All authenticated endpoints require the JWT token in the Authorization header:
```
Authorization: Bearer {your_token}
```

### Authentication

#### Register
```http
POST /api/Auth/register
```
Request body:
```json
{
    "username": "string",
    "email": "string",
    "password": "string",
    "firstName": "string",
    "lastName": "string"
}
```
Response:
```json
{
    "success": true,
    "message": "Registration successful",
    "token": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "username": "string",
    "email": "string"
}
```

#### Login
```http
POST /api/Auth/login
```
Request body:
```json
{
    "email": "string",
    "password": "string"
}
```
Response:
```json
{
    "success": true,
    "message": "Login successful",
    "token": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "username": "string",
    "email": "string"
}
```

### Account Management

#### Get Profile
```http
GET /api/Account/profile
```
Response:
```json
{
    "id": "string",
    "userName": "string",
    "email": "string",
    "firstName": "string",
    "lastName": "string",
    "isVerified": true,
    "roles": ["string"]
}
```

#### Authenticate
```http
POST /api/Account/authenticate
```
Request body:
```json
{
    "email": "string",
    "password": "string"
}
```
Response: Same as login response

#### Confirm Email
```http
GET /api/Account/confirm-email
```
Query parameters:
- userId (string)
- code (string)

Response:
```json
{
    "success": true,
    "message": "Account confirmed successfully"
}
```

#### Forgot Password
```http
POST /api/Account/forgot-password
```
Request body:
```json
{
    "email": "string"
}
```
Response:
```json
{
    "success": true,
    "message": "Password reset instructions sent to email"
}
```

#### Reset Password
```http
POST /api/Account/reset-password
```
Request body:
```json
{
    "email": "string",
    "token": "string",
    "password": "string"
}
```
Response:
```json
{
    "success": true,
    "message": "Password reset successful"
}
```

#### Delete Account
```http
DELETE /api/Account/delete-account
```
Response:
```json
{
    "success": true,
    "message": "Account deleted successfully"
}
```

#### Logout
```http
POST /api/Account/logout
```
Response:
```json
{
    "success": true,
    "message": "Logged out successfully"
}
```

#### Refresh Token
```http
POST /api/Account/refresh-token
```
Request body:
```json
{
    "token": "expired-jwt-token",
    "refreshToken": "refresh-token"
}
```
Response:
```json
{
    "id": "user_id",
    "userName": "string",
    "email": "string",
    "roles": ["string"],
    "isVerified": true,
    "jwToken": "new_jwt_token",
    "refreshToken": "new_refresh_token"
}
```

### Workspace Management

#### Create Workspace
```http
POST /api/Workspace
```
Request body:
```json
{
    "name": "string"
}
```
Response:
```json
{
    "id": number,
    "name": "string",
    "userId": "string",
    "createdBy": "string",
    "created": "datetime"
}
```

#### Get All Workspaces
```http
GET /api/Workspace
```
Response:
```json
[
    {
        "id": number,
        "name": "string",
        "userId": "string",
        "createdBy": "string",
        "created": "datetime"
    }
]
```

#### Get Workspace
```http
GET /api/Workspace/{id}
```
Response: Same as create workspace response

#### Update Workspace
```http
PUT /api/Workspace/{id}
```
Request body:
```json
{
    "name": "string"
}
```
Response: 204 No Content

#### Delete Workspace
```http
DELETE /api/Workspace/{id}
```
Response: 204 No Content

### Board Management

#### Create Board
```http
POST /api/Board
```
Request body:
```json
{
    "workspaceId": number,
    "name": "string",
    "background": "string" // Optional, hex color code
}
```
Response:
```json
{
    "id": number,
    "workspaceId": number,
    "name": "string",
    "background": "string",
    "isArchived": false
}
```

#### Get Boards
```http
GET /api/Board?workspaceId={workspaceId}
```
Response:
```json
[
    {
        "id": number,
        "workspaceId": number,
        "name": "string",
        "background": "string",
        "isArchived": boolean
    }
]
```

#### Get Board
```http
GET /api/Board/{id}
```
Response: Same as create board response

#### Update Board
```http
PUT /api/Board/{id}
```
Request body:
```json
{
    "name": "string",
    "background": "string"
}
```
Response: 204 No Content

#### Archive Board
```http
PUT /api/Board/{id}/archive
```
Response: 204 No Content

#### Get Board Statuses
```http
GET /api/Board/{id}/statuses
```
Response:
```json
[
    {
        "id": number,
        "title": "string",
        "position": number
    }
]
```

#### Get Board Users
```http
GET /api/Board/{id}/users
```
Response:
```json
[
    {
        "id": number,
        "userId": "string",
        "username": "string",
        "role": "string"
    }
]
```

#### Add User to Board
```http
POST /api/Board/{id}/users
```
Request body:
```json
{
    "username": "string",
    "role": "string"  // must be either "viewer" or "editor"
}
```
Response:
```json
{
    "id": number,
    "userId": "string",
    "username": "string",
    "role": "string"
}
```

### Board Status Management

#### Create Status
```http
POST /api/BoardStatus
```
Request body:
```json
{
    "boardId": number,
    "name": "string"
}
```
Response:
```json
{
    "id": number,
    "boardId": number,
    "title": "string",
    "position": number
}
```

### Task Management

#### Get Assigned Tasks
```http
GET /api/Task/assigned
```
Returns all tasks assigned to the current user across all boards they have access to, ordered by due date and priority.

Response:
```json
[
    {
        "id": number,
        "boardId": number,
        "statusId": number,
        "title": "string",
        "description": "string",
        "priority": "string", // "low", "medium", "high"
        "dueDate": "datetime",
        "assigneeId": "string",
        "position": number,
        "createdBy": "string",
        "created": "datetime",
        "lastModifiedBy": "string",
        "lastModified": "datetime"
    }
]
```

#### Get Board Tasks
```http
GET /api/Task/board/{boardId}
```
Returns all tasks in a board, ordered by status and position.

Response:
```json
[
    {
        "id": number,
        "boardId": number,
        "statusId": number,
        "title": "string",
        "description": "string",
        "priority": "string", // "low", "medium", "high"
        "dueDate": "string", // ISO 8601 date format
        "assigneeId": "string",
        "position": number,
        "createdBy": "string",
        "created": "string",
        "lastModifiedBy": "string",
        "lastModified": "string"
    }
]
```

#### Get Status Tasks
```http
GET /api/Task/status/{statusId}
```
Returns all tasks in a specific status column, ordered by position.

Response: Same as Get Board Tasks

#### Create Task
```http
POST /api/Task/board/{boardId}
```
Creates a new task in the specified board. If statusId is provided, the task will be created in that status. Otherwise, it will be placed in the first status column.

Request body:
```json
{
    "title": "string",
    "description": "string",
    "priority": "string", // "low", "medium", "high"
    "dueDate": "string", // ISO 8601 date format
    "assigneeId": "string", // optional
    "statusId": number    // optional - if not provided, task will be added to first status
}
```

Response:
```json
{
    "id": number,
    "boardId": number,
    "statusId": number,
    "title": "string",
    "description": "string",
    "priority": "string",
    "dueDate": "string",
    "assigneeId": "string",
    "position": number,
    "createdBy": "string",
    "created": "string",
    "lastModifiedBy": "string",
    "lastModified": "string"
}
```

Example requests:

1. Create task in first status (To Do):
```json
{
    "title": "First Task",
    "description": "This will go to To Do status",
    "priority": "medium",
    "dueDate": "2024-04-30T10:00:00Z"
}
```

2. Create task in specific status:
```json
{
    "title": "Second Task",
    "description": "This will go to specified status",
    "priority": "high",
    "dueDate": "2024-04-30T10:00:00Z",
    "statusId": 2
}
```

#### Update Task
```http
PUT /api/Task/{id}
```
Updates an existing task. Can be used to update task details, change status, or reorder within a status column.

Request body:
```json
{
    "title": "string",
    "description": "string",
    "priority": "string", // "low", "medium", "high"
    "dueDate": "string", // ISO 8601 date format
    "assigneeId": "string", // optional
    "statusId": number,
    "position": number
}
```

Response: Updated task object (same structure as in Get Board Tasks)

#### Delete Task
```http
DELETE /api/Task/{id}
```
Deletes the specified task.

Response: 204 No Content

## Documentation

### Swagger Documentation
Access the Swagger UI documentation at:
```
http://localhost:5001/swagger
```

### Health Check
Check API health status at:
```
http://localhost:5001/health
```

## Additional Information

### Meta Information

#### Get API Info
```http
GET /info
```
Response:
```json
{
    "version": "string",
    "lastUpdated": "datetime"
}
```

## Response Formats

### Success Response
```json
{
    "success": true,
    "message": "string",
    "data": {}
}
```

### Error Response
```json
{
    "success": false,
    "message": "string",
    "errors": []
}
```

### Paged Response
```json
{
    "pageNumber": number,
    "pageSize": number,
    "totalPages": number,
    "totalRecords": number,
    "data": [],
    "succeeded": true,
    "message": "string"
}
```

## Task Management API

All task endpoints require authentication. Include the JWT token in the Authorization header:
```
Authorization: Bearer {your_token}
```

### Get Assigned Tasks
```http
GET /api/Task/assigned
```
Returns all tasks assigned to the current user across all boards they have access to, ordered by due date and priority.

Response:
```json
[
    {
        "id": number,
        "boardId": number,
        "statusId": number,
        "title": "string",
        "description": "string",
        "priority": "string", // "low", "medium", "high"
        "dueDate": "datetime",
        "assigneeId": "string",
        "position": number,
        "createdBy": "string",
        "created": "datetime",
        "lastModifiedBy": "string",
        "lastModified": "datetime"
    }
]
```

### Get Board Tasks
```http
GET /api/Task/board/{boardId}
```
Returns all tasks in a board, ordered by status and position.

Response:
```json
[
    {
        "id": number,
        "boardId": number,
        "statusId": number,
        "title": "string",
        "description": "string",
        "priority": "string", // "low", "medium", "high"
        "dueDate": "string", // ISO 8601 date format
        "assigneeId": "string",
        "position": number,
        "createdBy": "string",
        "created": "string",
        "lastModifiedBy": "string",
        "lastModified": "string"
    }
]
```

### Get Status Tasks
```http
GET /api/Task/status/{statusId}
```
Returns all tasks in a specific status column, ordered by position.

Response: Same as Get Board Tasks

### Create Task
```http
POST /api/Task/board/{boardId}
```
Creates a new task in the specified board. If statusId is provided, the task will be created in that status. Otherwise, it will be placed in the first status column.

Request body:
```json
{
    "title": "string",
    "description": "string",
    "priority": "string", // "low", "medium", "high"
    "dueDate": "string", // ISO 8601 date format
    "assigneeId": "string", // optional
    "statusId": number    // optional - if not provided, task will be added to first status
}
```

Response:
```json
{
    "id": number,
    "boardId": number,
    "statusId": number,
    "title": "string",
    "description": "string",
    "priority": "string",
    "dueDate": "string",
    "assigneeId": "string",
    "position": number,
    "createdBy": "string",
    "created": "string",
    "lastModifiedBy": "string",
    "lastModified": "string"
}
```

Example requests:

1. Create task in first status (To Do):
```json
{
    "title": "First Task",
    "description": "This will go to To Do status",
    "priority": "medium",
    "dueDate": "2024-04-30T10:00:00Z"
}
```

2. Create task in specific status:
```json
{
    "title": "Second Task",
    "description": "This will go to specified status",
    "priority": "high",
    "dueDate": "2024-04-30T10:00:00Z",
    "statusId": 2
}
```

### Update Task
```http
PUT /api/Task/{id}
```
Updates an existing task. Can be used to update task details, change status, or reorder within a status column.

Request body:
```json
{
    "title": "string",
    "description": "string",
    "priority": "string", // "low", "medium", "high"
    "dueDate": "string", // ISO 8601 date format
    "assigneeId": "string", // optional
    "statusId": number,
    "position": number
}
```

Response: Updated task object (same structure as in Get Board Tasks)

### Delete Task
```http
DELETE /api/Task/{id}
```
Deletes the specified task.

Response: 204 No Content

## Board Status API

### Create Status
```http
POST /api/BoardStatus
```
Creates a new status column in a board.

Request body:
```json
{
    "boardId": number,
    "name": "string"
}
```

Response:
```json
{
    "id": number,
    "boardId": number,
    "name": "string",
    "position": number
}
```

## Task Features

### Position Management
- When creating a task:
  - If statusId is provided, task is placed at the end of the specified status column
  - If statusId is not provided, task is placed at the end of the first status column
- When updating a task's status, it's placed at the end of the new status column
- When updating a task's position within the same status:
  - Other tasks' positions are automatically adjusted
  - Tasks between the old and new positions are shifted accordingly
  - Position values are kept sequential without gaps

### Status Management
- Tasks can be created in any status column by specifying the statusId
- If no statusId is provided during creation, task defaults to the first status
- Status must exist in the board and user must have access to it
- Moving tasks between statuses is done via the update endpoint

### Authorization
- All endpoints verify that the user has access to the board
- Board access is determined by workspace ownership
- Users can only access tasks in boards they have access to

### Validation
- Status ID must belong to the same board when creating or moving tasks
- Position values are automatically bounded to valid ranges
- Required fields are enforced (title, priority)
- Priority must be one of: "low", "medium", "high"
