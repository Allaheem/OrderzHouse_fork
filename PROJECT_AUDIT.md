# OrderzHouse — Full-Stack Marketplace Audit Report

Client/freelancer marketplace (Fiverr-like). This report is based on actual repository structure, routes, and code references. **No code was changed.**

---

## 1) Project map

### Main folders

| Folder | Contents |
|--------|----------|
| **`frontend/`** | Vite + React app: `src/` (components, adminDash, api, slice, store), `public/`, Tailwind |
| **`backendEsModule/`** | Express API: `router/`, `controller/`, `middleware/`, `models/`, `sockets/`, `cron/`, `services/` |
| **`mobile_app/`** | Flutter app (out of scope for this audit) |
| **`docs/`** | `API_MAP.md`, `AUTH_FLOW.md`, `DB_SCHEMA.md`, `MOBILE_DATA_FLOW.md` |

### Frontend — major pages & routes

| Route | File / component | Notes |
|-------|-------------------|--------|
| `/` | `Main.jsx` | Landing (Hero, Categories, Join Community, etc.) |
| `/login` | `Login.jsx` | Login + Google OAuth (client-side only) |
| `/register` | `Register.jsx` | Registration |
| `/privacy` | `Policy.jsx` | Privacy Policy |
| `/terms` | `Terms.jsx` | Terms of Service |
| `/about` | `About.jsx` | About page |
| `/contact` | `Contact.jsx` | Contact |
| `/plans` | `Plans.jsx` | Subscription plans |
| `/blogs`, `/blogs/:id` | `Blogs.jsx`, `BlogPost.jsx` | Blog list & post |
| `/create-project` | `CreateProjectPage.jsx` | Protected — create project |
| `/tasks`, `/tasks/create`, `/tasks/:id` | `ProjectsPage`, `CreateTaskPage`, `ProjectDetails` | Tasks flow |
| `/projectsPage` | `ProjectsPage` | Browse projects (protected) |
| `/projects/:id` | `ProjectDetails` | Project details (protected) |
| `/notifications` | `NotificationsPage` | Notifications (protected) |
| `/appointments`, `/admin/appointments`, `/my-appointments` | Appointments components | Role-based |
| `/admin/*` | `AdminRouter` → `Dashboard`, people, operation, finance, etc. | Role 1 only |
| `/client/*` | Same `AdminRouter` (Dashboard, projects, payments, etc.) | Role 2 |
| `/freelancer/*` | Same `AdminRouter` | Role 3 |
| `/partner/*` | Same `AdminRouter` | Role 5 |
| `/payment/success` | `PaymentSuccess` | Stripe success |
| `/account/suspended` | `AccountSuspended` | Suspended account |
| `/copywriting-test` | `CopywritingTest` | Freelancer-only test |
| `/freelancer/contract-terms`, `/freelancer/contract-signup` | Freelancer contract | Public/signup |
| `*` (404) | Inline div in `App.jsx` | Simple 404, no dedicated component |

**References:** `frontend/src/App.jsx`, `frontend/src/adminDash/routes/index.jsx`

### Backend — major API mounts

| Mount | Router file | Purpose |
|-------|-------------|---------|
| `/auth` | `router/auth.js` | 2FA, change-password, accept-terms (all after auth) |
| `/users` | `router/user.js` | register, login, verify-email, verify-otp, getUserdata, edit, rate, deactivate |
| `/category` | `router/category.js` | Categories (public GET), admin CRUD |
| `/projects` | `router/projects.js` | Create, myprojects, filtering, offers, assignments, admin |
| `/offers` | `router/offers.js` | Offers (apply, list, approve/reject, etc.) |
| `/assignments` | `router/assignments.js` | Assignment for freelancer |
| `/tasks` | `router/tasks.js` | Tasks (client/freelancer/admin) |
| `/chats`, `/chat` | `router/chats.js` | Chats & messages |
| `/notifications` | `router/notifications.js` | Notifications |
| `/payments` | `router/payments.js` | Payments |
| `/plans` | `router/plans.js` | Plans (admin/freelancer) |
| `/subscriptions` | `router/subscription.js` | Subscriptions |
| `/blogs` | `router/blogs.js` | Blogs |
| `/verification` | `router/verification.js` | Verification (admin) |
| `/admUser` | `router/adminUser.js` | Admin user CRUD |
| `/search` | `router/search.js` | Search |
| `/referrals` | `router/referrals.js` | Referrals |
| `/ratings` | `router/rating.js` | Ratings |
| `/stripe` | `router/Stripe/stripe.js`, `stripeWebhook.js` | Stripe checkout & webhook |

**References:** `backendEsModule/index.js`, `backendEsModule/router/*.js`

---

## 2) Auth & roles

