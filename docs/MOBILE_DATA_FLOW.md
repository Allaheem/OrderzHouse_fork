# Mobile Data Flow - Flutter App Integration Guide

Recommended Flutter screen structure and API endpoint mapping for OrderzHouse mobile app.

## Overview

This document maps Flutter screens to backend API endpoints, providing a blueprint for building the mobile app that reuses the existing Express.js backend.

---

## Authentication Screens

### 1. Registration Screen (`/register`)

**Endpoints Used:**
- `POST /users/register` - Create new account
- `POST /users/verify-email` - Verify email with OTP

**Flow:**
1. User fills registration form (role, name, email, password, etc.)
2. For freelancers: Select main categories (`category_ids`)
3. Submit → `POST /users/register`
4. Receive OTP via email
5. Enter OTP → `POST /users/verify-email`
6. Navigate to login screen

**Data to Store:**
- `user_id` (temporary, until login)

---

### 2. Login Screen (`/login`)

**Endpoints Used:**
- `POST /users/login` - Login with email/password
- `POST /users/verify-otp` - Verify OTP (if required)
- `POST /users/send-otp` - Resend OTP
- `POST /auth/2fa/verify-login` - Verify 2FA code (if enabled)

**Flow:**
1. User enters email and password
2. Submit → `POST /users/login`
3. **If successful (no OTP/2FA):**
   - Store JWT token securely
   - Store user info
   - Navigate to home screen
4. **If OTP required:**
   - Show OTP input screen
   - User enters OTP → `POST /users/verify-otp`
   - Store token and navigate
5. **If 2FA enabled:**
   - Show 2FA input screen
   - User enters 2FA code → `POST /auth/2fa/verify-login`
   - Store token and navigate

**Data to Store:**
- JWT token (flutter_secure_storage)
- User info (SharedPreferences or local DB)

---

### 3. Forgot Password Screen (`/forgot-password`)

**Endpoints Used:**
- `POST /users/send-otp` - Send password reset OTP
- `PUT /users/update-password` - Update password (after verification)

**Flow:**
1. User enters email
2. Submit → `POST /users/send-otp`
3. Enter OTP
4. Enter new password → `PUT /users/update-password`
5. Navigate to login

---

## Main App Screens

### 4. Home/Dashboard Screen (`/home`)

**Endpoints Used:**
- `GET /users/getUserdata` - Get current user data
- `GET /notifications/count` - Get unread notification count
- `GET /api/stats` - Get dashboard statistics (public)

**Data Displayed:**
- User profile summary
- Notification badge count
- Quick stats (projects, tasks, etc.)
- Recent activity

**Navigation:**
- Projects list
- Tasks list
- Messages
- Profile

---

### 5. Projects List Screen (`/projects`)

**Endpoints Used:**
- `GET /projects/myprojects` - Get user's projects (if authenticated)
- `GET /projects/public/categories` - Get categories (for filtering)
- `GET /projects/public/category/:categoryId` - Get projects by category
- `GET /projects/public/subcategory/:subCategoryId` - Get projects by sub-category
- `GET /projects/public/subsubcategory/:subSubCategoryId` - Get projects by sub-sub-category

**Features:**
- Filter by category/sub-category
- Search projects
- Pull to refresh
- Infinite scroll pagination

**Navigation:**
- Project detail screen
- Create project screen (clients only)

---

### 6. Project Detail Screen (`/projects/:id`)

**Endpoints Used:**
- `GET /projects/project/:projectId/applications` - Get project applications
- `GET /projects/:projectId/files` - Get project files
- `GET /projects/:projectId/timeline` - Get project timeline
- `GET /projects/:projectId/deliveries` - Get project deliveries
- `POST /projects/:projectId/apply` - Apply for project (freelancer)
- `POST /projects/:projectId/assign` - Assign freelancer (client)
- `POST /projects/:projectId/deliver` - Submit delivery (freelancer)
- `POST /projects/:projectId/approve` - Approve work (client)
- `POST /projects/:projectId/request-changes` - Request changes (client)

**Features:**
- View project details
- View project files
- View timeline/activity
- Apply for project (freelancers)
- Manage assignments (clients)
- Submit/approve deliveries

**Navigation:**
- Chat screen (project chat)
- Freelancer profile (if assigned)

---

### 7. Create Project Screen (`/projects/create`)

