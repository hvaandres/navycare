// CircleViewModel.swift
// navycare — Circle Feature
//
// Drives the entire Circle screen. Owns all circle state and user actions.

import Foundation
import Observation

/// Primary view model for the Circle feature.
@MainActor
@Observable
final class CircleViewModel {

    // MARK: - State

    var lovedOne: LovedOne
    var caregivers: [Caregiver]

    /// The caregiver whose detail card is currently open.
    var selectedCaregiver: Caregiver?
    /// Orbit slot index tapped to trigger the invite sheet.
    var selectedSlotIndex: Int?

    var showingInviteSheet: Bool = false
    var showingMemberCard: Bool = false
    var showingLovedOneDetail: Bool = false

    // MARK: - Constants

    let maxCaregivers: Int = 5

    // MARK: - Init

    init(
        lovedOne: LovedOne = .mock,
        caregivers: [Caregiver] = Caregiver.mockData
    ) {
        self.lovedOne = lovedOne
        self.caregivers = caregivers
    }

    // MARK: - Computed

    /// All five orbit slots — filled positions followed by empty placeholders.
    var caregiverSlots: [CaregiverSlot] {
        let filled = caregivers.prefix(maxCaregivers).map { CaregiverSlot.filled($0) }
        let emptyStart = filled.count
        let empty = (0 ..< (maxCaregivers - filled.count))
            .map { CaregiverSlot.empty(slotIndex: emptyStart + $0) }
        return Array(filled) + empty
    }

    var canAddCaregiver: Bool { caregivers.count < maxCaregivers }

    var onlineCaregiverCount: Int { caregivers.filter(\.isOnline).count }

    // MARK: - Actions

    func tapCaregiver(_ caregiver: Caregiver) {
        selectedCaregiver = caregiver
        showingMemberCard = true
    }

    func tapSlot(_ slotIndex: Int) {
        guard canAddCaregiver else { return }
        selectedSlotIndex = slotIndex
        showingInviteSheet = true
    }

    func tapLovedOne() {
        showingLovedOneDetail = true
    }

    func addCaregiver(_ caregiver: Caregiver) {
        guard caregivers.count < maxCaregivers else { return }
        var positioned = caregiver
        positioned.orbitPosition = caregivers.count
        caregivers.append(positioned)
    }

    func removeCaregiver(_ caregiver: Caregiver) {
        caregivers.removeAll { $0.id == caregiver.id }
        // Reassign contiguous orbit positions
        for i in caregivers.indices {
            caregivers[i].orbitPosition = i
        }
    }

    func dismissMemberCard() {
        showingMemberCard = false
        selectedCaregiver = nil
    }
}