| Item | Status | Notes / file |
|------|--------|---------------|
| Login (email/password) | ✅ | `backendEsModule/router/user.js` POST `/users/login`, `frontend/src/components/login/Login.jsx` |
| Register | ✅ | POST `/users/register`, `Register.jsx` |
| Email verification (OTP) | ✅ | POST `/users/verify-email`, `/users/verify-otp`, `/users/send-otp` |
| Google OAuth (UI) | ⚠️ | `Login.jsx` uses `@react-oauth/google`; `main.jsx` wraps with `GoogleOAuthProvider`. **Backend does not issue JWT for Google** — frontend stores Google credential as “token” and `decoded.sub` as userId; backend expects JWT from `/users/login`. API calls after “Google login” will get 403. |
| Session / JWT storage | ✅ | Token in `localStorage` + Redux; `userData` in cookie (`authSlice.js`). Backend: JWT in `Authorization: Bearer` (`middleware/authentication.js`). |
| Route guards (frontend) | ✅ | `ProtectedRoute.jsx`: checks token, then `userData`, then `is_deleted`, then `allowedRoles`. Redirects to `/login` or `/access-denied`. |
| `/access-denied` route | ❌ | `ProtectedRoute` redirects to `/access-denied`, but in `App.jsx` the only `<Route path="/access-denied" ...>` is **commented out** (with course routes). So role-forbidden users see the **404** catch-all page. **File:** `App.jsx` (uncomment or add route). |
| Role-based access (backend) | ✅ | `adminOnly.js`, `freelancerOnly.js`, `authorization.js` used on routes (e.g. category, plans, payments, adminUser, verification). |
| Terms acceptance check | ✅ | Backend `authentication.js` enforces terms before protected routes; `/auth/accept-terms` excluded. |
| 2FA | ✅ | Backend: `/auth/2fa/generate`, verify, disable, verify-login. |
| JWT expiry / refresh | ⚠️ | Backend signs with `JWT_SECRET`; no refresh token flow found. Frontend logs out on 401/403 (axios interceptors). |
| Password hashing | ✅ | Backend uses bcrypt (referenced in auth controller). |

**Missing / risks**

- ❌ **Google login:** Not integrated with backend; “Google token” is not a valid app JWT. Either add backend endpoint that accepts Google ID token and returns app JWT, or remove Google login until then.
- ❌ **Access-denied page:** Add or uncomment route in `App.jsx` and use a proper `AccessDenied` component (e.g. `components/coursesManagement/AccessDenied.jsx` uncommented or a new page).

---

## 3) Core flows coverage

### Client

| Flow | Status | Where |
|------|--------|--------|
| Create project | ✅ | `CreateProjectPage.jsx`, POST `/projects` (auth), Stripe checkout |
| Manage projects | ✅ | `/client/projects` → `ClientsProjects.jsx`, dashboard APIs |
| Applicants / offers | ✅ | Offers API, `AdminProjects.jsx` / project details (approve/reject) |
| Payments | ✅ | Stripe (`/stripe/project-checkout-session`), `PaymentSuccess.jsx`, payments history |

### Freelancer

| Flow | Status | Where |
|------|--------|--------|
| Browse / apply | ✅ | `ProjectsPage`, project details, offers (apply, list) |
| Deliveries | ✅ | Projects: submit delivery, resubmit; tasks: submit work completion (tasks router) |
| Chat / messages | ⚠️ | Backend: `/chats`, `/chat` (get messages, create). **Frontend:** `ChatPage.jsx` and routes are **commented out** in `App.jsx`. So chat UI is not reachable. |
| Payments / withdrawal | ⚠️ | Payments router exists; wallet/subscription logic in backend. Frontend: dashboard payments, plans; no dedicated “withdraw” page found. |

### Admin

| Flow | Status | Where |
|------|--------|--------|
| Moderation | ✅ | Verifications, blogs approve/reject, user verify |
| Disputes | ✅ | Projects: approve/reject delivery, request changes; payments/admin routes |
| Users | ✅ | `Admins.jsx`, `Clients.jsx`, `Freelancers.jsx`, `admUser` API |
| Projects | ✅ | `AdminProjects.jsx`, `ProjectDetailsDash.jsx`, projects router (getAll, reassign, admin approve) |

---

## 4) Data & API consistency

### Key endpoints used by frontend

