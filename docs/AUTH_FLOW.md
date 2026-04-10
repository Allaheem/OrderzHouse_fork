# Authentication Flow - OrderzHouse Backend

Complete guide to authentication mechanisms used in the OrderzHouse backend API.

## Overview

The OrderzHouse backend uses **JWT (JSON Web Tokens)** for authentication. The system supports:
- Email/password authentication
- OTP (One-Time Password) verification for suspicious logins
- Two-Factor Authentication (2FA) using TOTP
- Role-based access control (Admin, Client, Freelancer)
- Account verification and subscription requirements for freelancers

---

## Authentication Method: JWT

### Token Format
- **Type**: JSON Web Token (JWT)
- **Algorithm**: HS256 (symmetric key)
- **Secret**: Stored in `JWT_SECRET` environment variable
- **Expiration**: 1 day (24 hours)

### Token Payload Structure
```json
{
  "userId": number,
  "role": number,  // 1=Admin, 2=Client, 3=Freelancer
  "is_verified": boolean,
  "username": "string",
  "is_deleted": boolean,
  "is_two_factor_enabled": boolean
}
```

### Token Location
Tokens are sent in the **Authorization header**:
```
Authorization: Bearer <jwt-token>
```

---

## Registration Flow

### 1. POST `/users/register`

**Request Body:**
```json
{
  "role_id": 2,  // or 3 for freelancer
  "first_name": "John",
  "last_name": "Doe",
  "email": "info@battechno.com",
  "password": "SecurePass123",
  "phone_number": "+1234567890",
  "country": "USA",
  "username": "johndoe",
  "category_ids": [1, 2]  // Required for freelancers (role_id=3)
}
```

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number

**Response:**
```json
{
  "success": true,
  "message": "Registered successfully. OTP sent ✅",
  "user_id": 123
}
```

**What Happens:**
1. User is created in database with `email_verified = false`
2. Password is hashed using bcrypt (10 rounds)
3. Email OTP is generated and sent to user's email
4. OTP expires in 5 minutes
5. For freelancers, categories are linked in `freelancer_categories` table

---

## Email Verification Flow

### 2. POST `/users/verify-email`

**Request Body:**
```json
{
  "email": "info@battechno.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully ✅"
}
```

**What Happens:**
1. OTP is validated against stored `email_otp`
2. Expiration time is checked
3. User's `email_verified` is set to `true`
4. OTP fields are cleared

**Note:** Users cannot login until email is verified.

---

## Password Recovery Flow

### POST `/users/forgot-password`
- **Body**: `{ email: string }`
- **Response**: Always `200` with message like "If the email exists, we sent a reset link" (no email enumeration).
- **Behavior**: If user exists, a secure token is generated, stored as SHA-256 hash in `password_reset_tokens`, expiry 30 min. Reset link sent by email: `FRONTEND_URL/reset-password/<rawToken>`. If SMTP is not configured (e.g. dev), URL is logged to console only.

### POST `/users/reset-password`
- **Body**: `{ token: string, password: string, confirmPassword: string }`
- **Behavior**: Token is hashed (SHA-256), looked up in `password_reset_tokens` (not expired, not used). User password is updated with bcrypt; token is marked `used_at = NOW()`.
- **Response**: `200` with message "Password updated successfully", or `400` for invalid/expired/used token or validation errors.

### Change password (authenticated)
- **PUT `/users/update-password`** (or **PATCH `/auth/change-password`**): requires current password; body `currentPassword`, `newPassword` (and optionally `confirmNewPassword` on frontend). Used from profile/settings.

---

## Login Flow

### Standard Login (No Failed Attempts)

### 3. POST `/users/login`

**Request Body:**
```json
{
  "email": "info@battechno.com",
  "password": "SecurePass123",
  "otpMethod": "email"  // Optional: "email" or "sms"
}
```

**Response (Direct Login):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userInfo": {
    "id": 123,
    "username": "johndoe",
    "email": "info@battechno.com",
    "role_id": 2,
    "first_name": "John",
    "last_name": "Doe",
    "profile_pic_url": "https://...",
    "is_deleted": false,
    "is_two_factor_enabled": false,
    "email_verified": true
  }
}
```

**What Happens:**
1. Email is validated (must be verified)
2. Account status is checked (not permanently deleted)
3. Password is verified using bcrypt
4. If no failed login attempts, JWT token is generated and returned
5. Failed login attempts counter is reset

---

## OTP-Protected Login Flow

### When OTP is Required

If user has **3 or more failed login attempts**, or password verification fails, an OTP is required:

**Response (OTP Required):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "user_id": 123,
  "username": "johndoe"
}
```

