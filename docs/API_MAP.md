# API Map - OrderzHouse Backend

Complete reference of all Express.js API endpoints for Flutter mobile app integration.

## Base URL
```
Production: https://orderzhouse-backend.onrender.com
Development: http://localhost:5050
```

## Authentication
Most endpoints require JWT authentication via Authorization header:
```
Authorization: Bearer <jwt-token>
```

---

## 1. Authentication (`/auth`)

### POST `/auth/2fa/verify-login`
**Public** - Verify 2FA code during login
- **Body**: `{ temp_token: string, code: string }`
- **Response**: `{ success: true, token: string, userInfo: {...} }`

### POST `/auth/2fa/generate`
**Auth Required** - Generate TOTP secret (stored server-side) and return a QR code for the authenticator app. The raw secret is **not** returned in the JSON body (scan the QR only).
- **Response**: `{ success: true, qrCodeUrl: string }` (and optional `message`)

### POST `/auth/2fa/verify`
**Auth Required** - Verify 2FA token to enable 2FA
- **Body**: `{ token: string }`
- **Response**: `{ success: true, message: string }`

### POST `/auth/2fa/disable`
**Auth Required** - Disable 2FA
- **Response**: `{ success: true, message: string }`

---

## 2. Users (`/users`)

### POST `/users/register`
**Public** - Register new user
- **Body**: 
  ```json
  {
    "role_id": 2|3,  // 2=Client, 3=Freelancer
    "first_name": "string",
    "last_name": "string",
    "email": "string",
    "password": "string",
    "phone_number": "string",
    "country": "string",
    "username": "string",
    "category_ids": [1, 2]  // Required for freelancers (role_id=3)
  }
  ```
- **Response**: `{ success: true, message: string, user_id: number }`

### POST `/users/verify-email`
**Public** - Verify email with OTP
- **Body**: `{ email: string, otp: string }`
- **Response**: `{ success: true, message: string }`

### POST `/users/login`
**Public** - Login user
- **Body**: `{ email: string, password: string, otpMethod?: "email"|"sms" }`
- **Response**: 
  ```json
  {
    "success": true,
    "token": "string",
    "userInfo": {
      "id": number,
      "username": "string",
      "email": "string",
      "role_id": number,
      "first_name": "string",
      "last_name": "string",
      "profile_pic_url": "string|null",
      "is_deleted": boolean,
      "is_two_factor_enabled": boolean,
      "email_verified": boolean
    }
  }
  ```
  OR (if OTP required):
  ```json
  {
    "success": true,
    "message": "OTP sent successfully",
    "user_id": number,
    "username": "string"
  }
  ```

### POST `/users/verify-otp`
**Public** - Verify OTP after login
- **Body**: `{ email: string, otp: string }`
- **Response**: `{ success: true, token: string, userInfo: {...} }`

### POST `/users/send-otp`
**Public** - Send OTP for login
- **Body**: `{ email: string, otpMethod?: "email"|"sms" }`
- **Response**: `{ success: true, message: string }`

### POST `/users/forgot-password`
**Public** - Request password reset email (rate limited: 10 per 15 min per IP)
- **Body**: `{ email: string }`
- **Response**: `{ success: true, message: "If the email exists, we sent a reset link. Check your inbox." }`
- **Note**: Always returns 200; does not reveal whether the email exists. Reset link: `FRONTEND_URL/reset-password/<token>` (token valid 30 min).

### POST `/users/reset-password`
**Public** - Set new password using reset token (rate limited: 10 per 15 min per IP)
- **Body**: `{ token: string, password: string, confirmPassword: string }`
- **Validation**: password length ≥ 8, confirmPassword must match
- **Response**: `{ success: true, message: "Password updated successfully" }`
- **Errors**: 400 for invalid/expired/used token or validation failure

### GET `/users/getUserdata`
**Auth Required** - Get current user data
- **Response**: `{ success: true, user: {...} }`