**Endpoints Used:**
- `GET /category` - Get all categories
- `GET /category/:categoryId/sub-categories` - Get sub-categories
- `GET /category/sub-category/:subCategoryId/sub-sub-categories` - Get sub-sub-categories
- `POST /projects` - Create project (multipart/form-data)

**Flow:**
1. Select category → sub-category → sub-sub-category
2. Fill project details (title, description, budget, etc.)
3. Upload cover picture (optional)
4. Upload project files (optional, max 10)
5. Submit → `POST /projects`
6. Navigate to project detail screen

**Form Fields:**
- Category selection (3 levels)
- Title (10-100 chars)
- Description (100-2000 chars)
- Project type (fixed/hourly/bidding)
- Budget fields (based on type)
- Duration (days/hours)
- Preferred skills
- Files (optional)

---

### 8. Offers Screen (`/offers`)

**Endpoints Used:**
- `GET /offers/projects/open` - Get open bidding projects (freelancer)
- `GET /offers/my-projects/offers` - Get offers for my projects (client)
- `GET /offers/project/:projectId/offers` - Get offers for specific project
- `GET /offers/my/:projectId/pending` - Check if I have pending offer
- `POST /offers/:projectId/offers` - Send offer
- `POST /offers/offers/approve-reject` - Approve/reject offer (client)
- `PUT /offers/offers/:offerId/cancel` - Cancel offer (freelancer)

**Features:**
- Browse open bidding projects (freelancers)
- View offers on my projects (clients)
- Send offer with amount and delivery days
- Approve/reject offers (clients)
- Cancel pending offers (freelancers)

**Navigation:**
- Project detail screen
- Offer detail screen

---

### 9. Tasks Screen (`/tasks`)

**Endpoints Used:**
- `GET /tasks/pool` - Get public task pool
- `GET /tasks/freelancer/my-tasks` - Get my created tasks (freelancer)
- `GET /tasks/freelancer/assigned` - Get assigned tasks (freelancer)
- `GET /tasks/categories` - Get task categories
- `GET /tasks/:id` - Get task details
- `POST /tasks/freelancer` - Create task (freelancer)
- `POST /tasks/client/request/:id` - Request task (client)
- `POST /tasks/client/payment/:id` - Submit payment proof (client)
- `POST /tasks/client/approve/:id` - Approve work (client)

**Features:**
- Browse task pool (public)
- Create tasks (freelancers)
- Request tasks (clients)
- Manage task requests
- Submit/approve work

**Navigation:**
- Task detail screen
- Create task screen

---

### 10. Messages/Chat Screen (`/messages`)

**Endpoints Used:**
- `GET /chats/user-chats` - Get user's chats
- `GET /chats/project/:projectId/messages` - Get project messages
- `GET /chats/task/:taskId/messages` - Get task messages
- `POST /chats/messages` - Send message

**Real-time (Socket.io):**
- Connect to Socket.io server
- Join project/task room
- Listen for new messages
- Send messages via socket

**Features:**
- List of conversations
- Project-based chats
- Task-based chats
- Send text messages
- Send file attachments
- Real-time message updates

**Socket Events:**
- `join-room` - Join chat room
- `send-message` - Send message
- `receive-message` - Receive message
- `typing` - Typing indicator (optional)

---

### 11. Notifications Screen (`/notifications`)

**Endpoints Used:**
- `GET /notifications` - Get notifications (paginated)
- `GET /notifications/count` - Get unread count
- `PUT /notifications/read-all` - Mark all as read
- `PUT /notifications/:id/read` - Mark as read
- `DELETE /notifications/:id` - Delete notification

**Real-time (Socket.io):**
- Listen for new notification events
- Update badge count in real-time

**Features:**
- List of notifications
- Filter by type
- Mark as read
- Delete notifications
- Navigate to related entity (project, offer, etc.)

---

### 12. Profile Screen (`/profile`)

**Endpoints Used:**
- `GET /users/getUserdata` - Get user data
- `PUT /users/edit` - Update profile
- `POST /users/uploadProfilePic` - Upload profile picture
- `POST /users/verify-password` - Verify password
- `PUT /users/update-password` - Update password
- `PUT /users/deactivate` - Deactivate account

**Features:**
- View profile information
- Edit profile
- Change profile picture
- Change password
- Account settings
- Deactivate account

