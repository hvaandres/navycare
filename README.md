# navycare

A SwiftUI iOS app. The first milestone is authentication only: a welcome screen
followed by a Login screen offering **Sign in with Apple** and **Sign in with
Google**, backed by Firebase Auth. The sign-in strategy is reused from the
`starving` app.

## Status
- Onboarding → Login → (placeholder) Home flow.
- Firebase Auth + Google Sign-In wired via Swift Package Manager.
- No credentials are committed; bring your own Firebase project (see `SETUP.md`).

## Getting started
See [SETUP.md](SETUP.md) for Firebase, Google, and Apple Sign-In configuration.

## Project layout
- `navycare/navycareApp.swift` — app entry; configures Firebase + Google Sign-In.
- `navycare/ContentView.swift` — onboarding/loading/login/home state machine.
- `navycare/Modifiers/AuthenticationModifier.swift` — `AuthenticationManager` + `withAuthentication()`.
- `navycare/Views/LoginView.swift` — Apple + Google login UI.
- `navycare/Views/OnBoardingView.swift` — welcome screen.
- `navycare/Views/HomeView.swift` — temporary signed-in placeholder.
