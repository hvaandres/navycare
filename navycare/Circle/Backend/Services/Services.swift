// Services.swift
// navycare — Circle Backend
//
// Business logic services. Each service orchestrates repositories and
// the SyncQueue — never touching ModelContext directly.

import Foundation
import SwiftData
import CryptoKit

// MARK: - Service Errors

enum ServiceError: LocalizedError {
    case circleFull
    case duplicateInvitation
    case invitationNotFound
    case unauthorized
    case phoneMismatch
    case invitationExpired
    case alreadyAccepted

    var errorDescription: String? {
        switch self {
        case .circleFull:          return "The care circle is already full (max 5 caregivers)."
        case .duplicateInvitation: return "An invitation has already been sent to this contact."
        case .invitationNotFound:  return "Invitation not found."
        case .unauthorized:        return "You are not authorized to perform this action."
        case .phoneMismatch:       return "Phone number does not match the invitation."
        case .invitationExpired:   return "This invitation has expired."
        case .alreadyAccepted:     return "This invitation has already been accepted."
        }
    }
}

// MARK: - Invitation Service

/// Orchestrates the full invitation lifecycle on the client side.
/// Server-side validation mirrors these checks in Cloud Functions.
@MainActor
final class InvitationService {

    private let invitationRepo: InvitationRepository
    private let circleRepo:     CircleRepository
    private let syncQueue:      SyncQueueRepository

    init(
        invitationRepo: InvitationRepository,
        circleRepo:     CircleRepository,
        syncQueue:      SyncQueueRepository
    ) {
        self.invitationRepo = invitationRepo
        self.circleRepo     = circleRepo
        self.syncQueue      = syncQueue
    }

    /// Creates a local invitation record and enqueues it for Firestore sync.
    /// The Cloud Function will send the SMS and generate the real token.
    /// Locally we store a placeholder tokenHash until the CF responds.
    func createInvitation(
        circleId:     String,
        senderUID:    String,
        receiverPhone: String,
        receiverName:  String,
        relationship:  String,
        permission:    String = "caregiver"
    ) async throws -> SDInvitation {

        // Local capacity check (fast path before hitting CF)
        if let circle = try await circleRepo.fetchCircle(for: senderUID), circle.isFull {
            throw ServiceError.circleFull
        }

        // Duplicate check
        if let _ = try await invitationRepo.fetchPendingInvitation(phone: receiverPhone, circleId: circleId) {
            throw ServiceError.duplicateInvitation
        }

        // Placeholder tokenHash — will be replaced with real hash from CF response
        let placeholderHash = SHA256
            .hash(data: Data(UUID().uuidString.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()

        let invitation = SDInvitation.make(
            circleId:      circleId,
            senderUID:     senderUID,
            receiverPhone: receiverPhone,
            receiverName:  receiverName,
            relationship:  relationship,
            permission:    permission,
            tokenHash:     placeholderHash
        )

        try await invitationRepo.saveInvitation(invitation)

        // Enqueue Firestore sync
        let payload = try JSONEncoder().encode(InvitationPayload(invitation: invitation))
        let item = SDSyncQueueItem(
            entityType: .invitation,
            entityId:   invitation.id,
            operation:  .create,
            payload:    payload
        )
        try await syncQueue.enqueue(item)

        return invitation
    }

    /// Revokes a pending invitation locally and enqueues the update.
    func revokeInvitation(id: String, senderUID: String) async throws {
        let invitations = try await invitationRepo.fetchInvitations(senderUID: senderUID)
        guard let invitation = invitations.first(where: { $0.id == id }) else {
            throw ServiceError.invitationNotFound
        }
        guard invitation.senderUID == senderUID else { throw ServiceError.unauthorized }
        guard invitation.isPending else { return } // already resolved

        try await invitationRepo.updateInvitationStatus(id: id, status: .expired, acceptedByUID: nil)

        let payload = try JSONEncoder().encode(["invitationId": id, "status": "expired"])
        let item = SDSyncQueueItem(
            entityType: .invitation,
            entityId:   id,
            operation:  .update,
            payload:    payload
        )
        try await syncQueue.enqueue(item)
    }
}

// MARK: - Circle Service

/// Manages circle membership operations on the client side.
@MainActor
final class CircleService {

    private let circleRepo: CircleRepository
    private let syncQueue:  SyncQueueRepository

    init(circleRepo: CircleRepository, syncQueue: SyncQueueRepository) {
        self.circleRepo = circleRepo
        self.syncQueue  = syncQueue
    }

    /// Removes a caregiver locally and enqueues the deletion for Firestore sync.
    func removeCaregiver(membershipId: String, circleId: String, actorUID: String) async throws {
        try await circleRepo.removeMember(id: membershipId)

        // Update cached count
        let members = try await circleRepo.fetchMembers(circleId: circleId)
        try await circleRepo.updateMemberCount(circleId: circleId, count: members.count)

        let payload = try JSONEncoder().encode(["membershipId": membershipId, "circleId": circleId])
        let item = SDSyncQueueItem(
            entityType: .member,
            entityId:   membershipId,
            operation:  .delete,
            payload:    payload
        )
        try await syncQueue.enqueue(item)
    }

    /// Applies a Firestore member snapshot received from a real-time listener.
    func applyRemoteMemberJoined(
        _ member: SDCircleMember,
        circleId: String
    ) async throws {
        // Idempotent: insert sets up a new record; SwiftData ignores duplicate @Attribute(.unique)
        let context = member.modelContext
        context?.insert(member)
        try context?.save()
        let members = try await circleRepo.fetchMembers(circleId: circleId)
        try await circleRepo.updateMemberCount(circleId: circleId, count: members.count)
    }
}

// MARK: - Notification Service

/// Handles inbound FCM push notifications and local notification scheduling.
@MainActor
final class NotificationService {

    enum NotificationType: String {
        case invitationReceived = "invitation_received"
        case invitationAccepted = "invitation_accepted"
        case invitationDeclined = "invitation_declined"
        case caregiverRemoved   = "caregiver_removed"
    }

    private let context: SDAuditLog.Type = SDAuditLog.self

    /// Parses an inbound APNs/FCM payload and returns a cacheable record.
    func parseNotification(userInfo: [AnyHashable: Any]) -> SDNotificationCache? {
        guard
            let type  = userInfo["type"]  as? String,
            let title = userInfo["title"] as? String,
            let body  = userInfo["body"]  as? String
        else { return nil }

        let payload = try? JSONSerialization.data(withJSONObject: userInfo)
        return SDNotificationCache(type: type, title: title, body: body, payload: payload)
    }

    /// Returns a human-readable alert body for a given notification type.
    func alertBody(for type: NotificationType, name: String) -> String {
        switch type {
        case .invitationReceived: return "\(name) invited you to join their care circle."
        case .invitationAccepted: return "\(name) accepted your invitation and joined your circle."
        case .invitationDeclined: return "\(name) declined your invitation."
        case .caregiverRemoved:   return "You have been removed from \(name)'s care circle."
        }
    }
}

// MARK: - Codable Helpers

private struct InvitationPayload: Encodable {
    let invitationId:  String
    let circleId:      String
    let senderUID:     String
    let receiverPhone: String
    let receiverName:  String
    let relationship:  String
    let permission:    String

    init(invitation: SDInvitation) {
        self.invitationId  = invitation.id
        self.circleId      = invitation.circleId
        self.senderUID     = invitation.senderUID
        self.receiverPhone = invitation.receiverPhone
        self.receiverName  = invitation.receiverName
        self.relationship  = invitation.relationship
        self.permission    = invitation.permission
    }
}
