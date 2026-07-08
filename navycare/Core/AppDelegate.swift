// AppDelegate.swift
// navycare — Core
//
// Minimal UIApplicationDelegate used exclusively to forward the APNs
// device token to Firebase Messaging. All other lifecycle is handled
// by SwiftUI's WindowGroup.
//
// Wired in navycareApp via:
//   @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

import UIKit
import FirebaseAuth

final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - APNs Token

    /// Firebase Messaging requires the APNs token to be set explicitly
    /// when using method swizzling disabled or SwiftUI lifecycle.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.apnsTokenReceived(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("AppDelegate: APNs registration failed — \(error.localizedDescription)")
    }

    // MARK: - Background Fetch (sync queue wakeup)

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            await AppContainer.shared.syncEngine.processSyncQueue()
            completionHandler(.newData)
        }
    }
}
