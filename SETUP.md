# Setup

navycare uses Firebase Authentication with **Sign in with Apple** and **Sign in
with Google**. Dependencies are managed with **Swift Package Manager** (no
CocoaPods/workspace). You must connect your own Firebase project before the app
will run.

## 1. Create a Firebase project
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a project.
2. Add an **iOS app** with bundle id `com.hvaandres.navycare`.
3. Under **Authentication → Sign-in method**, enable **Google** and **Apple**.

## 2. Add your GoogleService-Info.plist
1. Download `GoogleService-Info.plist` from the Firebase console.
2. Place it at `navycare/GoogleService-Info.plist`.
   - This path is gitignored so credentials are never committed.
   - In Xcode, make sure it is a member of the `navycare` target (drag it into
     the `navycare` group if needed so it is bundled at runtime).
3. See `GoogleService-Info.example.plist` for the expected structure.

## 3. Register the Google URL scheme
Open `Info.plist` (at the project root) and replace the placeholder URL scheme
`com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID` with the `REVERSED_CLIENT_ID`
value from your `GoogleService-Info.plist`.

## 4. Signing (Sign in with Apple)
- `navycare/navycare.entitlements` already enables the **Sign in with Apple** capability.
- In Xcode, select the `navycare` target → **Signing & Capabilities** and pick your team
  (the project currently uses `DEVELOPMENT_TEAM = F26L3GH72M`).
- In the [Apple Developer portal](https://developer.apple.com), make sure the App ID
  has **Sign in with Apple** enabled.

## 5. Resolve packages and run
1. Open `navycare.xcodeproj` in Xcode.
2. Xcode resolves the Swift packages automatically
   (`firebase-ios-sdk`, `GoogleSignIn-iOS`). To do it from the CLI:
   ```bash
   xcodebuild -project navycare.xcodeproj -scheme navycare -resolvePackageDependencies
   ```
3. Select a simulator and run (⌘R).

> Note: until a valid `GoogleService-Info.plist` is present, the app compiles but
> crashes on launch at `FirebaseApp.configure()`. This is expected.

## Dependencies (Swift Package Manager)
- `firebase-ios-sdk` — products `FirebaseAuth`, `FirebaseCore` (Up to Next Major from 11.5.0)
- `GoogleSignIn-iOS` — product `GoogleSignIn` (Up to Next Major from 7.1.0)