### POST `/users/uploadProfilePic`
**Auth Required** - Upload profile picture
- **Content-Type**: `multipart/form-data`
- **Body**: `file: File`
- **Response**: `{ success: true, profile_pic_url: string }`

### PUT `/users/edit`
**Auth Required** - Edit user profile
- **Content-Type**: `multipart/form-data`
- **Body**: `{ first_name?, last_name?, phone_number?, country?, ... }`
- **Response**: `{ success: true, user: {...} }`

### POST `/users/rate`
**Auth Required** - Rate a freelancer
- **Body**: `{ freelancer_id: number, rating: number, comment?: string }`
- **Response**: `{ success: true, message: string }`

### POST `/users/verify-password`
**Auth Required** - Verify password before sensitive operations
- **Body**: `{ password: string }`
- **Response**: `{ success: true }`

### PUT `/users/update-password`
**Auth Required** - Change password (current user)
- **Body**: `{ currentPassword: string, newPassword: string }`
- **Response**: `{ success: true, message: "Password updated successfully" }`
- **Note**: Same as change-password flow; use from profile/settings.

### PUT `/users/deactivate`
**Auth Required** - Deactivate account
- **Body**: `{ reason?: string }`
- **Response**: `{ success: true, message: string }`

### GET `/users/deactivated-users`
**Auth Required** - Get deactivated users (Admin only)
- **Response**: `{ success: true, users: [...] }`

---

## 3. Projects (`/projects`)

### POST `/projects`
**Auth Required** - Create new project
- **Content-Type**: `multipart/form-data`
- **Body**:
  ```json
  {
    "category_id": number,
    "sub_category_id": number,
    "sub_sub_category_id": number,
    "title": "string (10-100 chars)",
    "description": "string (100-2000 chars)",
    "budget": number,  // For fixed projects
    "budget_min": number,  // For bidding projects
    "budget_max": number,  // For bidding projects
    "hourly_rate": number,  // For hourly projects
    "duration_type": "days"|"hours",
    "duration_days": number,  // If duration_type=days
    "duration_hours": number,  // If duration_type=hours
    "project_type": "fixed"|"hourly"|"bidding",
    "preferred_skills": "string",
    "cover_pic": File,  // Optional
    "project_files": File[]  // Optional, max 10
  }
  ```
- **Response**: `{ success: true, project: {...} }`

### GET `/projects/myprojects`
**Auth Required** - Get user's projects
- **Response**: `{ success: true, projects: [...] }`

### DELETE `/projects/myprojects/:projectId`
**Auth Required** - Soft delete project (owner only)
- **Response**: `{ success: true, message: string }`

### POST `/projects/:projectId/assign`
**Auth Required** - Assign freelancer to project (client only)
- **Body**: `{ freelancer_id: number }`
- **Response**: `{ success: true, message: string }`

### POST `/projects/:projectId/apply`
**Auth Required** - Apply for project (freelancer, verified+subscribed)
- **Body**: `{ message?: string }`
- **Response**: `{ success: true, message: string }`

### POST `/projects/applications/decision`
**Auth Required** - Approve/reject application (client)
- **Body**: `{ application_id: number, decision: "approve"|"reject" }`
- **Response**: `{ success: true, message: string }`

### GET `/projects/applications/my-projects`
**Auth Required** - Get applications for user's projects
- **Response**: `{ success: true, applications: [...] }`

### POST `/projects/assignments/:assignmentId/accept`
**Auth Required** - Accept assignment (freelancer, verified+subscribed)
- **Response**: `{ success: true, message: string }`

### POST `/projects/assignments/:assignmentId/reject`
**Auth Required** - Reject assignment (freelancer, verified+subscribed)
- **Response**: `{ success: true, message: string }`

