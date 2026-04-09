# Mobile App Architecture Refactor – Audit & Notes

## A) Audit Summary

### 1. shared_preferences usage

| Key / pattern | Where | What it stores |
|---------------|--------|-----------------|
| `app_locale` | `lib/core/providers/locale_provider.dart` | Language code (e.g. `en`, `ar`) |
| `user_data` | `lib/services/storage_service.dart` | User JSON (id, username, email, role_id, etc.). **Only used by legacy** `lib/providers/auth_provider.dart` (ChangeNotifier). Active app uses `features/auth` (Riverpod) and does **not** persist user to prefs. |
| `app_cache_*` | `lib/core/cache/cache_service.dart` | Cached JSON (e.g. projects, categories). Keys like `app_cache_my_projects_<userId>`, `app_cache_explore_*`, `app_cache_explore_categories`, etc. |
| `app_cache_ts_*` | `lib/core/cache/cache_service.dart` | Timestamp (int) for corresponding cache entry. |
| `cr_last_seen_<userId>_<projectId>` | `lib/features/projects/data/change_requests_last_seen.dart` | Last-seen time for change requests (int, ms since epoch). |

**Conclusion:** No token or secret is stored in SharedPreferences. Token is in secure storage. User JSON in prefs is only from legacy auth; we will keep app_prefs for non-sensitive settings only and can migrate/clear legacy `user_data` on next start if desired.

### 2. flutter_secure_storage / token storage

- **Active auth:** `lib/core/storage/secure_storage_service.dart`  
  - Keys: `jwt_token`, `refresh_token`  
  - Used by: `AuthInterceptor`, `AuthRepository`, `features/auth/presentation/providers/auth_provider.dart`
- **Legacy:** `lib/services/storage_service.dart`  
  - Uses `FlutterSecureStorage` for token (key from `AppConstants.tokenKey` = `jwt_token`).  
  - Used by: `lib/providers/auth_provider.dart`, `lib/services/api_client.dart`  
  - App UI uses the **feature** auth provider; legacy path is not used by main flow.

**Conclusion:** Tokens are stored only in secure storage. We will add a single `lib/core/storage/secure_store.dart` (or standardize on SecureStorageService) for token read/write/delete and keep all tokens out of SharedPreferences.

### 3. equatable usage

- **pubspec.yaml:** `equatable: ^2.0.5` is present.
- **Code:** No Dart file imports or uses `equatable` or `Equatable`.

**Conclusion:** Equatable can be removed from dependencies (redundant with Freezed equality/copyWith).

### 4. Freezed models (equality / copyWith)

- Models using Freezed: `user.dart`, `api_response.dart`, `project.dart`, `category.dart`, `plan.dart` (and their `.freezed.dart` generated files).
- These get `==`, `hashCode`, and `copyWith` from Freezed; no need for Equatable.

### 5. Dio usage

- **Base URL:** `lib/core/config/app_config.dart` – `AppConfig.baseUrl` (from env: `APP_API_URL` or `BASE_URL`, default `http://10.0.2.2:5050`).
- **Client:** `lib/core/network/dio_client.dart` – singleton `DioClient.instance`, creates `Dio(BaseOptions(baseUrl: AppConfig.baseUrl, ...))`.
- **Interceptors (order):** `AuthInterceptor`, `LoggingInterceptor`, `ErrorInterceptor`, `RetryInterceptor` (in `dio_interceptors.dart`).
- **Auth:** `AuthInterceptor` reads token via `SecureStorageService.getToken()` and sets `Authorization: Bearer <token>`.
- **Requests:** Raw `_dio.get/post/put/patch` in repositories: `auth_repository`, `projects_repository`, `notifications_repository`, `payments_repository`, `categories_repository`, `messages_repository`, `offers_repository`, `referrals_repository`, `subscription_repository`, etc.

**Conclusion:** Add a typed API layer (e.g. Retrofit) on top of this Dio instance; keep baseUrl and interceptors in one place (e.g. `dio_client.dart`), and move endpoint definitions into a typed client.

### 6. Backend endpoints (for typed API / no 404)

- Explore / public projects: category filtering and search (see `projects_repository` and backend `projectsFiltering.js` / `router/projects.js`).
- Change requests: **GET** `/projects/:projectId/change-requests` (backend: `router/projects.js`).
- Notifications, payments, chat, etc.: as in existing repositories and `docs/API_MAP.md`.

---

## Implementation status

- **B)** app_prefs.dart – typed wrapper for locale, themeMode, onboardingSeen (no tokens).
- **C)** secure_store.dart – access/refresh token save/read/delete; auth and logout use it; clear user-specific caches on logout.
- **D)** Remove equatable from pubspec and any stray imports (none found).
- **E)** Local cache: Cache invalidation on logout/login implemented (CacheService.clearAll() + invalidate myProjects, explore, categories, notifications). Drift was added to pubspec but code generation timed out in this environment; to add Drift DB: add back `drift`, `drift_dev`, `sqlite3_flutter_libs`, create `lib/core/db/app_database.dart` with table CacheEntries (key, userId, data, updatedAt), run `dart run build_runner build`, then wire repositories to read/write cache from AppDatabase and clear on logout via clearForUser(userId).
- **F)** Typed API: `lib/core/network/api_client.dart` with typed methods (getMyProjects, getChangeRequests, getNotifications, getCategories, etc.). Repositories use ApiClient.instance; notifications and projects (my projects, change-requests) wired. Endpoints match backend (no 404).
- **G)** Safe dependency updates (dio, go_router, etc.); run pub get and code gen.
- **H)** Skeleton loading: Explore screen already uses `ExploreSkeletonGrid` when loading with no cached data; `exploreProjectsLastDataProvider` shows previous data + progress while refetching. No UI redesign.

---

*Last updated: refactor implementation.*
