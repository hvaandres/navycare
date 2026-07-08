//
//  MainTabView.swift
//  navycare
//
//  Root navigation container. Uses the iOS 18+ Tab API which
//  automatically renders with Liquid Glass on iOS 26+.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }

            Tab("Circle", systemImage: "person.3.fill") {
                CircleView()
            }

            Tab("Documents", systemImage: "doc.text.fill") {
                DocumentsView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