### POST `/projects/:projectId/resubmit`
**Auth Required** - Resubmit work completion (freelancer, verified+subscribed)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files: File[] }`
- **Response**: `{ success: true, message: string }`

### PUT `/projects/:projectId/approve`
**Auth Required** - Approve work completion (client)
- **Response**: `{ success: true, message: string }`

### PUT `/projects/hourly/:projectId`
**Auth Required** - Complete hourly project
- **Body**: `{ hours_worked: number }`
- **Response**: `{ success: true, message: string }`

### POST `/projects/:projectId/files`
**Auth Required** - Add files to project
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files: File[] }` (max 5)
- **Response**: `{ success: true, files: [...] }`

### GET `/projects/:projectId/files`
**Auth Required** - Get project files
- **Response**: `{ success: true, files: [...] }`

### GET `/projects/:projectId/timeline`
**Auth Required** - Get project timeline
- **Response**: `{ success: true, timeline: [...] }`

### GET `/projects/admin/freelancers`
**Auth Required** - Get all freelancers (Admin)
- **Response**: `{ success: true, freelancers: [...] }`

### GET `/projects/admin/projects`
**Auth Required** - Get all projects (Admin)
- **Response**: `{ success: true, projects: [...] }`

### PUT `/projects/admin/projects/:projectId/reassign`
**Auth Required** - Reassign freelancer (Admin)
- **Body**: `{ freelancer_id: number }`
- **Response**: `{ success: true, message: string }`

### GET `/projects/category/:category_id`
**Auth Required** - Get projects by category
- **Response**: `{ success: true, projects: [...] }`

### GET `/projects/sub-category/:sub_category_id`
**Auth Required** - Get projects by sub-category
- **Response**: `{ success: true, projects: [...] }`

### GET `/projects/sub-sub-category/:sub_sub_category_id`
**Auth Required** - Get projects by sub-sub-category
- **Response**: `{ success: true, projects: [...] }`

### GET `/projects/public/categories`
**Public** - Get public categories
- **Response**: `{ success: true, categories: [...] }`

### GET `/projects/public/category/:categoryId`
**Public** - Get projects by category ID
- **Response**: `{ success: true, projects: [...] }`

### GET `/projects/public/subcategory/:subCategoryId`
**Public** - Get projects by sub-category ID
- **Response**: `{ success: true, projects: [...] }`

### GET `/projects/public/subsubcategory/:subSubCategoryId`
**Public** - Get projects by sub-sub-category ID
- **Response**: `{ success: true, projects: [...] }`

### GET `/projects/project/:projectId/applications`
**Auth Required** - Get applications for a project
- **Response**: `{ success: true, applications: [...] }`

