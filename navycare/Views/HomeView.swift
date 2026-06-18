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
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("You're signed in")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                if let email = authManager.user?.email {
                    Text(email)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }

                Button(action: { authManager.signOut() }) {
                    Text("Sign Out")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                }
                .padding(.horizontal, 40)
                .padding(.top, 12)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
}
