// Permission.swift
// navycare — Circle Feature
//
// Defines the level of access a caregiver holds within the care circle.

import Foundation

/// The access tier granted to a Circle member.
enum Permission: String, Codable, CaseIterable, Sendable {

    case admin     = "admin"
    case caregiver = "caregiver"
    case viewer    = "viewer"

    // MARK: Display

    var displayName: String {
        switch self {
        case .admin:     return "Admin"
        case .caregiver: return "Caregiver"
        case .viewer:    return "Viewer"
        }
    }

    /// Short description shown in permission pickers and badges.
    var accessDescription: String {
        switch self {
        case .admin:
            return "Full access — can manage the circle and all care settings"
        case .caregiver:
            return "Can view and update care information and daily logs"
        case .viewer:
            return "Read-only access to care updates and activity"
        }
    }

    var systemImage: String {
        switch self {
        case .admin:     return "crown.fill"
        case .caregiver: return "heart.fill"
        case .viewer:    return "eye.fill"
        }
    }
}
