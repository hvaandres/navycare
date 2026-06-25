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
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
