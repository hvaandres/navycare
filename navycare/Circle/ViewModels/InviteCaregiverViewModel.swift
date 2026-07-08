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

    /// Calls the `createInvitation` Cloud Function, then returns a local `Caregiver`
    /// for immediate UI update. Firestore is the source of truth for the server record.
    func sendInvitation() async -> Caregiver? {
        guard canSend else { return nil }

        isSending    = true
        errorMessage = nil

        // Normalize phone to E.164 (+1 prefix for US numbers)
        let digits       = receiverPhone.filter(\.isNumber)
        let e164Phone    = receiverPhone.hasPrefix("+") ? receiverPhone : "+1\(digits)"
        let permissionRaw = permission.rawValue

        do {
            // --- Call Cloud Function ---
            struct Request: Encodable {
                let receiverPhone: String
                let receiverName:  String
                let relationship:  String
                let permission:    String
            }
            struct Response: Decodable {
                let invitationId: String
                let expiresAt:    String
            }

            let response: Response = try await CloudFunctionCaller.shared.call(
                "createInvitation",
                data: Request(
                    receiverPhone: e164Phone,
                    receiverName:  receiverName,
                    relationship:  relationship.trimmingCharacters(in: .whitespaces),
                    permission:    permissionRaw
                )
            )

            // Build a local Caregiver for immediate orbit UI update
            let invitation = Invitation(
                id:            UUID(),
                invitationId:  UUID(uuidString: response.invitationId) ?? UUID(),
                senderUserId:  "",
                receiverUserId: nil,
                receiverName:  receiverName,
                receiverPhone: e164Phone,
                relationship:  relationship,
                permission:    permission,
                status:        .pending,
                createdDate:   .now,
                expirationDate: .now
            )

            let caregiver = Caregiver(
                id:            UUID(),
                name:          receiverName,
                profileImageURL: nil,
                relationship:  relationship,
                permission:    permission,
                invitation:    invitation,
                isOnline:      false,
                orbitPosition: 0
            )

            isSending = false
            hasSent   = true
            return caregiver

        } catch let cfError as CloudFunctionError {
            isSending    = false
            errorMessage = cfError.localizedDescription
            return nil
        } catch {
            isSending    = false
            errorMessage = error.localizedDescription
            return nil
        }
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