- **Auth:** `POST /users/login`, `POST /users/register`, `POST /users/verify-email`, `POST /users/verify-otp`, `GET /users/getUserdata`, `PATCH /auth/change-password`, `POST /auth/accept-terms`
- **Categories:** `GET /category`, `GET /category/:id`, sub/sub-sub (e.g. `frontend/src/components/Catigories/api/category.js`, `CreateProjects/api/category.js`)
- **Projects:** `GET/POST /projects`, filtering, offers, assignments (e.g. `Catigories/api/projects.js`, `CreateProjects/api/projects.js`)
- **Tasks:** `GET/POST /tasks/*` (e.g. `Tasks/api/tasks.js`, `Catigories/api/tasks.js`)
- **Offers:** `.../offers` (e.g. `Catigories/api/offers.js`)
- **Dashboard:** `fetchClientDashboard`, `fetchFreelancerDashboard`, `fetchAdminDashboard` (`adminDash/api/dashboard.js`)
- **Payments:** Stripe, payments history (temp route in backend: `GET /payments/history`)
- **Notifications:** notifications API (e.g. `NotificationsPage.jsx`)
- **Blogs:** `GET /blogs` (e.g. `Blogs.jsx`, `adminDash/api/blogs.js`)

### baseURL / env issues

| File | Issue |
|------|--------|
| `adminDash/api/admin.js` | Uses `VITE_API_URL` (wrong). Vite convention is `VITE_APP_API_URL`. So with only `VITE_APP_API_URL` set, `API_BASE` is `""`. **Fix:** use `import.meta.env.VITE_APP_API_URL`. |
| `adminDash/pages/operation/Tasks.jsx` | `baseURL: import.meta.env.VITE_API_URL \|\| ""` — same wrong env name. |
| `adminDash/pages/insights/Analytics.jsx` | Same: `VITE_API_URL`. |
| `api/client.js` | ✅ Uses `VITE_APP_API_URL` with fallback `http://localhost:5050`. |
| `adminDash/api/axios.js` | ✅ Uses `VITE_APP_API_URL` (no fallback; can be undefined if env missing). |
| Others | Most use `VITE_APP_API_URL`; some use `\|\| ""` so requests can go to relative origin when undefined. |

### Pages that may fail fetch

- **Categories:** Depend on `VITE_APP_API_URL` and `GET /category`. If env is unset and no fallback, requests break (e.g. `category.js` uses `` `${import.meta.env.VITE_APP_API_URL}/category` ``).
- **Dashboard:** `dashboard.js` uses `API_BASE = import.meta.env.VITE_APP_API_URL || "http://localhost:5050"` — safe.
- **Admin user list:** Uses `admin.js` → `VITE_API_URL`; will be wrong unless fixed.

---

## 5) UI/UX completeness

| Area | Status | Notes |
|------|--------|--------|
| Responsive | ✅ | Tailwind breakpoints; Hero/Categories/Join Community scaled for 2xl/3xl/4xl; Dashboard “Your Lesson” has mobile carousel; Policy/Terms white layout. |
| Loading / skeleton | ✅ | Dashboard (skeleton rows/cards), Tables, AdminProjects, AssignFreelancersStep, Hero search “Loading…”, Payments, Notifications, etc. |
| Empty states | ✅ | “Nothing to show”, “No messages”, “No pending”, “No {title} found”, empty tables, LatestProjectsMiniTable empty. |
| Error handling / toasts | ✅ | `react-toastify` + `react-hot-toast` in `App.jsx`; axios 401/403 trigger logout; many components use toast on error. |
| Global loading overlay | ⚠️ | `GlobalLoadingProvider` / `axiosLoading.js` exist but are **commented out** in `App.jsx`. |

---

## 6) Security & production readiness

| Item | Status | Where |
|------|--------|--------|
| Input validation | ⚠️ | No express-validator/joi in backend. Controllers do ad-hoc checks (e.g. projects “missing required fields”). **Missing:** centralized validation for body/params/query. |
| Rate limiting | ❌ | Backend has a commented rate limiter in `index.js`. Not enabled. |
| CORS | ✅ | Configured in `index.js` (origin list, credentials, methods, headers). |
| CSRF | ⚠️ | Not used. Acceptable if API is JWT-only and CORS is strict; document decision. |
| Password hashing | ✅ | bcrypt in backend (e.g. auth/user controller). |
| JWT expiry / refresh | ⚠️ | JWT signed with `JWT_SECRET`; no refresh flow. Frontend logout on 401/403. |
| Permissions on backend | ✅ | `authentication`, `adminOnly`, `freelancerOnly`, `authorization("admin")` on sensitive routes. |
| File upload | ✅ | Multer with limits (e.g. 10MB, 50 files) in `uploadMiddleware.js`; type/extension checks not visible in snippet — recommend validating mime/extension. |
| .env / secrets | ✅ | Backend uses `dotenv` and `process.env` (DB, JWT, Stripe, Cloudinary, SMTP). `.env` exists (not in repo content). **Recommend:** `.env.example` with dummy values (see backend README). |
| Google client ID in frontend | ⚠️ | `main.jsx` has hardcoded `GoogleOAuthProvider clientId="308002675488-...".` Prefer `import.meta.env.VITE_GOOGLE_CLIENT_ID`. |

---

## 7) Missing pages / polish