**Navigation:**
- Edit profile screen
- Settings screen
- 2FA settings screen

---

### 13. Settings Screen (`/settings`)

**Endpoints Used:**
- `POST /auth/2fa/generate` - Generate 2FA enrollment (QR in response; secret stored server-side only)
- `POST /auth/2fa/verify` - Verify and enable 2FA
- `POST /auth/2fa/disable` - Disable 2FA
- `GET /subscriptions/admin/all` - Get my subscriptions (if applicable)

**Features:**
- Enable/disable 2FA
- View subscription status
- App preferences
- Privacy settings

---

### 14. Subscriptions Screen (`/subscriptions`)

**Endpoints Used:**
- `GET /plans` - Get all plans
- `POST /stripe/create-checkout-session` - Create checkout session
- `GET /stripe/confirm` - Confirm payment

**Flow:**
1. Display available plans
2. User selects plan
3. Create Stripe checkout session → `POST /stripe/create-checkout-session`
4. Redirect to Stripe checkout (web view)
5. After payment, confirm → `GET /stripe/confirm?session_id=...`
6. Update subscription status

**Features:**
- View subscription plans
- Select and purchase plan
- View current subscription
- Cancel subscription (if applicable)

---

### 15. Payments Screen (`/payments`)

**Endpoints Used:**
- `GET /payments/user/:user_id` - Get user payments

**Features:**
- List of payment history
- Filter by purpose (plan/project)
- View payment details
- Download receipts (if available)

---

### 16. Ratings Screen (`/ratings`)

**Endpoints Used:**
- `GET /ratings/freelancer/:freelancerId` - Get freelancer ratings
- `POST /ratings` - Submit rating (client)

**Features:**
- View freelancer ratings (public)
- Submit rating after project completion (clients)
- View average rating
- Read reviews

---

### 17. Categories Screen (`/categories`)

**Endpoints Used:**
- `GET /category` - Get all categories
- `GET /category/:categoryId/sub-categories` - Get sub-categories
- `GET /category/sub-category/:subCategoryId/sub-sub-categories` - Get sub-sub-categories

**Features:**
- Browse category hierarchy
- Filter projects by category
- Select categories for profile (freelancers)

---

### 18. Freelancer Categories Screen (`/freelancer-categories`)

**Endpoints Used:**
- `GET /freelancerCategories` - Get my categories
- `PUT /freelancerCategories` - Update categories

**Features:**
- View selected categories
- Add/remove categories
- Update profile categories (freelancers only, verified+subscribed)

---

### 19. Blogs Screen (`/blogs`)

**Endpoints Used:**
- `GET /blogs` - Get all blogs
- `GET /blogs/:id` - Get blog details
- `POST /blogs` - Create blog
- `POST /blogs/:id/like` - Like blog
- `POST /blogs/:id/save` - Save blog

**Features:**
- Browse blog posts
- Read blog details
- Create blog post (authenticated)
- Like and save blogs
- Filter by status (approved only for public)

---

### 20. Admin Screens (Admin Only)

**Endpoints Used:**
- `GET /admUser/role/:roleId` - Get users by role
- `GET /projects/admin/projects` - Get all projects
- `GET /tasks/admin` - Get all tasks
- `GET /payments/admin/all` - Get all payments
- `GET /verification/verifications` - Get pending verifications
- `PUT /verification/verifications/:id/approve` - Approve verification
- `PUT /verification/verifications/:id/reject` - Reject verification
- `GET /logs` - Get system logs

**Features:**
- User management
- Project oversight
- Task management
- Payment tracking
- Verification approvals
- System logs

---

## Data Flow Patterns

### 1. Authentication Flow
```
Registration → Email Verification → Login → (OTP/2FA if needed) → Home
```

### 2. Project Flow (Client)
```
Create Project → View Projects → Manage Applications → Assign Freelancer → 
Approve Deliveries → Complete Project → Rate Freelancer
```

### 3. Project Flow (Freelancer)
```
Browse Projects → Apply/Submit Offer → Accept Assignment → 
Work on Project → Submit Delivery → Resubmit if needed → Get Approved
```

### 4. Task Flow (Freelancer)
```
Create Task → Task Listed in Pool → Client Requests → 
Accept Request → Client Pays → Complete Work → Get Approved
```