### POST `/projects/:projectId/deliver`
**Auth Required** - Submit project delivery (freelancer, verified+subscribed)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files?: File[], message?: string }`
- **Response**: `{ success: true, message: string }`

### GET `/projects/:projectId/deliveries`
**Auth Required** - Get project deliveries
- **Response**: `{ success: true, deliveries: [...] }`

### POST `/projects/admin/projects/:projectId/decision`
**Auth Required** - Admin approve/reject project
- **Body**: `{ decision: "approve"|"reject" }`
- **Response**: `{ success: true, message: string }`

### POST `/projects/:projectId/request-changes`
**Auth Required** - Request changes to delivery (client)
- **Body**: `{ message: string }`
- **Response**: `{ success: true, message: string }`

---

## 4. Offers (`/offers`)

### GET `/offers/projects/open`
**Auth Required** - Get all open bidding projects (freelancer, verified+subscribed)
- **Response**: `{ success: true, projects: [...] }`

### POST `/offers/:projectId/offers`
**Auth Required** - Send offer for project (freelancer, verified+subscribed)
- **Body**: `{ amount: number, message?: string, delivery_days: number }`
- **Response**: `{ success: true, message: string }`

### GET `/offers/:projectId/my-offers`
**Auth Required** - Get my offers for a project (freelancer, verified+subscribed)
- **Response**: `{ success: true, offers: [...] }`

### GET `/offers/my-projects/offers`
**Auth Required** - Get offers for my projects (client)
- **Response**: `{ success: true, offers: [...] }`

### GET `/offers/project/:projectId/offers`
**Auth Required** - Get offers for a specific project (client-owner)
- **Response**: `{ success: true, offers: [...] }`

### POST `/offers/offers/approve-reject`
**Auth Required** - Approve or reject offer (client)
- **Body**: `{ offer_id: number, decision: "approve"|"reject" }`
- **Response**: `{ success: true, message: string }`

### PUT `/offers/offers/:offerId/cancel`
**Auth Required** - Cancel pending offer (freelancer, verified+subscribed)
- **Response**: `{ success: true, message: string }`

### GET `/offers/offers/accepted`
**Auth Required** - Get accepted offers
- **Response**: `{ success: true, offers: [...] }`

### GET `/offers/my/:projectId/pending`
**Auth Required** - Check if I have pending offer (freelancer, verified+subscribed)
- **Response**: `{ success: true, hasPending: boolean, offer?: {...} }`

---

## 5. Tasks (`/tasks`)

### GET `/tasks/admin`
**Auth Required** - Get all tasks (Admin)
- **Response**: `{ success: true, tasks: [...] }`

### PUT `/tasks/admin/:id/status`
**Auth Required** - Approve task by admin
- **Body**: `{ status: string }`
- **Response**: `{ success: true, message: string }`

### PUT `/tasks/admin/payment/:id/confirm`
**Auth Required** - Confirm payment by admin
- **Response**: `{ success: true, message: string }`

### POST `/tasks/freelancer`
**Auth Required** - Create task (freelancer)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ title, description, budget, category_id, files?: File[] }`
- **Response**: `{ success: true, task: {...} }`

### PUT `/tasks/freelancer/:id`
**Auth Required** - Update task (freelancer)
- **Body**: `{ title?, description?, budget?, ... }`
- **Response**: `{ success: true, task: {...} }`

### DELETE `/tasks/freelancer/:id`
**Auth Required** - Delete task (freelancer)
- **Response**: `{ success: true, message: string }`

### PUT `/tasks/freelancer/requests/:id/status`
**Auth Required** - Update task request status (freelancer)
- **Body**: `{ status: string }`
- **Response**: `{ success: true, message: string }`

### POST `/tasks/freelancer/requests/:id/submit`
**Auth Required** - Submit work completion (freelancer)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files?: File[] }`
- **Response**: `{ success: true, message: string }`

### POST `/tasks/freelancer/requests/:id/resubmit`
**Auth Required** - Resubmit work completion (freelancer)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files?: File[] }`
- **Response**: `{ success: true, message: string }`

### PUT `/tasks/freelancer/:id/kanban`
**Auth Required** - Update task kanban status (freelancer)
- **Body**: `{ status: string }`
- **Response**: `{ success: true, message: string }`

### GET `/tasks/freelancer/my-tasks`
**Auth Required** - Get freelancer's created tasks
- **Response**: `{ success: true, tasks: [...] }`

### GET `/tasks/freelancer/requests/:taskId`
**Auth Required** - Get task requests (freelancer)
- **Response**: `{ success: true, requests: [...] }`

### GET `/tasks/freelancer/assigned`
**Auth Required** - Get assigned tasks (freelancer)
- **Response**: `{ success: true, tasks: [...] }`

### POST `/tasks/client/request/:id`
**Auth Required** - Request task (client)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ message?: string, files?: File[] }`
- **Response**: `{ success: true, message: string }`

### POST `/tasks/client/payment/:id`
**Auth Required** - Submit payment proof (client)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ file: File }`
- **Response**: `{ success: true, message: string }`

