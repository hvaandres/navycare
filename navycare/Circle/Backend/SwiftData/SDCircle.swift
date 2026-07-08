// SDCircle.swift
// navycare — Circle Backend
//
// Persistent representation of a care circle.
// circleId is identical to the lovedOneUID for simplicity.
// memberCount is a cached value — authoritative count lives in Firestore.

import Foundation
import SwiftData

// MARK: - SDCircle

@Model
final class SDCircle {

    @Attribute(.unique) var id: String
    /// Firebase UID of the person at the center.
    var lovedOneUID: String
    /// Cached member count — used for fast local capacity checks.
    var memberCount: Int

    var createdAt:    Date
    var updatedAt:    Date
    var lastSyncedAt: Date?
    var syncStatusRaw: String

    @Relationship(deleteRule: .cascade, inverse: \SDCircleMember.circle)
    var members: [SDCircleMember] = []

    @Relationship(deleteRule: .cascade, inverse: \SDInvitation.circle)
    var invitations: [SDInvitation] = []

    init(
        id:           String,
        lovedOneUID:  String,
        memberCount:  Int         = 0,
        createdAt:    Date        = .now,
        updatedAt:    Date        = .now,
        syncStatus:   SyncStatus  = .pendingCreate
    ) {
        self.id            = id
        self.lovedOneUID   = lovedOneUID
        self.memberCount   = memberCount
        self.createdAt     = createdAt
        self.updatedAt     = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension SDCircle {

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreate }
        set { syncStatusRaw = newValue.rawValue }
    }

    var isFull: Bool { memberCount >= 5 }
    var availableSlots: Int { max(0, 5 - memberCount) }
}

// MARK: - SDCircleMember

/// A single caregiver's membership record inside a circle.
@Model
final class SDCircleMember {

    /// Format: "{circleId}_{caregiverUID}"
    @Attribute(.unique) var id: String
    var circleId:       String
    var caregiverUID:   String

    /// Denormalized for offline display — no extra fetch required.
    var caregiverName:  String
    var caregiverPhone: String

    var relationship:   String
    var permissionRaw:  String       // "admin" | "caregiver" | "viewer"
    var joinedAt:       Date
    var invitationId:   String
    var syncStatusRaw:  String

    var circle: SDCircle?

    init(
        id:            String,
        circleId:      String,
        caregiverUID:  String,
        caregiverName: String,
        caregiverPhone: String,
        relationship:  String,
        permission:    String        = "caregiver",
        joinedAt:      Date          = .now,
        invitationId:  String,
        syncStatus:    SyncStatus    = .pendingCreate
    ) {
        self.id             = id
        self.circleId       = circleId
        self.caregiverUID   = caregiverUID
        self.caregiverName  = caregiverName
        self.caregiverPhone = caregiverPhone
        self.relationship   = relationship
        self.permissionRaw  = permission
        self.joinedAt       = joinedAt
        self.invitationId   = invitationId
        self.syncStatusRaw  = syncStatus.rawValue
    }
}

extension SDCircleMember {

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreate }
        set { syncStatusRaw = newValue.rawValue }
    }

    var permission: String { permissionRaw }

    /// Composite ID helper.
    static func makeID(circleId: String, caregiverUID: String) -> String {
        "\(circleId)_\(caregiverUID)"
    }
}
