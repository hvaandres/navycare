//
//  navycareApp.swift
//  navycare
//
//  Created by Alan Haro on 6/12/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct navycareApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init() {
        // Enable verbose Firebase logging during development.
        FirebaseConfiguration.shared.setLoggerLevel(.debug)

        FirebaseApp.configure()

        // Configure Google Sign-In using the client ID from GoogleService-Info.plist.
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .withAuthentication()
        }
    }
}
