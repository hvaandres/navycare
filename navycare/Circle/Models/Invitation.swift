// Invitation.swift
// navycare — Circle Feature
//
// Represents an invitation sent to a potential care circle member.

import Foundation

// MARK: - Invitation Status

/// The lifecycle state of a Circle invitation.
enum InvitationStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case accepted
    case declined
    case expired

    var displayName: String {
        switch self {
        case .pending:  return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired:  return "Expired"
        }
    }

    var systemImage: String {
        switch self {
        case .pending:  return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .expired:  return "exclamationmark.circle.fill"
        }
    }

    /// Whether the invitation is still actionable.
    var isActive: Bool {
        self == .pending || self == .accepted
    }
}

// MARK: - Invitation

/// An invitation issued to bring someone into the care circle.
struct Invitation: Identifiable, Codable, Sendable {
    let id: UUID
    let invitationId: UUID
    let senderUserId: String
    let receiverUserId: String?
    let receiverName: String
    let receiverPhone: String
    let relationship: String
    let permission: Permission
    var status: InvitationStatus
    let createdDate: Date
    let expirationDate: Date
    var acceptedDate: Date?

    /// Returns `true` if the invitation window has elapsed without a response.
    var isExpired: Bool {
        status == .pending && Date() > expirationDate
    }
}

// MARK: - Mock

extension Invitation {
    static func mock(
        receiverName: String,
        receiverPhone: String,
        relationship: String,
        status: InvitationStatus = .pending,
        permission: Permission = .caregiver
    ) -> Invitation {
        Invitation(
            id: UUID(),
            invitationId: UUID(),
            senderUserId: "current_user",
            receiverUserId: nil,
            receiverName: receiverName,
            receiverPhone: receiverPhone,
            relationship: relationship,
            permission: permission,
            status: status,
            createdDate: Date(),
            expirationDate: Calendar.current.date(
                byAdding: .day, value: 7, to: Date()
            ) ?? Date(),
            acceptedDate: status == .accepted ? Date() : nil
        )
    }
}
