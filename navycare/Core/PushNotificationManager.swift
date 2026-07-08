// PushNotificationManager.swift
// navycare — Core (Step 9)
//
// Manages FCM device token registration and handles inbound push notifications.
//
// REQUIRES: Add FirebaseMessaging to the Xcode target via SPM
//   File → Add Package Dependencies → firebase-ios-sdk → FirebaseMessaging
//
// Setup in navycareApp:
//   1. Enable Push Notifications capability in Xcode
//   2. Enable Background Modes → Remote notifications
//   3. Call PushNotificationManager.shared.configure() from navycareApp.init()

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit
import Observation

// MARK: - Push Notification Manager

@Observable
@MainActor
final class PushNotificationManager: NSObject {

    static let shared = PushNotificationManager()

    // MARK: State

    private(set) var fcmToken: String?
    /// Set when a notification is tapped while the app is backgrounded.
    private(set) var pendingNotificationPayload: [String: Any]?

    // MARK: Dependencies (injected after AppContainer is ready)
    var onTokenRefresh: ((String) -> Void)?
    var onNotificationReceived: (([String: Any]) -> Void)?

    // MARK: - Setup

    /// Call once from `navycareApp.init()` before the scene is created.
    nonisolated func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    /// Requests notification permission and registers for APNs.
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("PushNotificationManager: permission request failed — \(error.localizedDescription)")
        }
    }

    /// Forwards the APNs device token to Firebase (called from navycareApp scene delegate).
    nonisolated func apnsTokenReceived(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func consumePendingPayload() {
        pendingNotificationPayload = nil
    }
}

// MARK: - MessagingDelegate

extension PushNotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { @MainActor in
            self.fcmToken = token
            self.onTokenRefresh?(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {

    /// Called when a notification arrives while the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user taps a notification.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            self.pendingNotificationPayload = userInfo as? [String: Any]
            self.onNotificationReceived?(userInfo as? [String: Any] ?? [:])
        }
        completionHandler()
    }
}

// MARK: - navycareApp Integration Snippet
//
// Add this to navycareApp:
//
//  @main
//  struct navycareApp: App {
//      @State private var appContainer = AppContainer.shared
//      private let pushManager = PushNotificationManager.shared
//
//      init() {
//          FirebaseApp.configure()
//          pushManager.configure()
//
//          // Wire token refresh to Firestore
//          pushManager.onTokenRefresh = { token in
//              guard let uid = Auth.auth().currentUser?.uid else { return }
//              Task {
//                  try? await FirestoreService.shared.updateFCMToken(uid: uid, token: token)
//                  try? await appContainer.userRepository.updateFCMToken(uid: uid, token: token)
//              }
//          }
//      }
//
//      var body: some Scene {
//          WindowGroup {
//              ContentView(...)
//                  .environment(appContainer)
//                  .onOpenURL { url in appContainer.deepLinkHandler.handle(url) }
//                  .task { await pushManager.requestPermission() }
//          }
//      }
//  }
