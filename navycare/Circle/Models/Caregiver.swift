// Caregiver.swift
// navycare — Circle Feature
//
// A trusted person in the Loved One's orbit.

import Foundation

/// A caregiver positioned in the care circle orbit.
struct Caregiver: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var profileImageURL: URL?
    var relationship: String
    var permission: Permission
    var invitation: Invitation?
    var isOnline: Bool
    /// Zero-based index in the five-slot orbit (0–4).
    var orbitPosition: Int

    // MARK: Computed

    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }

    var initials: String {
        name.components(separatedBy: " ")
            .compactMap(\.first)
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()
    }

    var invitationStatus: InvitationStatus? {
        invitation?.status
    }

    /// A stable color seed derived from the caregiver's name.
    var colorSeedIndex: Int {
        abs(name.hashValue) % 5
    }
}

// MARK: - Mock

extension Caregiver {
    static let mockData: [Caregiver] = [
        Caregiver(
            id: UUID(),
            name: "Sarah Johnson",
            profileImageURL: nil,
            relationship: "Daughter",
            permission: .admin,
            invitation: .mock(
                receiverName: "Sarah Johnson",
                receiverPhone: "+1 (555) 010-1000",
                relationship: "Daughter",
                status: .accepted,
                permission: .admin
            ),
            isOnline: true,
            orbitPosition: 0
        ),
        Caregiver(
            id: UUID(),
            name: "James Anderson",
            profileImageURL: nil,
            relationship: "Son",
            permission: .caregiver,
            invitation: .mock(
                receiverName: "James Anderson",
                receiverPhone: "+1 (555) 010-1001",
                relationship: "Son",
                status: .accepted
            ),
            isOnline: false,
            orbitPosition: 1
        ),
        Caregiver(
            id: UUID(),
            name: "Dr. Emily Chen",
            profileImageURL: nil,
            relationship: "Primary Doctor",
            permission: .viewer,
            invitation: .mock(
                receiverName: "Dr. Emily Chen",
                receiverPhone: "+1 (555) 010-1002",
                relationship: "Primary Doctor",
                status: .pending,
                permission: .viewer
            ),
            isOnline: true,
            orbitPosition: 2
        )
    ]
}
