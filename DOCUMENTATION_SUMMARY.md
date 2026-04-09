# Documentation Summary - OrderzHouse

## Overview

This document summarizes the official documentation from the `docs/` directory, which serves as the **source of truth** for understanding the OrderzHouse platform.

---

## 1. API Map Summary (`API_MAP.md`)

### Base Configuration
- **Production URL**: `https://orderzhouse-backend.onrender.com`
- **Development URL**: `http://localhost:5050`
- **Authentication**: JWT via `Authorization: Bearer <token>` header

### Key API Endpoints (21 main groups)

1. **Authentication (`/auth`)**
   - 2FA generation, verification, disable
   - Terms acceptance
   - Password change

2. **Users (`/users`)**
   - Registration (requires email verification)
   - Login (with OTP/2FA support)
   - Profile management
   - Account deactivation (30-day grace period)

3. **Projects (`/projects`)**
   - CRUD operations
   - Assignment/application flow
   - Work submission/review
   - File management
   - Timeline tracking
   - Admin operations

4. **Offers (`/offers`)**
   - Bidding system for projects
   - Offer submission/approval/rejection
   - Offer cancellation

5. **Tasks (`/tasks`)**
   - Freelancer-created tasks
   - Client task requests
   - Payment proof submission
   - Work approval flow

6. **Payments (`/payments`)**
   - Payment history
   - Wallet management (freelancers)
   - Escrow management (admin)

7. **Chats (`/chats`)**
   - Project-based messaging
   - Task-based messaging
   - Real-time via Socket.io

8. **Notifications (`/notifications`)**
   - Paginated notifications
   - Read/unread management
   - Real-time updates

9. **Ratings (`/ratings`)**
   - Freelancer ratings by clients
   - Public rating display

10. **Categories (`/category`)**
    - 3-level hierarchy (category → sub-category → sub-sub-category)
    - Public and admin endpoints

11. **Plans & Subscriptions (`/plans`, `/subscriptions`)**
    - Plan management (admin)
    - Subscription tracking

12. **Stripe Payments (`/stripe`)**
    - Checkout session creation
    - Webhook handling
    - Payment confirmation

13. **Freelancer Categories (`/freelancerCategories`)**
    - Category selection for freelancers
    - Requires verification + subscription

14. **Assignments (`/assignments`)**
    - Assignment checking
    - Assignment retrieval

15. **Verification (`/verification`)**
    - Admin approval/rejection of freelancer verifications

16. **Courses (`/courses`)**
    - Coupon management
    - Course enrollment

17. **Blogs (`/blogs`)**
    - Blog CRUD
    - Like/save functionality
    - Admin approval workflow

18. **Email Verification (`/email`)**
    - OTP verification

19. **Admin Users (`/admUser`)**
    - User management (admin only)

20. **Logs (`/logs`)**
    - System logging
    - Error tracking
    - Statistics

21. **Live Screen Stats (`/api`)**
    - Dashboard statistics

### Role-Based Access
- **Role 1**: Admin (full access)
- **Role 2**: Client
- **Role 3**: Freelancer

### Middleware Requirements
- `authentication`: JWT token required
- `adminOnly`: Role ID must be 1
- `requireVerifiedWithSubscription`: 
  - Admins/Clients bypass
  - Freelancers must be verified AND have active subscription

---

## 2. Authentication Flow Summary (`AUTH_FLOW.md`)

### Authentication Method
- **Type**: JWT (JSON Web Tokens)
- **Algorithm**: HS256
- **Expiration**: 1 day (24 hours)
- **Token Payload**: userId, role, is_verified, username, is_deleted, is_two_factor_enabled

### Registration Flow
1. POST `/users/register` → User created, email OTP sent
2. POST `/users/verify-email` → Email verified, account activated

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number

### Login Flow
1. **Standard Login**: POST `/users/login` → Direct JWT token
2. **OTP-Protected Login**: If 3+ failed attempts → OTP required → POST `/users/verify-otp`
3. **2FA Login**: If 2FA enabled → Temp token → POST `/auth/2fa/verify-login`

### Two-Factor Authentication (2FA)
- **Method**: TOTP (Time-based One-Time Password)
- **Enabling**: Generate secret → Verify code → Enable
- **Login with 2FA**: Password → Temp token → 2FA code → Full token

### Account Deactivation
- **Grace Period**: 30 days
- **Reactivation**: Automatic on login within grace period
- **Permanent Deletion**: After 30 days

### Security Features
- Email verification required
- OTP for suspicious logins (3+ failed attempts)
- Optional 2FA (TOTP)
- Account soft delete with grace period
- Terms & Conditions acceptance enforcement

