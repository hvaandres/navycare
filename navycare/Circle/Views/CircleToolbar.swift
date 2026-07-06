// CircleToolbar.swift
// navycare — Circle Feature
//
// Navigation bar toolbar for the Circle screen.

import SwiftUI

/// Provides the trailing navigation bar items for the Circle screen.
struct CircleToolbar: ToolbarContent {

    let onSettingsTapped: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onSettingsTapped) {
                Image(systemName: "gearshape")
                    .fontWeight(.medium)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Circle settings")
        }
    }
}
