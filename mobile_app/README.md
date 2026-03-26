# OrderzHouse Mobile App

Production-grade Flutter mobile app for OrderzHouse marketplace (Client & Freelancer roles).

## Architecture

- **State Management**: Riverpod
- **Routing**: go_router
- **Networking**: Dio with interceptors
- **Models**: Freezed + json_serializable
- **Storage**: flutter_secure_storage
- **Environment**: flutter_dotenv

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

Run code generation for freezed models and json_serializable:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Environment Configuration

Create a `.env` file in the `mobile_app` directory:

```env
BASE_URL=http://10.0.2.2:5000
ENV=development
```

**Note**: For Android emulator, use `http://10.0.2.2:5000` to access `localhost:5000` on your host machine.

### 4. Run the App

```bash
# For Android emulator
flutter run -d emulator-5554

# Or select device interactively
flutter run
```

## Project Structure

```text
lib/
├── core/
│   ├── config/          # App configuration
│   ├── network/         # Dio client & interceptors
│   ├── routing/         # go_router configuration
│   ├── storage/         # Secure storage service
│   ├── theme/           # Design system (colors, typography, spacing)
│   ├── widgets/         # Reusable UI components
│   ├── models/          # Core models (User, Project, etc.)
│   └── utils/           # Utilities (validators, etc.)
└── features/
    ├── auth/            # Authentication feature
    ├── freelancer/      # Freelancer-specific screens
    ├── client/          # Client-specific screens
    └── common/          # Shared screens (profile, payments, etc.)
```

## Features

### Authentication
- Login with email/password
- Registration with role selection (Client/Freelancer)
- Email verification
- OTP verification for suspicious logins
- Persistent session with JWT tokens

### Role-Based Navigation

**Freelancer:**
- Home (Dashboard)
- My Projects (Active/Pending/Completed)
- Explore Projects
- Payments
- Profile

**Client:**
- Home (Dashboard)
- My Projects
- Explore Talents
- Payments
- Profile

## API Integration

The app uses the backend API documented in `/docs/API_MAP.md` and `/docs/AUTH_FLOW.md`.

Base URL is configured via `.env` file. For Android emulator, use `http://10.0.2.2:<PORT>` to access localhost.

## Security

- JWT tokens stored securely using flutter_secure_storage
- Automatic token injection in API requests
- Global error handling for 401/403 (auto-logout)
- Input validation on client side
- No sensitive data in logs

## Development

### Code Generation

After modifying models, regenerate code:

```bash
flutter pub run build_runner watch
```

### Linting

Strict linting rules are configured in `analysis_options.yaml`. Fix issues:

```bash
flutter analyze
```

## Quality Gates

Run the production safety checks before opening a PR:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter test --coverage
flutter test integration_test
flutter test --update-goldens
```

Suggested CI order:
1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test --coverage`
5. `flutter test integration_test`

## Health Check

A health check screen is available at `/health-check` to test API connectivity.

## Notes

- All screens are placeholders and ready for API integration
- Design system is implemented for consistent UI
- Routing is role-based with separate navigation stacks
- Error handling and loading states are implemented