---

## 3. Database Schema Summary (`DB_SCHEMA.md`)

### Core Tables (26 total)

#### User Management
1. **`users`** - Main user accounts
   - Authentication fields (email, password, OTP, 2FA)
   - Profile fields (name, phone, country, profile_pic)
   - Status fields (email_verified, is_verified, is_deleted)
   - Timestamps (created_at, updated_at, deactivated_at)

2. **`roles`** - User roles (1=Admin, 2=Client, 3=Freelancer)

#### Categories (3-level hierarchy)
3. **`categories`** - Main categories (level 0)
4. **`sub_categories`** - Sub-categories (level 1)
5. **`sub_sub_categories`** - Sub-sub-categories (level 2)
6. **`freelancer_categories`** - Freelancer → Category mapping
7. **`freelancer_sub_categories`** - Freelancer → Sub-category mapping

#### Projects & Assignments
8. **`projects`** - Project listings
   - Types: 'fixed', 'hourly', 'bidding'
   - Status: 'active', 'bidding', 'in_progress', 'completed', 'cancelled'
   - Completion status: 'not_started', 'in_progress', 'completed'
   - Budget fields vary by type

9. **`project_assignments`** - Freelancer assignments
   - Status: 'pending', 'accepted', 'rejected', 'in_progress', 'completed'
   - Types: 'direct_assign', 'application', 'offer'

10. **`offers`** - Bids on bidding projects
    - Status: 'pending', 'accepted', 'rejected', 'cancelled', 'expired'

11. **`project_files`** - Files attached to projects
12. **`project_deliveries`** - Delivery submissions
13. **`delivery_files`** - Files in deliveries

#### Tasks
14. **`tasks`** - Freelancer-created tasks
15. **`task_requests`** - Client requests for tasks
    - Payment proof workflow

#### Payments & Subscriptions
16. **`plans`** - Subscription plans
    - Types: 'monthly', 'yearly'
    - Features stored as JSONB

17. **`subscriptions`** - User subscriptions
    - Status: 'active', 'cancelled', 'expired'

18. **`payments`** - Payment records
    - Purpose: 'plan' or 'project'
    - Stripe integration fields

#### Communication
19. **`messages`** - Chat messages
    - Project-based or task-based
    - File attachments support

20. **`notifications`** - User notifications
    - Type-based filtering
    - Read/unread status

#### Reviews & Content
21. **`ratings`** - Freelancer ratings by clients
22. **`blogs`** - Blog posts with approval workflow

#### System
23. **`verifications`** - Freelancer verification requests
24. **`logs`** - System activity logs
25. **`permissions`** - System permissions
26. **`role_permission`** - Role → Permission mapping

### Key Relationships
- Users → Projects (one-to-many, as client)
- Users → Project Assignments (one-to-many, as freelancer)
- Projects → Assignments (one-to-many)
- Projects → Offers (one-to-many)
- Users → Subscriptions (one-to-many)
- Categories → Sub Categories → Sub Sub Categories (hierarchical)

### Important Notes
- **Soft Deletes**: Most tables use `is_deleted` flag
- **Timestamps**: All tables have `created_at` and `updated_at`
- **Currency**: JOD (Jordanian Dinar) default
- **File Storage**: Cloudinary URLs stored in database
- **JSON Fields**: JSONB used for flexible data (plans.features, logs.metadata)

---

## 4. Mobile Data Flow Summary (`MOBILE_DATA_FLOW.md`)

### Screen Structure (20 main screens)

1. **Authentication Screens**
   - Registration → Email Verification → Login
   - Forgot Password flow

2. **Main App Screens**
   - Home/Dashboard
   - Projects List/Detail
   - Create Project (wizard)
   - Offers
   - Tasks
   - Messages/Chat (Socket.io)
   - Notifications (real-time)
   - Profile/Settings
   - Subscriptions
   - Payments
   - Ratings
   - Categories
   - Freelancer Categories
   - Blogs
   - Admin Screens

### Data Flow Patterns

1. **Authentication**: Registration → Verification → Login → (OTP/2FA) → Home
2. **Project (Client)**: Create → View → Manage Applications → Assign → Approve → Complete → Rate
3. **Project (Freelancer)**: Browse → Apply/Offer → Accept → Work → Submit → Resubmit → Approved
4. **Task (Freelancer)**: Create → Listed → Client Requests → Accept → Complete → Approved
5. **Task (Client)**: Browse → Request → Pay → Approve → Review
6. **Payment**: Select Plan → Stripe Checkout → Confirm → Active