### POST `/tasks/client/approve/:id`
**Auth Required** - Approve work completion (client)
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files?: File[] }`
- **Response**: `{ success: true, message: string }`

### POST `/tasks/client/review/:id`
**Auth Required** - Create review (client)
- **Body**: `{ rating: number, comment?: string }`
- **Response**: `{ success: true, message: string }`

### GET `/tasks/pool`
**Public** - Get task pool (public tasks)
- **Response**: `{ success: true, tasks: [...] }`

### GET `/tasks/categories`
**Public** - Get task categories
- **Response**: `{ success: true, categories: [...] }`

### GET `/tasks/:id`
**Public** - Get task by ID
- **Response**: `{ success: true, task: {...} }`

### POST `/tasks/files/:id`
**Auth Required** - Add files to task
- **Content-Type**: `multipart/form-data`
- **Body**: `{ files: File[] }`
- **Response**: `{ success: true, files: [...] }`

---

## 6. Payments (`/payments`)

### GET `/payments/user/:user_id`
**Public** - Get user payments
- **Response**: 
  ```json
  {
    "success": true,
    "payments": [
      {
        "id": number,
        "user_id": number,
        "amount": number,
        "currency": "string",
        "status": "string",
        "purpose": "plan"|"project",
        "reference_id": number,
        "created_at": "timestamp",
        "stripe_session_id": "string",
        "stripe_payment_intent": "string",
        "plan_name": "string|null",
        "project_title": "string|null"
      }
    ]
  }
  ```

### GET `/payments/admin/all`
**Auth Required, Admin Only** - Get all payments
- **Response**: `{ success: true, payments: [...] }`

---

## 7. Chats (`/chats` or `/chat`)

### GET `/chats/user-chats`
**Auth Required** - Get user's chats
- **Response**: `{ success: true, chats: [...] }`

### GET `/chats/project/:projectId/messages`
**Auth Required** - Get messages by project ID
- **Response**: `{ success: true, messages: [...] }`

### GET `/chats/task/:taskId/messages`
**Auth Required** - Get messages by task ID
- **Response**: `{ success: true, messages: [...] }`

### POST `/chats/messages`
**Auth Required** - Create message
- **Body**: 
  ```json
  {
    "project_id": number,  // OR task_id
    "task_id": number,
    "content": "string",
    "file_urls": ["string"]  // Optional
  }
  ```
- **Response**: `{ success: true, message: {...} }`

### GET `/chats/admin/all-chats`
**Auth Required** - Get all chats (Admin)
- **Response**: `{ success: true, chats: [...] }`

---

## 8. Notifications (`/notifications`)

### GET `/notifications`
**Auth Required** - Get notifications for authenticated user
- **Query Params**: `?limit=20&offset=0`
- **Response**: `{ success: true, notifications: [...] }`

### GET `/notifications/count`
**Auth Required** - Get notification count
- **Response**: `{ success: true, count: number }`

### PUT `/notifications/read-all`
**Auth Required** - Mark all notifications as read
- **Response**: `{ success: true, message: string }`

### PUT `/notifications/:id/read`
**Auth Required** - Mark notification as read
- **Response**: `{ success: true, message: string }`

### DELETE `/notifications/:id`
**Auth Required** - Delete notification
- **Response**: `{ success: true, message: string }`

### DELETE `/notifications/cleanup`
**Auth Required, Admin Only** - Cleanup old notifications
- **Response**: `{ success: true, message: string }`

### POST `/notifications/test`
**Auth Required, Admin Only** - Create test notification
- **Response**: `{ success: true, message: string }`

---

## 9. Ratings (`/ratings`)

### POST `/ratings`
**Auth Required** - Submit rating (client)
- **Body**: `{ freelancer_id: number, rating: number, comment?: string }`
- **Response**: `{ success: true, message: string }`

### GET `/ratings/freelancer/:freelancerId`
**Public** - Get ratings for freelancer
- **Response**: `{ success: true, ratings: [...] }`

---

## 10. Categories (`/category`)

### GET `/category`
**Public** - Get all categories
- **Response**: `{ success: true, categories: [...] }`

### GET `/category/:categoryId`
**Public** - Get category by ID
- **Response**: `{ success: true, category: {...} }`

### GET `/category/:categoryId/sub-categories`
**Public** - Get sub-categories
- **Response**: `{ success: true, subCategories: [...] }`

### GET `/category/sub-category/:subCategoryId/sub-sub-categories`
**Public** - Get sub-sub-categories
- **Response**: `{ success: true, subSubCategories: [...] }`

### GET `/category/:categoryId/sub-sub-categories`
**Public** - Get all sub-sub-categories by category
- **Response**: `{ success: true, subSubCategories: [...] }`

### POST `/category`
**Auth Required, Admin Only** - Create category
- **Body**: `{ name: string, description?: string }`
- **Response**: `{ success: true, category: {...} }`

### PUT `/category/:id`
**Auth Required, Admin Only** - Update category
- **Body**: `{ name?: string, description?: string }`
- **Response**: `{ success: true, category: {...} }`

### DELETE `/category/:id`
**Auth Required, Admin Only** - Delete category
- **Response**: `{ success: true, message: string }`

### POST `/category/:categoryId/sub-categories`
**Auth Required, Admin Only** - Create sub-category
- **Body**: `{ name: string, description?: string }`
- **Response**: `{ success: true, subCategory: {...} }`

### PUT `/category/:categoryId/sub-categories/:id`
**Auth Required, Admin Only** - Update sub-category
- **Body**: `{ name?: string, description?: string }`
- **Response**: `{ success: true, subCategory: {...} }`

### DELETE `/category/:categoryId/sub-categories/:id`
**Auth Required, Admin Only** - Delete sub-category
- **Response**: `{ success: true, message: string }`

### POST `/category/sub-category/:subCategoryId/sub-sub-categories`
**Auth Required, Admin Only** - Create sub-sub-category
- **Body**: `{ name: string, description?: string }`
- **Response**: `{ success: true, subSubCategory: {...} }`

### PUT `/category/sub-category/:subCategoryId/sub-sub-categories/:id`
**Auth Required, Admin Only** - Update sub-sub-category
- **Body**: `{ name?: string, description?: string }`
- **Response**: `{ success: true, subSubCategory: {...} }`

### DELETE `/category/sub-category/:subCategoryId/sub-sub-categories/:id`
**Auth Required, Admin Only** - Delete sub-sub-category
- **Response**: `{ success: true, message: string }`

---

## 11. Plans & Subscriptions (`/plans`)

### GET `/plans`
**Public** - Get all plans
- **Response**: `{ success: true, plans: [...] }`

### GET `/plans/subscriptions/counts`
**Auth Required, Admin Only** - Get subscription counts
- **Response**: `{ success: true, counts: {...} }`

### GET `/plans/subscriptions/all`
**Auth Required, Admin Only** - Get all subscriptions
- **Response**: `{ success: true, subscriptions: [...] }`

### GET `/plans/:id/subscribers`
**Auth Required, Admin Only** - Get plan subscribers
- **Response**: `{ success: true, subscribers: [...] }`

### POST `/plans/create`
**Auth Required, Admin Only** - Create plan
- **Body**: `{ name, price, duration, plan_type, ... }`
- **Response**: `{ success: true, plan: {...} }`

### PUT `/plans/edit/:id`
**Auth Required, Admin Only** - Edit plan
- **Body**: `{ name?, price?, duration?, ... }`
- **Response**: `{ success: true, plan: {...} }`

### DELETE `/plans/delete/:id`
**Auth Required, Admin Only** - Delete plan
- **Response**: `{ success: true, message: string }`

### PATCH `/plans/admin/subscription`
**Auth Required, Admin Only** - Admin update subscription
- **Body**: `{ subscription_id: number, ... }`
- **Response**: `{ success: true, message: string }`

### PATCH `/plans/:planId/subscribers/:id`
**Auth Required, Admin Only** - Admin cancel subscription
- **Response**: `{ success: true, message: string }`

### GET `/subscriptions/admin/all`
**Auth Required, Admin Only** - Get all subscriptions
- **Response**: `{ success: true, subscriptions: [...] }`

---

## 12. Stripe Payments (`/stripe`)

### POST `/stripe/create-checkout-session`
**Public** - Create Stripe checkout session for subscription
- **Body**: 
  ```json
  {
    "plan_id": number,
    "user_id": number,
    "includes_verification_fee": boolean
  }
  ```
- **Response**: `{ success: true, sessionId: string, url: string }`

### POST `/stripe/project-checkout-session`
**Auth Required** - Create Stripe checkout session for project payment
- **Body**: 
  ```json
  {
    "project_id": number,
    "amount": number
  }
  ```
- **Response**: `{ success: true, sessionId: string, url: string }`

### GET `/stripe/confirm`
**Public** - Confirm checkout session
- **Query Params**: `?session_id=string`
- **Response**: `{ ok: true, message: string }`

### POST `/stripe/webhook`
**Webhook** - Stripe webhook handler (raw body required)
- **Headers**: `stripe-signature: string`
- **Note**: This endpoint processes Stripe events automatically

---

## 13. Freelancer Categories (`/freelancerCategories`)

### GET `/freelancerCategories`
**Auth Required, Verified+Subscribed** - Get freelancer categories
- **Response**: `{ success: true, categories: [...] }`

### PUT `/freelancerCategories`
**Auth Required, Verified+Subscribed** - Update freelancer categories
- **Body**: `{ category_ids: [number] }`
- **Response**: `{ success: true, message: string }`

---

## 14. Assignments (`/assignments`)

### GET `/assignments/:projectId/my-assignment`
**Auth Required** - Get assignment for freelancer
- **Response**: `{ success: true, assignment: {...} }`

### GET `/assignments/:projectId/check`
**Auth Required** - Check if assigned to project
- **Response**: `{ success: true, isAssigned: boolean }`

---

## 15. Verification (`/verification`)

### GET `/verification/verifications`
**Auth Required, Admin Only** - Get pending verifications
- **Response**: `{ success: true, verifications: [...] }`

### PUT `/verification/verifications/:id/approve`
**Auth Required, Admin Only** - Approve verification
- **Response**: `{ success: true, message: string }`

### PUT `/verification/verifications/:id/reject`
**Auth Required, Admin Only** - Reject verification
- **Body**: `{ reason?: string }`
- **Response**: `{ success: true, message: string }`

---

## 16. Courses (`/courses`)

### POST `/courses/coupon`
**Auth Required, Admin Only** - Give course coupon to freelancer
- **Body**: `{ freelancer_id: number, coupon_code: string }`
- **Response**: `{ success: true, message: string }`

### GET `/courses/myCoupon`
**Auth Required, Verified+Subscribed** - Get my course coupons
- **Response**: `{ success: true, coupons: [...] }`

---

## 17. Blogs (`/blogs`)

### GET `/blogs`
**Public** - Get all blogs
- **Query Params**: `?limit=20&offset=0&status=approved`
- **Response**: `{ success: true, blogs: [...] }`

### GET `/blogs/:id`
**Public** - Get blog by ID
- **Response**: `{ success: true, blog: {...} }`

### POST `/blogs`
**Auth Required** - Create blog
- **Content-Type**: `multipart/form-data`
- **Body**: 
  ```json
  {
    "title": "string",
    "content": "string",
    "cover": File,  // Optional
    "attachments": File[]  // Optional, max 5
  }
  ```
- **Response**: `{ success: true, blog: {...} }`

### PUT `/blogs/:id`
**Auth Required** - Update blog
- **Content-Type**: `multipart/form-data`
- **Body**: `{ title?, content?, cover?, attachments? }`
- **Response**: `{ success: true, blog: {...} }`

### DELETE `/blogs/:id`
**Auth Required** - Delete blog
- **Response**: `{ success: true, message: string }`

### PUT `/blogs/:id/approve`
**Auth Required, Admin Only** - Approve blog
- **Response**: `{ success: true, message: string }`

### PUT `/blogs/:id/reject`
**Auth Required, Admin Only** - Reject blog
- **Body**: `{ reason?: string }`
- **Response**: `{ success: true, message: string }`

### POST `/blogs/:id/like`
**Auth Required** - Like blog
- **Response**: `{ success: true, message: string }`

### POST `/blogs/:id/save`
**Auth Required** - Save blog
- **Response**: `{ success: true, message: string }`

---

## 18. Email Verification (`/email`)

### POST `/email/verify`
**Public** - Verify email OTP
- **Body**: `{ email: string, otp: string }`
- **Response**: `{ success: true, message: string }`

---

## 19. Admin Users (`/admUser`)

### POST `/admUser`
**Auth Required, Admin Only** - Create user
- **Body**: `{ role_id, first_name, last_name, email, ... }`
- **Response**: `{ success: true, user: {...} }`

### GET `/admUser/role/:roleId`
**Auth Required, Admin Only** - Get users by role
- **Response**: `{ success: true, users: [...] }`

### GET `/admUser/:id`
**Auth Required, Admin Only** - Get user by ID
- **Response**: `{ success: true, user: {...} }`

### PUT `/admUser/:id`
**Auth Required, Admin Only** - Update user
- **Body**: `{ first_name?, last_name?, ... }`
- **Response**: `{ success: true, user: {...} }`

### DELETE `/admUser/:id`
**Auth Required, Admin Only** - Delete user
- **Response**: `{ success: true, message: string }`

### PATCH `/admUser/verify/:id`
**Auth Required, Admin Only** - Verify freelancer
- **Response**: `{ success: true, message: string }`

---

## 20. Logs (`/logs`)

### GET `/logs/messages`
**Auth Required** - Get message logs
- **Response**: `{ success: true, logs: [...] }`

### GET `/logs`
**Auth Required** - Get system logs
- **Query Params**: `?level=info&limit=50&offset=0`
- **Response**: `{ success: true, logs: [...] }`

### GET `/logs/entity/:entityType/:entityId`
**Auth Required** - Get logs for entity
- **Response**: `{ success: true, logs: [...] }`

### GET `/logs/user/:userId`
**Auth Required** - Get logs for user
- **Response**: `{ success: true, logs: [...] }`

### GET `/logs/errors`
**Auth Required** - Get error logs
- **Response**: `{ success: true, logs: [...] }`

### GET `/logs/critical`
**Auth Required** - Get critical logs
- **Response**: `{ success: true, logs: [...] }`

### GET `/logs/statistics`
**Auth Required** - Get log statistics
- **Response**: `{ success: true, statistics: {...} }`

### GET `/logs/export`
**Auth Required** - Export logs to CSV
- **Response**: CSV file download

### DELETE `/logs/cleanup`
**Auth Required** - Cleanup old logs
- **Response**: `{ success: true, message: string }`

---

## 21. Live Screen Stats (`/api`)

### GET `/api/stats`
**Public** - Get dashboard statistics
- **Response**: 
  ```json
  {
    "totalProjects": number,
    "processing": number,
    "clients": number,
    "freelancers": number
  }
  ```

---

## Role-Based Access

### Roles
- **1**: Admin
- **2**: Client
- **3**: Freelancer

### Middleware Requirements
- **authentication**: JWT token required
- **adminOnly**: Role ID must be 1 (Admin)
- **requireVerifiedWithSubscription**: 
  - Admins and Clients bypass
  - Freelancers must be verified (`is_verified = true`) AND have active subscription

---

## Common Response Formats

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {...}  // Optional
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error"  // Optional
}
```

### Pagination (where applicable)
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "total": number,
    "limit": number,
    "offset": number,
    "hasMore": boolean
  }
}
```
