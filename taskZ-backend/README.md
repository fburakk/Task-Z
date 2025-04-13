# TaskZ Backend API Documentation

## Getting Started

### Prerequisites
- Docker
- Docker Compose

### Running the Application
1. Start the application:
```bash
docker compose up -d
```

2. Stop the application:
```bash
docker compose down
```

The API will be available at `http://localhost:5001`

## Authentication

### Register
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

### Login
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

### Refresh Token
```http
POST /api/Account/refresh-token
```
Request body:
```json
{
    "token": "your-expired-jwt-token",
    "refreshToken": "your-refresh-token"
}
```

When you login or register, you'll receive both a JWT token and a refresh token. The JWT token expires after the configured duration (default: 60 minutes), while the refresh token is valid for 7 days.

To refresh your token:
1. Store both tokens securely on the client side
2. Use the JWT token for API requests in the Authorization header
3. When you get a 401 Unauthorized response, call the refresh-token endpoint
4. Use the new JWT token and refresh token pair received in the response

Note: Refresh tokens are single-use. Each refresh operation invalidates the old refresh token and generates a new one.

## Account Management

### Get Profile
```http
GET /api/Account/profile
```
Requires authentication. Returns user profile information including:
- User ID
- Username
- Email
- First Name
- Last Name
- Verification Status
- Roles

### Delete Account
```http
DELETE /api/Account/delete-account
```
Requires authentication. Permanently deletes the user's account.

### Logout
```http
POST /api/Account/logout
```
Requires authentication. Logs out the current user and invalidates their session.

## Products API (v1)
Requires authentication. Include the JWT token in the Authorization header:
```
Authorization: Bearer {your_token}
```

### Get All Products
```http
GET /api/v1/Product
```
Query parameters:
- pageSize (optional)
- pageNumber (optional)

### Get Product by ID
```http
GET /api/v1/Product/{id}
```

### Create Product
```http
POST /api/v1/Product
```
Request body:
```json
{
    "name": "string",
    "barcode": "string",
    "description": "string",
    "rate": number
}
```

### Update Product
```http
PUT /api/v1/Product/{id}
```
Request body:
```json
{
    "id": number,
    "name": "string",
    "barcode": "string",
    "description": "string",
    "rate": number
}
```

### Delete Product
```http
DELETE /api/v1/Product/{id}
```

## Categories API (v1)
Requires Admin role. Include the JWT token in the Authorization header:
```
Authorization: Bearer {your_token}
```

### Get All Categories
```http
GET /api/v1/Category
```
Query parameters:
- pageSize (optional)
- pageNumber (optional)

### Create Category
```http
POST /api/v1/Category
```
Request body:
```json
{
    "name": "string",
    "description": "string"
}
```

## Response Format

### Success Response
```json
{
    "success": true,
    "message": "string",
    "data": {}
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

### Error Response
```json
{
    "success": false,
    "message": "string",
    "errors": []
}
```

## Database Access

### Using pgAdmin
1. Access pgAdmin at `http://localhost:5050`
2. Login credentials:
   - Email: admin@admin.com
   - Password: admin
3. Connect to database:
   - Host: db
   - Port: 5432
   - Database: CleanArchitectureDb
   - Username: sa
   - Password: YourStrong@Passw0rd

## Additional Information

### Meta Information
```http
GET /info
```
Returns version and last update information of the API.

### Swagger Documentation
Access the Swagger UI documentation at:
```
http://localhost:5001/swagger
``` 