//
//  HomeView.swift
//  navycare
//
//  Temporary placeholder shown once the user is authenticated. Real app
//  content will replace this in a later milestone.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Welcome to Navycare")
                        .font(.title2.bold())

                    if let email = authManager.user?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
}
