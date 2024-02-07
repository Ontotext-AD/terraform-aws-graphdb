# asdasdasda Title

## Users
| qwe | qwe |


```http request
Users
GET /api/users: Retrieve all users(admin access)
GET /api/users/{userId}: Get user details
POST /api/users: Create a new user
Payload
Content-Type: application/json
{
"username": "new_username",
"password": "new_password",
"email": "new_email@example.com"
}
```


PATCH /users/{userId}: Update user information(authentication required)
Payload
Host: example.com
Content-Type: application/json
Authorization: Bearer <token>
{
"username": "new_username",
"password": "new_password",
"email": "new_email@example.com"
}

DELETE /users/{userId}: Delete a user(authentication required)
Payload
Host: example.com
Authorization: Bearer <token>

Posts
GET /posts: Retrieve all posts
GET /posts/{postId}: Retrieve a specific post
POST /posts: Create a new post(authentication required)
Payload
Host: example.com
Content-Type: application/json
Authorization: Bearer <token>
{
"title": "Post Title",
"content": "Post Content"
}

PATCH /posts/{postId}: Update a specific post(authentication required, user must be owner)
Payload
Host: example.com
Content-Type: application/json
Authorization: Bearer <token>
{
"title": "Post Title",
"content": "Post Content"
}

DELETE /posts/{postId}: Delete a specific post(authentication required, user must be owner)
Payload
Host: example.com
Authorization: Bearer <token>

Comments
GET /posts/{postId}/comments: Retrieve all comments for a specific post
GET /comments/{commentId}: Retrieve a specific comment
POST /posts/{postId}/comments: Add a new comment to a specific post(authentication required)
Payload
Host: example.com
Content-Type: application/json
Authorization: Bearer <token>
{
"content": "Comment Content"
}

PATCH /comments/{commentId}: Update a specific comment(authentication required, user must be owner)
Payload
Host: example.com
Content-Type: application/json
Authorization: Bearer <token>
{
"content": "Updated Comment Content"
}

DELETE /comments/{commentId}: Delete a specific comment(authentication required, user must be owner)
Payload
Host: example.com
Authorization: Bearer <token>