### 5. Task Flow (Client)
```
Browse Task Pool → Request Task → Submit Payment → 
Freelancer Completes → Approve Work → Leave Review
```

### 6. Payment Flow
```
Select Plan → Stripe Checkout → Payment Confirmation → 
Subscription Active → Access Premium Features
```

---

## State Management Recommendations

### Recommended: Provider or Riverpod

**Global State:**
- Authentication state (user, token)
- User profile data
- Notification count
- Subscription status

**Local State:**
- Form inputs
- UI state (loading, errors)
- Pagination state

**Example Structure:**
```dart
// Auth Provider
class AuthProvider extends ChangeNotifier {
  String? token;
  User? user;
  bool isAuthenticated;
  
  Future<void> login(String email, String password) async {
    // Call POST /users/login
    // Store token
    // Update state
  }
}

// Projects Provider
class ProjectsProvider extends ChangeNotifier {
  List<Project> projects = [];
  bool isLoading = false;
  
  Future<void> fetchProjects() async {
    // Call GET /projects/myprojects
    // Update projects list
  }
}
```

---

## API Client Setup

### Recommended: Dio or http package

**Base Configuration:**
```dart
class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://orderzhouse-backend.onrender.com',
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ),
  );
  
  // Add interceptor for JWT token
  ApiClient() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 403) {
            // Token expired, redirect to login
          }
          return handler.next(error);
        },
      ),
    );
  }
}
```

---

## File Upload Handling

### Multipart Requests
```dart
Future<void> uploadProfilePic(File image) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      image.path,
      filename: 'profile.jpg',
    ),
  });
  
  final response = await dio.post(
    '/users/uploadProfilePic',
    data: formData,
  );
}
```

---

## Real-time Features (Socket.io)

### Setup
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  
  void connect(String token) {
    socket = IO.io(
      'https://orderzhouse-backend.onrender.com',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .build(),
    );
    
    socket!.onConnect((_) {
      print('Connected to server');
    });
    
    socket!.on('receive-message', (data) {
      // Handle new message
    });
  }
  
  void joinRoom(String roomId) {
    socket!.emit('join-room', roomId);
  }
  
  void sendMessage(String roomId, String content) {
    socket!.emit('send-message', {
      'room_id': roomId,
      'content': content,
    });
  }
}
```

---

## Error Handling

### Common Error Scenarios

1. **401/403 - Authentication Error**
   - Clear stored token
   - Redirect to login screen

2. **400 - Validation Error**
   - Display error message from response
   - Highlight invalid fields

3. **500 - Server Error**
   - Show generic error message
   - Log error for debugging

4. **Network Error**
   - Show offline message
   - Retry mechanism

**Example:**
```dart
try {
  final response = await apiClient.get('/projects/myprojects');
  return response.data;
} on DioException catch (e) {
  if (e.response?.statusCode == 403) {
    // Token expired
    await storage.delete(key: 'jwt_token');
    Navigator.pushReplacementNamed(context, '/login');
  } else {
    // Show error message
    showError(e.response?.data['message'] ?? 'An error occurred');
  }
}
```

---

## Caching Strategy

### Recommended: Hive or SharedPreferences

**Cache:**
- User profile data
- Categories list
- Plans list
- Recent projects/tasks

**Cache Invalidation:**
- On logout
- On profile update
- After creating/updating projects
- Manual refresh

---

## Navigation Structure

```
/ (Splash)
├── /login
├── /register
└── /home (Main App)
    ├── /projects
    │   ├── /projects/create
    │   └── /projects/:id
    ├── /offers
    ├── /tasks
    │   └── /tasks/create
    ├── /messages
    │   └── /messages/:roomId
    ├── /notifications
    ├── /profile
    │   ├── /profile/edit
    │   └── /settings
    ├── /subscriptions
    ├── /payments
    └── /blogs
```

---

## Summary

1. **Authentication**: JWT-based with OTP and 2FA support
2. **Projects**: Full CRUD with file uploads and real-time updates
3. **Tasks**: Freelancer-created tasks with client requests
4. **Messaging**: Real-time chat via Socket.io
5. **Payments**: Stripe integration for subscriptions
6. **Notifications**: Real-time push notifications
7. **File Uploads**: Multipart form data to Cloudinary
8. **State Management**: Provider/Riverpod for global state
9. **Caching**: Local storage for offline support
10. **Error Handling**: Comprehensive error handling with user feedback
