//
//  CircleView.swift
//  navycare
//
//  Care circle — your trusted group of caregivers and contacts.
//

import SwiftUI

struct CircleView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)

                    Text("Your Circle")
                        .font(.title2.bold())

                    Text("Your care circle will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle("Circle")
        }
    }
}

#Preview {
    CircleView()
}
