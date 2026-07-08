//
//  navycareApp.swift
//  navycare
//
//  Created by Alan Haro on 6/12/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct navycareApp: App {

    // MARK: - UIKit delegate (APNs token forwarding)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - App-wide state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var appContainer  = AppContainer.shared
    @State private var deepLinkHandler = DeepLinkHandler()
    private let pushManager = PushNotificationManager.shared

    // MARK: - Init

    init() {
        // Firebase must be configured before anything else
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        FirebaseApp.configure()

        // Configure Google Sign-In
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }

        // Start push notification delegate chain
        pushManager.configure()

        // Wire FCM token refresh → Firestore + SwiftData
        pushManager.onTokenRefresh = { token in
            guard let uid = Auth.auth().currentUser?.uid else { return }
            Task {
                try? await FirestoreService.shared.updateFCMToken(uid: uid, token: token)
                try? await AppContainer.shared.userRepository.updateFCMToken(uid: uid, token: token)
            }
        }

        // Register background sync task
        AppContainer.shared.syncEngine.registerBackgroundTask()
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .withAuthentication()
                .environment(appContainer)
                .environment(deepLinkHandler)
                // Handle Google Sign-In and invitation deep links
                .onOpenURL { url in
                    if !GIDSignIn.sharedInstance.handle(url) {
                        deepLinkHandler.handle(url)
                    }
                }
                // Request push permission after onboarding completes
                .task {
                    if hasCompletedOnboarding {
                        await pushManager.requestPermission()
                    }
                }
                // Trigger sync when app comes to foreground
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)
                ) { _ in
                    Task { await appContainer.syncEngine.processSyncQueue() }
                }
        }
    }
}
