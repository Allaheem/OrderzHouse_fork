# Google Sign-In Setup

## 1. Mobile app .env

Add to `mobile_app/.env`:

```
GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Get this from [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → Create OAuth 2.0 Client ID → **Web application**.

## 2. Backend .env

Add to `backendEsModule/.env`:

```
GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

(Same Web Client ID as mobile. Backend verifies the idToken with Google.)

## 3. Backend endpoint

`POST /auth/google` is implemented. Body: `{ "idToken": "<google_id_token>" }`. Response same as `/users/login` (token, userInfo, must_accept_terms).

**Note:** Google login only works for **existing** users. If the Google email is not in the DB, the backend returns "No account found with this Google email. Please register first."

## 4. Android

- **SHA-1**: Add debug and release SHA-1 to the **Web application** OAuth client in Google Cloud Console (or create an Android OAuth client and add SHA-1 there).
- **Package name** must match `applicationId` in `build.gradle.kts`.
- **minSdk**: 21 (configured).

Get SHA-1:
```bash
# Debug (Windows: %USERPROFILE%\.android\debug.keystore)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

## 5. iOS

1. Create an **iOS** OAuth 2.0 client in Google Cloud Console.
2. Copy `ios/Flutter/Secrets.xcconfig.example` to **`ios/Flutter/Secrets.xcconfig`** (this file is gitignored).
3. Set `GOOGLE_REVERSED_CLIENT_ID` to your **Reversed Client ID** exactly as shown in Google Cloud (e.g. `com.googleusercontent.apps.123456789012-abcdefghijklmnop`).

`Info.plist` reads `$(GOOGLE_REVERSED_CLIENT_ID)` from that xcconfig at build time. **Do not** leave the literal `YOUR_IOS_CLIENT_ID` placeholder — App Store Connect rejects it (error **90158**): URL schemes may only use letters, digits, `.`, `-`, and `+` (no underscores).

**Before every `flutter build ipa` or Archive:** ensure `Secrets.xcconfig` exists on the machine doing the build.
