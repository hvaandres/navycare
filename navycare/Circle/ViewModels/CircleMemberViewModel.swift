// CircleMemberViewModel.swift
// navycare — Circle Feature
//
// Manages per-node interaction and animation state for a single caregiver.

import Foundation
import Observation

/// Drives the visual and interaction state of one caregiver node in the orbit.
@MainActor
@Observable
final class CircleMemberViewModel {

    // MARK: - State

    let caregiver: Caregiver

    var isExpanded: Bool = false
    var isLongPressing: Bool = false
    var showContextMenu: Bool = false

    // MARK: - Init

    init(caregiver: Caregiver) {
        self.caregiver = caregiver
    }

    // MARK: - Actions

    /// Triggers the spring-expand-then-contract tap feedback.
    func handleTap() async {
        isExpanded = true
        try? await Task.sleep(for: .milliseconds(220))
        isExpanded = false
    }

    func handleLongPress() {
        isLongPressing = true
        showContextMenu = true
    }

    func dismissContextMenu() {
        isLongPressing = false
        showContextMenu = false
    }
}
