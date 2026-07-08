//
//  ContentView.swift
//  navycare
//
//  Created by Alan Haro on 6/12/26.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(DeepLinkHandler.self) private var deepLinkHandler

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnBoardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if authManager.isRestoringSession {
                // Loading state while Firebase restores the persisted session.
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            } else if !authManager.isSignedIn {
                LoginView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                MainTabView()
            }
        }
        // Deep link — invitation acceptance sheet
        .sheet(isPresented: .constant(deepLinkHandler.hasPendingInvitation && authManager.isSignedIn)) {
            if let token = deepLinkHandler.pendingInvitationToken {
                InvitationAcceptanceView(token: token) {
                    deepLinkHandler.consume()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .interactiveDismissDisabled()
            }
        }
        // When a deep link arrives before sign-in, it waits here.
        // Once isSignedIn flips to true, the sheet auto-presents.
        .onChange(of: authManager.isSignedIn) { _, signedIn in
            if signedIn, deepLinkHandler.hasPendingInvitation {
                // Sheet will auto-present via the .sheet binding above
            }
        }
    }
}
