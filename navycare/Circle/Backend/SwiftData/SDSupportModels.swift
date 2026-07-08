// SDSupportModels.swift
// navycare — Circle Backend
//
// Supporting SwiftData models: contacts (local only), sync queue,
// notification cache, and append-only audit log.

import Foundation
import SwiftData

// MARK: - SDContact

/// Device contact cached from CNContactStore.
/// Never synchronized to Firestore — device-local only.
@Model
final class SDContact {

    /// CNContact.identifier — stable across contact store updates.
    @Attribute(.unique) var cnIdentifier: String

    var firstName:        String
    var lastName:         String
    /// E.164-formatted phone numbers extracted from the contact.
    var phoneNumbers:     [String]
    var email:            String?
    /// `true` when this contact is an active circle member.
    var isInCircle:       Bool
    /// `true` when there is a pending invitation to this contact.
    var hasOpenInvitation: Bool
    var lastUpdated:      Date

    init(
        cnIdentifier:     String,
        firstName:        String,
        lastName:         String,
        phoneNumbers:     [String],
        email:            String?   = nil,
        isInCircle:       Bool      = false,
        hasOpenInvitation: Bool     = false,
        lastUpdated:      Date      = .now
    ) {
        self.cnIdentifier      = cnIdentifier
        self.firstName         = firstName
        self.lastName          = lastName
        self.phoneNumbers      = phoneNumbers
        self.email             = email
        self.isInCircle        = isInCircle
        self.hasOpenInvitation = hasOpenInvitation
        self.lastUpdated       = lastUpdated
    }
}

extension SDContact {
    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }
    var primaryPhone: String? { phoneNumbers.first }
}

// MARK: - SDSyncQueueItem

/// A pending write operation waiting to be dispatched to Firestore.
/// Processed by `SyncEngine` with exponential-backoff retries.
@Model
final class SDSyncQueueItem {

    @Attribute(.unique) var id: String
    var entityTypeRaw:  String     // SyncEntityType.rawValue
    var entityId:       String
    var operationRaw:   String     // SyncOperation.rawValue
    /// JSON-encoded delta payload for the Firestore write.
    var payload:        Data
    var attemptCount:   Int
    var maxAttempts:    Int
    var nextRetryAt:    Date
    var createdAt:      Date
    var lastError:      String?
    /// Set to `true` after `maxAttempts` are exhausted.
    var isFailed:       Bool

    init(
        id:             String       = UUID().uuidString,
        entityType:     SyncEntityType,
        entityId:       String,
        operation:      SyncOperation,
        payload:        Data,
        maxAttempts:    Int          = 5,
        nextRetryAt:    Date         = .now,
        createdAt:      Date         = .now
    ) {
        self.id            = id
        self.entityTypeRaw = entityType.rawValue
        self.entityId      = entityId
        self.operationRaw  = operation.rawValue
        self.payload       = payload
        self.attemptCount  = 0
        self.maxAttempts   = maxAttempts
        self.nextRetryAt   = nextRetryAt
        self.createdAt     = createdAt
        self.isFailed      = false
    }
}

extension SDSyncQueueItem {

    var entityType: SyncEntityType {
        SyncEntityType(rawValue: entityTypeRaw) ?? .invitation
    }

    var operation: SyncOperation {
        SyncOperation(rawValue: operationRaw) ?? .create
    }

    var hasRemainingAttempts: Bool { attemptCount < maxAttempts }

    /// Returns the next retry delay using exponential backoff (1s, 4s, 16s, 64s…).
    var nextBackoffDelay: TimeInterval {
        pow(4.0, Double(attemptCount))
    }

    mutating func recordFailure(error: String) {
        attemptCount += 1
        lastError     = error
        nextRetryAt   = Date.now.addingTimeInterval(nextBackoffDelay)
        if attemptCount >= maxAttempts { isFailed = true }
    }
}

// MARK: - SDNotificationCache

/// A local mirror of a received push notification.
@Model
final class SDNotificationCache {

    @Attribute(.unique) var id: String
    /// e.g. "invitation_accepted" | "caregiver_removed" | "invitation_received"
    var type:        String
    var title:       String
    var body:        String
    /// JSON-encoded notification payload for deep-link handling.
    var payload:     Data?
    var isRead:      Bool
    var receivedAt:  Date

    init(
        id:         String  = UUID().uuidString,
        type:       String,
        title:      String,
        body:       String,
        payload:    Data?   = nil,
        receivedAt: Date    = .now
    ) {
        self.id         = id
        self.type       = type
        self.title      = title
        self.body       = body
        self.payload    = payload
        self.isRead     = false
        self.receivedAt = receivedAt
    }
}

// MARK: - SDAuditLog

/// Append-only local audit trail. Mirrors the Firestore /auditLogs collection.
/// Never mutated after creation.
@Model
final class SDAuditLog {

    @Attribute(.unique) var id: String
    var action:      String     // e.g. "invitation_sent" | "caregiver_removed"
    var entityType:  String
    var entityId:    String
    var actorUID:    String
    var timestamp:   Date
    /// JSON-encoded context metadata (phone last4, relationship, etc.).
    var metadata:    Data?

    init(
        id:         String  = UUID().uuidString,
        action:     String,
        entityType: String,
        entityId:   String,
        actorUID:   String,
        timestamp:  Date    = .now,
        metadata:   Data?   = nil
    ) {
        self.id         = id
        self.action     = action
        self.entityType = entityType
        self.entityId   = entityId
        self.actorUID   = actorUID
        self.timestamp  = timestamp
        self.metadata   = metadata
    }
}