**What Happens:**
1. OTP is generated (6-digit code)
2. OTP expires in 2 minutes
3. OTP is sent via email (or SMS if configured)
4. OTP is stored in `users.otp_code` and `users.otp_expires`

### 4. POST `/users/verify-otp`

**Request Body:**
```json
{
  "email": "info@battechno.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userInfo": {...}
}
```

**What Happens:**
1. OTP is validated
2. Expiration is checked
3. JWT token is generated
4. Failed login attempts counter is reset
5. OTP fields are cleared

---

## Two-Factor Authentication (2FA) Flow

### Enabling 2FA

### 5. POST `/auth/2fa/generate`
**Auth Required**

**Response:**
```json
{
  "success": true,
  "message": "Scan this QR code with your authenticator app.",
  "qrCodeUrl": "data:image/png;base64,iVBORw0KG..."
}
```

**What Happens:**
1. TOTP secret is generated using speakeasy
2. QR code is generated with user's email (secret is not exposed in the API response; use the QR to enroll)
3. Secret is stored in `users.two_factor_secret`
4. `is_two_factor_enabled` is set to `false` (not enabled yet)

### 6. POST `/auth/2fa/verify`
**Auth Required**

**Request Body:**
```json
{
  "token": "123456"  // 6-digit code from authenticator app
}
```

**Response:**
```json
{
  "success": true,
  "message": "2FA has been enabled successfully!"
}
```

**What Happens:**
1. TOTP code is verified against stored secret
2. `is_two_factor_enabled` is set to `true`

---

## Login with 2FA Enabled

When a user has 2FA enabled, the login flow changes:

### 7. POST `/users/login` (with 2FA enabled)

**Initial Response:**
```json
{
  "success": true,
  "message": "2FA required",
  "temp_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": 123
}
```

**What Happens:**
1. Password is verified
2. If 2FA is enabled, a temporary JWT token is generated with `stage: "2fa_login"`
3. This temp token is short-lived and used only for 2FA verification

### 8. POST `/auth/2fa/verify-login`
**Public** (no auth required, uses temp_token)

**Request Body:**
```json
{
  "temp_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "code": "123456"  // 6-digit code from authenticator app
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userInfo": {...}
}
```

**What Happens:**
1. Temp token is validated
2. TOTP code is verified
3. Full JWT token is generated and returned

---

## Disabling 2FA

### 9. POST `/auth/2fa/disable`
**Auth Required**

**Response:**
```json
{
  "success": true,
  "message": "2FA has been disabled."
}
```

**What Happens:**
1. `is_two_factor_enabled` is set to `false`
2. `two_factor_secret` is cleared

---

## Account Deactivation Flow

### 10. PUT `/users/deactivate`
**Auth Required**

**Request Body:**
```json
{
  "reason": "Taking a break"  // Optional
}
```

**What Happens:**
1. `is_deleted` is set to `true`
2. `deactivated_at` timestamp is recorded
3. `reason_for_disruption` is stored (if provided)

**Grace Period:**
- Accounts have a 30-day grace period after deactivation
- During this period, users can reactivate by logging in
- After 30 days, account is permanently deleted

**Reactivation:**
- If user logs in within 30 days, account is automatically reactivated
- `is_deleted` is set back to `false`
- `deactivated_at` is cleared

---

## Authentication Middleware

### `authentication` Middleware

**Location:** `middleware/authentication.js`

**Function:**
- Extracts JWT token from `Authorization` header
- Validates token signature using `JWT_SECRET`
- Checks token expiration
- Attaches decoded token to `req.token`

**Usage:**
```javascript
import { authentication } from "../middleware/authentication.js";

router.get("/protected", authentication, handler);
```

**Error Responses:**
- `403 Forbidden` - No token provided
- `403 Forbidden` - Invalid or expired token

---

## Authorization Middleware

### Role-Based Access

**Roles:**
- `1` = Admin
- `2` = Client
- `3` = Freelancer