### Technical Recommendations
- **State Management**: Provider or Riverpod
- **API Client**: Dio with interceptors
- **Storage**: flutter_secure_storage for tokens, SharedPreferences for user data
- **Real-time**: Socket.io client for messages/notifications
- **File Uploads**: Multipart form data
- **Caching**: Hive or SharedPreferences

---

## Key Architectural Decisions (from docs)

### 1. Authentication & Security
- JWT-based authentication with 1-day expiration
- Email verification required for all users
- OTP protection for suspicious logins
- Optional 2FA (TOTP)
- Terms & Conditions acceptance enforced
- Account deactivation with 30-day grace period

### 2. Role-Based Access Control
- Three roles: Admin (1), Client (2), Freelancer (3)
- Freelancers require verification + subscription for certain actions
- Permission-based authorization system

### 3. Project Types
- **Fixed**: Single budget amount
- **Hourly**: Hourly rate with prepaid hours
- **Bidding**: Budget range, requires payment + admin approval

### 4. Assignment Flow
- **Client Invites**: Direct assignment → Freelancer accepts/rejects
- **Freelancer Applies**: Application → Client approves/rejects
- **Bidding**: Offer submission → Client accepts → Assignment created

### 5. Work Completion Flow
- Freelancer submits → Status: `pending_review`
- Client reviews → Approve (`completed`) or Request revision (`revision_requested`)
- Revision → Freelancer resubmits → Cycle repeats

### 6. Payment System
- Stripe integration for payments
- Escrow system for project payments
- Wallet system for freelancers
- Subscription-based access for freelancers

### 7. Real-time Features
- Socket.io for messages and notifications
- Room-based messaging (project rooms, task rooms)
- Real-time notification delivery

### 8. File Management
- Cloudinary for file storage
- Multipart form data for uploads
- File limits: 10 files for projects, 5 for tasks/blogs

### 9. Category System
- 3-level hierarchy: Category → Sub-Category → Sub-Sub-Category
- Freelancers select main categories
- Projects require sub-sub-category

### 10. Soft Deletes
- Most entities use `is_deleted` flag
- 30-day grace period for account deactivation
- Permanent deletion after grace period

---

## Naming Conventions (from docs)

### API Endpoints
- RESTful naming (GET, POST, PUT, DELETE, PATCH)
- Plural resource names (`/projects`, `/users`, `/offers`)
- Nested resources (`/projects/:id/files`)
- Public endpoints prefixed with `/public` or `/tasks/pool`

### Database
- Snake_case for column names
- Plural table names (`users`, `projects`, `categories`)
- Foreign keys: `{table}_id` (e.g., `user_id`, `project_id`)
- Status fields: `status`, `completion_status`
- Timestamps: `created_at`, `updated_at`

### Response Format
- Success: `{ success: true, message: "...", data: {...} }`
- Error: `{ success: false, message: "...", error: "..." }`
- Pagination: `{ data: [...], pagination: { total, limit, offset, hasMore } }`

---

## Business Rules (from docs)

1. **Registration**: Email verification required before login
2. **Freelancer Verification**: Admin approval required
3. **Freelancer Subscription**: Required for applying to projects, submitting offers, etc.
4. **Project Creation**: 
   - Fixed/Hourly: Immediately active
   - Bidding: Requires payment + admin approval
5. **Work Submission**: Only active freelancer can submit
6. **Account Deactivation**: 30-day grace period for reactivation
7. **Terms Acceptance**: Required before accessing resources
8. **OTP Protection**: Triggered after 3+ failed login attempts
9. **2FA**: Optional, uses TOTP (Google Authenticator compatible)
10. **File Limits**: 
    - Projects: 10 files max
    - Tasks/Blogs: 5 files max

---

## Questions for Clarification

Before proceeding to source code review, I'd like to confirm:

1. **Terms & Conditions**: The docs mention terms acceptance, but I see `CURRENT_TERMS_VERSION = "v1"` in code. Is there a terms content table or file?

2. **Project Status Flow**: The docs show multiple status fields (`status`, `completion_status`). Are there specific state transitions documented?

3. **Escrow System**: The docs mention escrow but the exact flow (when created, when released) isn't fully detailed. Should I infer from code?

4. **Notification Types**: The API map doesn't list all notification types. Should I reference the notification service code?

5. **Task System**: The task flow seems separate from projects. Are tasks a different marketplace model?

---

## Next Steps

After confirmation, I will:
1. Review source code file-by-file
2. Map implementation to documentation
3. Identify mismatches
4. Document findings
5. Propose fixes with clear reasoning

**Ready to proceed to Phase 2 (Source Code Review)?**