| Item | Status | Notes |
|------|--------|--------|
| Privacy page | ✅ | `Policy.jsx`, route `/privacy`. |
| Terms page | ✅ | `Terms.jsx`, route `/terms`. |
| Help center / FAQ | ⚠️ | Landing has `Faq.jsx` section; no dedicated `/help` or help center page. |
| 404 page | ✅ | Inline in `App.jsx` (`path="*"`). Simple; could be a dedicated component. |
| 500 / error boundary | ❌ | No React Error Boundary or 500-style page. Uncaught errors can white-screen. |
| SEO / meta tags | ⚠️ | No systematic `<title>` / `<meta>` per route (e.g. react-helmet or similar). |
| Accessibility | ⚠️ | No project-wide a11y audit. Some `aria-label` and semantic HTML; not consistently checked. |

---

## 8) Priority plan (next steps)

### P0 — Must-fix before launch

| # | Description | Where to change |
|---|-------------|------------------|
| 1 | **Access-denied route:** Role-forbidden users are sent to `/access-denied` but get 404. | `frontend/src/App.jsx`: Add `<Route path="/access-denied" element={<AccessDenied />} />` and use a proper component (e.g. uncomment/restore `AccessDenied.jsx` or create a minimal “Access denied” page). |
| 2 | **Google login vs backend JWT:** After “Google login”, frontend uses Google credential as Bearer token; backend expects its own JWT. All authenticated API calls will 403. | Either: (a) Add backend endpoint (e.g. `POST /users/login-google`) that accepts Google ID token, finds/creates user, returns app JWT; then in `Login.jsx` call it and store that JWT. Or (b) Remove Google login until (a) is done. |
| 3 | **Admin API baseURL:** Admin user list and any use of `admin.js` use wrong env name. | `frontend/src/adminDash/api/admin.js`: Change `VITE_API_URL` to `VITE_APP_API_URL`. |
| 4 | **Tasks & Analytics baseURL:** Same wrong env. | `frontend/src/adminDash/pages/operation/Tasks.jsx`, `frontend/src/adminDash/pages/insights/Analytics.jsx`: Use `VITE_APP_API_URL` (and optionally fallback like `http://localhost:5050`). |
| 5 | **Ensure API URL everywhere:** Avoid undefined baseURL. | All files that use `import.meta.env.VITE_APP_API_URL`: Prefer a shared client (e.g. `api/client.js` or `adminDash/api/axios.js`) with a single fallback so all requests have a valid base. |

### P1 — Important

| # | Description | Where to change |
|---|-------------|------------------|
| 6 | **Chat UI:** Chat routes are commented out; backend is ready. | `frontend/src/App.jsx`: Uncomment Chat routes; fix any Chat component or API so chat is reachable. |
| 7 | **Rate limiting:** Prevent brute-force and abuse. | `backendEsModule/index.js`: Uncomment and tune rate limiter; consider stricter limits on `/users/login`, `/users/register`. |
| 8 | **Input validation:** Add validation for critical payloads. | Backend: Add express-validator (or joi) for `/users/register`, `/users/login`, `/projects` create, and other mutation endpoints. |
| 9 | **Error boundary:** Avoid white screen on uncaught errors. | `frontend/src`: Add an Error Boundary component and wrap app (or main route tree) in `App.jsx`; optionally add a simple 500-style page. |
| 10 | **.env.example:** So new devs/deploys know required vars. | `backendEsModule/.env.example`, `frontend/.env.example`: List all required keys (no real secrets); backend README already documents some. |

### P2 — Nice-to-have

| # | Description | Where to change |
|---|-------------|------------------|
| 11 | **JWT refresh:** Reduce re-login on token expiry. | Backend: Implement refresh token (e.g. in `auth` or `user` controller); frontend: store refresh token, call refresh on 401 where appropriate. |
| 12 | **Google Client ID in env:** Avoid hardcoding. | `frontend/main.jsx`: Use `import.meta.env.VITE_GOOGLE_CLIENT_ID`; add to `frontend/.env.example`. |
| 13 | **SEO / meta:** Per-route title and description. | Frontend: Use react-helmet-async or similar and set `<title>` and `<meta name="description">` per route. |
| 14 | **404 component:** Dedicated 404 page. | `frontend/src`: Create e.g. `components/NotFound.jsx` and use it in `App.jsx` for `path="*"`. |
| 15 | **Help center:** Dedicated help/FAQ page. | Frontend: Add route `/help` and a page that reuses or extends FAQ content. |
| 16 | **File upload validation:** Mime type and extension allowlist. | `backendEsModule/middleware/uploadMiddleware.js` (or where multer is used): Add validation for allowed types/extensions and reject others. |

---

**End of audit.** All findings are based on the current codebase; implement P0 before launch, then P1/P2 as needed.
