// BackendEnums.swift
// navycare — Circle Backend
//
// Shared enumerations used by all SwiftData models.
// Stored as raw String values for SwiftData compatibility.

import Foundation

// MARK: - Sync Status

/// Tracks the synchronization state of every persisted entity.
enum SyncStatus: String, Codable, Sendable {
    /// Matches the server record exactly.
    case synced
    /// Written locally, not yet pushed to Firestore.
    case pendingCreate
    /// Updated locally, not yet pushed to Firestore.
    case pendingUpdate
    /// Deleted locally, deletion not yet pushed to Firestore.
    case pendingDelete
    /// Local and remote versions diverged; requires manual resolution.
    case conflict
}

// MARK: - User Role

/// The role a Firebase Auth user holds within the app.
enum UserRole: String, Codable, Sendable {
    /// The person whose care is being coordinated — manages the circle.
    case lovedOne
    /// A trusted person invited into the circle.
    case caregiver
}

// MARK: - Invitation Status

/// Lifecycle states for a circle invitation.
enum InvitationStatusBE: String, Codable, Sendable {
    case pending
    case accepted
    case declined
    case expired

    /// Returns `true` when further action is meaningful.
    var isActive: Bool { self == .pending }
}

// MARK: - Sync Operation

/// The type of write operation queued for Firestore sync.
enum SyncOperation: String, Codable, Sendable {
    case create
    case update
    case delete
}

// MARK: - Sync Entity Type

/// Identifies which domain entity a sync queue item refers to.
enum SyncEntityType: String, Codable, Sendable {
    case invitation
    case circle
    case member
    case userProfile
    case notification
}