### `adminOnly` Middleware

**Location:** `middleware/adminOnly.js`

**Function:**
- Checks if `req.token.role === 1`
- Returns `403 Forbidden` if not admin

**Usage:**
```javascript
import adminOnly from "../middleware/adminOnly.js";

router.get("/admin-only", authentication, adminOnly, handler);
```

### `authorization` Middleware

**Location:** `middleware/authorization.js`

**Function:**
- Checks permissions in `role_permission` and `permissions` tables
- More granular than `adminOnly`

**Usage:**
```javascript
import authorization from "../middleware/authorization.js";

router.delete("/cleanup", authentication, authorization("admin"), handler);
```

### `requireVerifiedWithSubscription` Middleware

**Location:** `middleware/requireVerifiedWithSubscription.js`

**Function:**
- Admins (role 1) and Clients (role 2) bypass this check
- For Freelancers (role 3):
  - Must have `is_verified = true`
  - Must have active subscription in `subscriptions` table

**Usage:**
```javascript
import requireVerifiedWithSubscription from "../middleware/requireVerifiedWithSubscription.js";

router.post("/apply", authentication, requireVerifiedWithSubscription, handler);
```

**Error Responses:**
- `403 Forbidden` - Account must be verified
- `403 Forbidden` - Active subscription required

---

## Socket.io Authentication

### Socket Authentication

**Location:** `middleware/authentication.js` (authSocket function)

**How it works:**
1. Client connects with token in `socket.handshake.auth.token`
2. Token is verified using JWT
3. Decoded user info is attached to `socket.user`
4. Socket is authenticated

**Client-side (Flutter):**
```dart
socket = io(
  'https://orderzhouse-backend.onrender.com',
  OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': jwtToken})
    .build()
);
```

---

## Token Refresh

**Current Implementation:**
- Tokens expire after 1 day
- No automatic refresh mechanism
- Users must login again after expiration

**Recommendation for Flutter:**
- Store token securely (flutter_secure_storage)
- Check token expiration before API calls
- Implement refresh logic or re-login flow

---

## Security Best Practices

1. **Token Storage:**
   - Never store tokens in plain text
   - Use secure storage (flutter_secure_storage)
   - Clear tokens on logout

2. **Token Transmission:**
   - Always use HTTPS in production
   - Include token in Authorization header (not query params)

3. **Error Handling:**
   - Handle 403 errors by redirecting to login
   - Clear stored tokens on authentication errors

4. **Password Security:**
   - Never send passwords in logs
   - Use HTTPS for all authentication requests
   - Implement password strength requirements

5. **OTP Security:**
   - OTPs expire quickly (2-5 minutes)
   - Limit OTP request rate
   - Clear OTPs after successful use

---

## Common Authentication Errors

| Status Code | Error | Solution |
|------------|-------|----------|
| 400 | Missing email/password | Provide required fields |
| 401 | Invalid credentials | Check email/password |
| 403 | Forbidden - No token | Include Authorization header |
| 403 | Token invalid/expired | Re-login to get new token |
| 403 | Account not verified | Verify email first |
| 403 | Subscription required | Subscribe to a plan |
| 404 | User not found | Check email address |
| 410 | Account permanently deleted | Contact support |

---

## Flutter Implementation Notes

### Storing Tokens
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Save token
await storage.write(key: 'jwt_token', value: token);

// Read token
String? token = await storage.read(key: 'jwt_token');

// Delete token (logout)
await storage.delete(key: 'jwt_token');
```

### Making Authenticated Requests
```dart
import 'package:http/http.dart' as http;

Future<http.Response> authenticatedGet(String url) async {
  final token = await storage.read(key: 'jwt_token');
  
  return await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
}
```

### Handling Token Expiration
```dart
if (response.statusCode == 403) {
  // Token expired or invalid
  await storage.delete(key: 'jwt_token');
  // Redirect to login screen
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## Summary

1. **Registration** → Email verification required
2. **Login** → JWT token returned (OTP if suspicious)
3. **2FA** → Optional, uses TOTP (Google Authenticator, etc.)
4. **Token Usage** → Include in Authorization header
5. **Role Checks** → Admin, Client, Freelancer have different permissions
6. **Freelancer Restrictions** → Must be verified + subscribed for certain actions
