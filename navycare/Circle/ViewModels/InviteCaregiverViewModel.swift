// InviteCaregiverViewModel.swift
// navycare — Circle Feature
//
// Manages state and logic for the invite caregiver flow.

import Foundation
import Contacts
import Observation

/// Drives the InviteCaregiverSheet form and send action.
@MainActor
@Observable
final class InviteCaregiverViewModel {

    // MARK: - State

    var selectedContact: CNContact?
    var relationship: String = ""
    var permission: Permission = .caregiver
    var personalMessage: String = ""
    var isSending: Bool = false
    var hasSent: Bool = false
    var showingContactPicker: Bool = false
    var errorMessage: String?

    // MARK: - Computed

    var receiverName: String {
        guard let contact = selectedContact else { return "" }
        return [contact.givenName, contact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var receiverPhone: String {
        selectedContact?.phoneNumbers.first?.value.stringValue ?? ""
    }

    var formattedPhone: String {
        receiverPhone.isEmpty ? "No phone number" : receiverPhone
    }

    var canSend: Bool {
        selectedContact != nil &&
        !relationship.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    /// Sends the invitation and returns the new `Caregiver` on success, or `nil` on failure.
    func sendInvitation() async -> Caregiver? {
        guard canSend else { return nil }

        isSending = true
        errorMessage = nil

        // Simulate network request
        do {
            try await Task.sleep(for: .seconds(1.2))
        } catch {
            isSending = false
            errorMessage = "Request was cancelled."
            return nil
        }

        let invitation = Invitation.mock(
            receiverName: receiverName,
            receiverPhone: receiverPhone,
            relationship: relationship,
            status: .pending,
            permission: permission
        )

        let caregiver = Caregiver(
            id: UUID(),
            name: receiverName,
            profileImageURL: nil,
            relationship: relationship,
            permission: permission,
            invitation: invitation,
            isOnline: false,
            orbitPosition: 0 // re-assigned by CircleViewModel
        )

        isSending = false
        hasSent = true
        return caregiver
    }

    func reset() {
        selectedContact = nil
        relationship = ""
        permission = .caregiver
        personalMessage = ""
        isSending = false
        hasSent = false
        errorMessage = nil
    }
}
