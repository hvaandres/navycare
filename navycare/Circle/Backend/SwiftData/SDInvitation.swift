// SDInvitation.swift
// navycare — Circle Backend
//
// Persistent invitation record.
// IMPORTANT: Only the SHA-256 tokenHash is stored — never the plain token.
// The plain token exists only in the SMS URL and in memory during validation.

import Foundation
import SwiftData

@Model
final class SDInvitation {

    @Attribute(.unique) var id: String
    var circleId:       String
    var senderUID:      String

    /// E.164 format.
    var receiverPhone:  String
    var receiverName:   String
    var relationship:   String
    var permissionRaw:  String       // "admin" | "caregiver" | "viewer"

    var statusRaw:      String
    /// SHA-256 hash of the plain invitation token. Never store the plain token.
    var tokenHash:      String

    var createdAt:      Date
    var expiresAt:      Date
    var acceptedAt:     Date?
    var acceptedByUID:  String?
    var syncStatusRaw:  String

    var circle: SDCircle?

    init(
        id:            String,
        circleId:      String,
        senderUID:     String,
        receiverPhone: String,
        receiverName:  String,
        relationship:  String,
        permission:    String              = "caregiver",
        status:        InvitationStatusBE  = .pending,
        tokenHash:     String,
        createdAt:     Date                = .now,
        expiresAt:     Date,
        syncStatus:    SyncStatus          = .pendingCreate
    ) {
        self.id            = id
        self.circleId      = circleId
        self.senderUID     = senderUID
        self.receiverPhone = receiverPhone
        self.receiverName  = receiverName
        self.relationship  = relationship
        self.permissionRaw = permission
        self.statusRaw     = status.rawValue
        self.tokenHash     = tokenHash
        self.createdAt     = createdAt
        self.expiresAt     = expiresAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

// MARK: - Computed

extension SDInvitation {

    var status: InvitationStatusBE {
        get { InvitationStatusBE(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreate }
        set { syncStatusRaw = newValue.rawValue }
    }

    var isExpired: Bool {
        status == .pending && Date.now > expiresAt
    }

    var isPending: Bool { status == .pending && !isExpired }

    var permission: String { permissionRaw }
}

// MARK: - Factory

extension SDInvitation {
    /// Creates an invitation with a 7-day expiry window.
    static func make(
        id:            String        = UUID().uuidString,
        circleId:      String,
        senderUID:     String,
        receiverPhone: String,
        receiverName:  String,
        relationship:  String,
        permission:    String        = "caregiver",
        tokenHash:     String
    ) -> SDInvitation {
        SDInvitation(
            id:            id,
            circleId:      circleId,
            senderUID:     senderUID,
            receiverPhone: receiverPhone,
            receiverName:  receiverName,
            relationship:  relationship,
            permission:    permission,
            tokenHash:     tokenHash,
            expiresAt:     Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
        )
    }
}
