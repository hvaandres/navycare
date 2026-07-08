// RepositoryProtocols.swift
// navycare — Circle Backend
//
// Protocol-oriented repository interfaces.
// Concrete implementations (SwiftData) are in separate files.
// This separation enables unit testing with mock implementations.

import Foundation

// MARK: - Circle Repository Protocol

protocol CircleRepositoryProtocol: Sendable {
    /// Returns the circle for the given Loved One UID, or `nil` if not found locally.
    func fetchCircle(for lovedOneUID: String) async throws -> SDCircle?
    /// Returns all active members of a circle.
    func fetchMembers(circleId: String) async throws -> [SDCircleMember]
    /// Persists a new or updated circle record.
    func saveCircle(_ circle: SDCircle) async throws
    /// Removes a caregiver membership record locally.
    func removeMember(id: String) async throws
    /// Updates the local memberCount cache.
    func updateMemberCount(circleId: String, count: Int) async throws
}

// MARK: - Invitation Repository Protocol

protocol InvitationRepositoryProtocol: Sendable {
    /// Returns all invitations sent from the given user.
    func fetchInvitations(senderUID: String) async throws -> [SDInvitation]
    /// Returns the first active invitation matching a phone number.
    func fetchPendingInvitation(phone: String, circleId: String) async throws -> SDInvitation?
    /// Persists a new or updated invitation.
    func saveInvitation(_ invitation: SDInvitation) async throws
    /// Updates the status of an existing invitation.
    func updateInvitationStatus(id: String, status: InvitationStatusBE, acceptedByUID: String?) async throws
}

// MARK: - User Repository Protocol

protocol UserRepositoryProtocol: Sendable {
    /// Returns the profile for the currently signed-in user.
    func fetchCurrentUser(uid: String) async throws -> SDUserProfile?
    /// Creates or replaces the local user profile.
    func saveUser(_ profile: SDUserProfile) async throws
    /// Updates only the FCM token field.
    func updateFCMToken(uid: String, token: String) async throws
    /// Updates the user's role.
    func updateRole(uid: String, role: UserRole) async throws
}

// MARK: - Contact Repository Protocol

protocol ContactRepositoryProtocol: Sendable {
    /// Returns all cached device contacts.
    func fetchAllContacts() async throws -> [SDContact]
    /// Looks up a contact by CNContact identifier.
    func fetchContact(cnIdentifier: String) async throws -> SDContact?
    /// Bulk-replaces the contact cache from CNContactStore.
    func replaceContacts(with contacts: [SDContact]) async throws
    /// Marks a contact as having an open invitation.
    func markInvitationSent(cnIdentifier: String) async throws
}

// MARK: - Sync Queue Repository Protocol

protocol SyncQueueRepositoryProtocol: Sendable {
    /// Returns all items ready to retry (nextRetryAt ≤ now, not failed).
    func fetchPendingItems() async throws -> [SDSyncQueueItem]
    /// Enqueues a new sync operation.
    func enqueue(_ item: SDSyncQueueItem) async throws
    /// Removes an item after successful sync.
    func dequeue(id: String) async throws
    /// Records a failure and advances the retry schedule.
    func recordFailure(id: String, error: String) async throws
}
