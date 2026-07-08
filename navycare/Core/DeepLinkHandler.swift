// DeepLinkHandler.swift
// navycare — Core (Step 6)
//
// Handles deep links for invitation flow WITHOUT requiring a custom domain.
//
// Strategy (no domain required):
//   1. Custom URL Scheme — "navycare://invite/{token}"
//      Registered in Info.plist CFBundleURLSchemes.
//      Works when app is already installed.
//
//   2. Firebase Hosting redirect page (free, hosted at your-project.web.app)
//      SMS link goes to: https://navycare-XXXXX.web.app/invite/{token}
//      That page detects the platform:
//        • App installed  → opens navycare://invite/{token}
//        • App not installed → redirects to App Store
//
// Setup in Xcode (no domain needed):
//   1. Open Info.plist → Add CFBundleURLTypes entry:
//      CFBundleURLSchemes: ["navycare"]
//      CFBundleURLName: "com.hvaandres.navycare"
//   2. Deploy functions/hosting/public/* to Firebase Hosting
//
// Usage in navycareApp:
//   .onOpenURL { url in deepLinkHandler.handle(url) }

import Foundation
import Observation

// MARK: - Deep Link

/// Represents a parsed, actionable deep link.
enum DeepLink: Equatable {
    /// An invitation token extracted from navycare.com/invite/{token}
    case invitation(token: String)
    /// Unrecognized or malformed URL
    case unknown
}

// MARK: - Deep Link Handler

@Observable
@MainActor
final class DeepLinkHandler {

    /// The pending deep link waiting to be acted on.
    /// Cleared once the app has routed to the correct screen.
    private(set) var pendingLink: DeepLink?

    // MARK: - Parse

    /// Parses a URL and stores it as `pendingLink`.
    /// Call from `navycareApp.body` via `.onOpenURL { url in handler.handle(url) }`.
    func handle(_ url: URL) {
        let link = DeepLinkHandler.parse(url)
        guard link != .unknown else { return }
        pendingLink = link
    }

    /// Clears the pending link after the app has handled it.
    func consume() {
        pendingLink = nil
    }

    // MARK: - Route

    /// Returns `true` when there is an invitation deep link awaiting processing.
    var hasPendingInvitation: Bool {
        if case .invitation = pendingLink { return true }
        return false
    }

    /// Extracts the token from the pending invitation link, if present.
    var pendingInvitationToken: String? {
        if case .invitation(let token) = pendingLink { return token }
        return nil
    }

    // MARK: - Static Parser

    static func parse(_ url: URL) -> DeepLink {
        // PRIMARY: Custom scheme — navycare://invite/{token}
        // Registered in Info.plist, no domain required.
        if url.scheme == "navycare",
           url.host == "invite",
           let token = url.pathComponents.first(where: { !$0.isEmpty && $0 != "/" }),
           !token.isEmpty
        {
            return .invitation(token: token)
        }

        // SECONDARY: Firebase Hosting URL — https://{project}.web.app/invite/{token}
        // Arrives when the app IS installed and iOS opens the URL natively.
        if let host = url.host,
           host.hasSuffix(".web.app"),
           url.pathComponents.count >= 3,
           url.pathComponents[1] == "invite"
        {
            let token = url.pathComponents[2]
            guard !token.isEmpty else { return .unknown }
            return .invitation(token: token)
        }

        return .unknown
    }
}
