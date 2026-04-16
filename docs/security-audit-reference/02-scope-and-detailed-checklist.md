# Scope and Detailed Checklist

## Scope

Audit EVERYTHING inside this workspace recursively, including but not limited to:

- Flutter / Dart code
- React code
- Node.js backend code
- Routes, controllers, middleware, services
- Authentication and session logic
- Token handling (JWT, refresh tokens, API keys)
- Local storage / secure storage usage
- HTTP clients / interceptors
- Role-based access control / permission checks
- Input validation / sanitization
- File upload handlers
- Error handling / exception exposure
- Logging of secrets / PII
- Database query construction
- ORM usage and unsafe raw queries
- CORS / CSRF / XSS / SSRF / IDOR / open redirect risks
- Rate limiting / brute force protections
- Dependency vulnerabilities
- Hardcoded secrets / keys / tokens / passwords
- .env usage and secret leakage patterns
- Insecure cryptography usage
- Transport security assumptions
- Insecure debug flags / dev configs in production paths
- Build scripts, Dockerfiles, CI files, reverse proxy configs if present
- Mobile app-specific risks (secure storage, certificate pinning presence/absence, deep links, local caching, screenshots, rooted/jailbroken handling if applicable)
- Web-specific risks (DOM injection, token storage, dangerous HTML rendering, CSP-related gaps if detectable)
- API-specific risks (auth bypass, broken object level authorization, mass assignment, insecure defaults, missing validation)
- Business logic issues in booking/reservation/payment/privilege workflows if present
- Warning signs, weak patterns, and code smells that could become vulnerabilities later

## What to look for in detail

### A) Authentication and session security
- Weak login flow
- Missing account lockout or rate limits
- Weak password policy indicators
- Insecure JWT handling
- Long-lived tokens without rotation
- Refresh token misuse
- Tokens stored insecurely in local storage/session storage/plain preferences
- Missing revocation strategy
- Missing logout invalidation
- Missing re-auth for sensitive actions
- Session fixation or broken session lifecycle patterns

### B) Authorization / access control
- Missing role checks
- Backend trusting frontend role flags
- IDOR / BOLA risks
- Missing ownership validation
- Horizontal and vertical privilege escalation patterns
- Admin routes exposed without strict enforcement
- Inconsistent auth middleware coverage

### C) Input handling / injection risks
- Missing schema validation
- Unsafe deserialization
- Raw query building
- Dynamic code execution
- Unsafe file operations
- Path traversal indicators
- Dangerous template rendering
- XSS sinks
- HTML injection
- Command execution patterns
- SSRF-prone URL fetch logic

### D) Web security
- Unsafe dangerouslySetInnerHTML usage
- Unsanitized rendering from APIs
- Missing CSRF protections if cookie auth is used
- Token leakage to browser storage
- Overexposed client-side environment variables
- Weak route guarding assumptions
- Sensitive data exposed in source maps or client bundles
- UI integrity checks: every visible button/action must trigger a real, intended function (no dead buttons/placeholders in production paths)
- UI-to-backend consistency: critical buttons (approve/pay/cancel/delete/admin actions) must be backed by server-enforced authorization and validation

### E) Flutter / mobile security
- Secrets embedded in app
- API keys hardcoded in Dart
- Tokens cached insecurely
- Sensitive data written to logs
- Insecure storage usage instead of secure storage
- Weak certificate trust patterns
- Debug-only code leaking to production
- Weak deep link / intent handling
- Unprotected local database/cache for sensitive data
- Screenshot/background exposure risks if relevant
- Missing jailbreak/root/emulator detection only as informative, not as sole control

### F) Backend / Node.js security
- Missing helmet / security headers if applicable
- Weak CORS policy
- No rate limiting on auth or sensitive routes
- Trust proxy misuse
- Verbose error leakage
- Unsafely merged request bodies
- Prototype pollution exposure patterns
- Insecure file upload validation
- Missing request size limits
- Missing centralized validation
- Missing audit logs for sensitive actions
- Weak secret management
- Insecure use of child_process / eval / Function constructor

### G) Dependency / supply chain / config security
- Known vulnerable packages if lockfiles indicate risky versions
- Abandoned or suspicious packages
- Overly broad dependency footprint
- Exposed .env or sample secrets
- Dev secrets committed to repo
- Insecure Docker defaults
- Containers running as root
- Debug ports or admin panels exposed in configs
- CI/CD leaking secrets in scripts
- Unsafe GitHub Actions / pipeline patterns if present

### H) Privacy / sensitive data
- PII logging
- Payment-related sensitive field handling
- Booking/reservation user data exposure
- Missing masking/redaction
- Insecure analytics events
- Excessive data retention patterns visible in code

### I) Booking / reservation / workflow logic
If booking/reservation/order/scheduling logic exists, inspect for:
- Race conditions / double booking risk
- Missing inventory/slot locking
- Price/fee tampering trust on client input
- Unauthorized booking modification/cancellation
- Inconsistent state transitions
- Replay or duplicate submission issues
- Weak server-side validation of booking ownership
- Refund/cancel flow misuse risk
- Promo/coupon abuse logic if present

### J) Warning signs / code smells
Flag patterns that are not confirmed vulnerabilities but are dangerous, such as:
- TODO/FIXME around auth/security
- Disabled validation
- “temporary” bypass code
- Debug endpoints
- Mock auth code still reachable
- Commented secrets
- Hidden admin flags
- Environment fallbacks that silently disable protections
- Buttons or UI controls rendered without implemented handlers (dead actions), especially in auth/payment/admin/booking flows
