// SwiftDataRepositories.swift
// navycare — Circle Backend
//
// Concrete SwiftData-backed repository implementations.
// All writes happen on the ModelContext's actor to satisfy Swift 6 concurrency.

import Foundation
import SwiftData

// MARK: - Errors

enum RepositoryError: LocalizedError {
    case notFound(String)
    case saveFailed(String)
    case contextUnavailable

    var errorDescription: String? {
        switch self {
        case .notFound(let id):          return "Record not found: \(id)"
        case .saveFailed(let reason):    return "Save failed: \(reason)"
        case .contextUnavailable:        return "ModelContext is unavailable"
        }
    }
}

// MARK: - Circle Repository

@MainActor
final class CircleRepository: CircleRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchCircle(for lovedOneUID: String) throws -> SDCircle? {
        let descriptor = FetchDescriptor<SDCircle>(
            predicate: #Predicate { $0.lovedOneUID == lovedOneUID }
        )
        return try context.fetch(descriptor).first
    }

    nonisolated func fetchCircle(for lovedOneUID: String) async throws -> SDCircle? {
        try await MainActor.run { try self.fetchCircle(for: lovedOneUID) }
    }

    func fetchMembers(circleId: String) throws -> [SDCircleMember] {
        let descriptor = FetchDescriptor<SDCircleMember>(
            predicate: #Predicate { $0.circleId == circleId },
            sortBy: [SortDescriptor(\.joinedAt)]
        )
        return try context.fetch(descriptor)
    }

    nonisolated func fetchMembers(circleId: String) async throws -> [SDCircleMember] {
        try await MainActor.run { try self.fetchMembers(circleId: circleId) }
    }

    func saveCircle(_ circle: SDCircle) throws {
        context.insert(circle)
        try context.save()
    }

    nonisolated func saveCircle(_ circle: SDCircle) async throws {
        try await MainActor.run { try self.saveCircle(circle) }
    }

    func removeMember(id: String) throws {
        let descriptor = FetchDescriptor<SDCircleMember>(
            predicate: #Predicate { $0.id == id }
        )
        guard let member = try context.fetch(descriptor).first else { return }
        context.delete(member)
        try context.save()
    }

    nonisolated func removeMember(id: String) async throws {
        try await MainActor.run { try self.removeMember(id: id) }
    }

    func updateMemberCount(circleId: String, count: Int) throws {
        let descriptor = FetchDescriptor<SDCircle>(
            predicate: #Predicate { $0.id == circleId }
        )
        guard let circle = try context.fetch(descriptor).first else { return }
        circle.memberCount = count
        circle.updatedAt   = .now
        circle.syncStatus  = .synced
        try context.save()
    }

    nonisolated func updateMemberCount(circleId: String, count: Int) async throws {
        try await MainActor.run { try self.updateMemberCount(circleId: circleId, count: count) }
    }
}

// MARK: - Invitation Repository

@MainActor
final class InvitationRepository: InvitationRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchInvitations(senderUID: String) throws -> [SDInvitation] {
        let descriptor = FetchDescriptor<SDInvitation>(
            predicate: #Predicate { $0.senderUID == senderUID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    nonisolated func fetchInvitations(senderUID: String) async throws -> [SDInvitation] {
        try await MainActor.run { try self.fetchInvitations(senderUID: senderUID) }
    }

    func fetchPendingInvitation(phone: String, circleId: String) throws -> SDInvitation? {
        let pendingRaw = InvitationStatusBE.pending.rawValue
        let descriptor = FetchDescriptor<SDInvitation>(
            predicate: #Predicate {
                $0.receiverPhone == phone &&
                $0.circleId      == circleId &&
                $0.statusRaw     == pendingRaw
            }
        )
        return try context.fetch(descriptor).first
    }

    nonisolated func fetchPendingInvitation(phone: String, circleId: String) async throws -> SDInvitation? {
        try await MainActor.run { try self.fetchPendingInvitation(phone: phone, circleId: circleId) }
    }

    func saveInvitation(_ invitation: SDInvitation) throws {
        context.insert(invitation)
        try context.save()
    }

    nonisolated func saveInvitation(_ invitation: SDInvitation) async throws {
        try await MainActor.run { try self.saveInvitation(invitation) }
    }

    func updateInvitationStatus(id: String, status: InvitationStatusBE, acceptedByUID: String?) throws {
        let descriptor = FetchDescriptor<SDInvitation>(
            predicate: #Predicate { $0.id == id }
        )
        guard let invitation = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound(id)
        }
        invitation.status        = status
        invitation.acceptedByUID = acceptedByUID
        invitation.acceptedAt    = status == .accepted ? .now : nil
        invitation.syncStatus    = .synced
        try context.save()
    }

    nonisolated func updateInvitationStatus(id: String, status: InvitationStatusBE, acceptedByUID: String?) async throws {
        try await MainActor.run { try self.updateInvitationStatus(id: id, status: status, acceptedByUID: acceptedByUID) }
    }
}

// MARK: - User Repository

@MainActor
final class UserRepository: UserRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchCurrentUser(uid: String) throws -> SDUserProfile? {
        let descriptor = FetchDescriptor<SDUserProfile>(
            predicate: #Predicate { $0.uid == uid }
        )
        return try context.fetch(descriptor).first
    }

    nonisolated func fetchCurrentUser(uid: String) async throws -> SDUserProfile? {
        try await MainActor.run { try self.fetchCurrentUser(uid: uid) }
    }

    func saveUser(_ profile: SDUserProfile) throws {
        context.insert(profile)
        try context.save()
    }

    nonisolated func saveUser(_ profile: SDUserProfile) async throws {
        try await MainActor.run { try self.saveUser(profile) }
    }

    func updateFCMToken(uid: String, token: String) throws {
        guard let profile = try fetchCurrentUser(uid: uid) else { return }
        profile.fcmToken   = token
        profile.updatedAt  = .now
        profile.syncStatus = .pendingUpdate
        try context.save()
    }

    nonisolated func updateFCMToken(uid: String, token: String) async throws {
        try await MainActor.run { try self.updateFCMToken(uid: uid, token: token) }
    }

    func updateRole(uid: String, role: UserRole) throws {
        guard let profile = try fetchCurrentUser(uid: uid) else { return }
        profile.role       = role
        profile.updatedAt  = .now
        profile.syncStatus = .pendingUpdate
        try context.save()
    }

    nonisolated func updateRole(uid: String, role: UserRole) async throws {
        try await MainActor.run { try self.updateRole(uid: uid, role: role) }
    }
}

// MARK: - Sync Queue Repository

@MainActor
final class SyncQueueRepository: SyncQueueRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchPendingItems() throws -> [SDSyncQueueItem] {
        let now  = Date.now
        let descriptor = FetchDescriptor<SDSyncQueueItem>(
            predicate: #Predicate {
                $0.isFailed   == false &&
                $0.nextRetryAt <= now
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    nonisolated func fetchPendingItems() async throws -> [SDSyncQueueItem] {
        try await MainActor.run { try self.fetchPendingItems() }
    }

    func enqueue(_ item: SDSyncQueueItem) throws {
        context.insert(item)
        try context.save()
    }

    nonisolated func enqueue(_ item: SDSyncQueueItem) async throws {
        try await MainActor.run { try self.enqueue(item) }
    }

    func dequeue(id: String) throws {
        let descriptor = FetchDescriptor<SDSyncQueueItem>(
            predicate: #Predicate { $0.id == id }
        )
        guard let item = try context.fetch(descriptor).first else { return }
        context.delete(item)
        try context.save()
    }

    nonisolated func dequeue(id: String) async throws {
        try await MainActor.run { try self.dequeue(id: id) }
    }

    func recordFailure(id: String, error: String) throws {
        let descriptor = FetchDescriptor<SDSyncQueueItem>(
            predicate: #Predicate { $0.id == id }
        )
        guard let item = try context.fetch(descriptor).first else { return }
        item.attemptCount += 1
        item.lastError     = error
        let delay          = pow(4.0, Double(item.attemptCount))
        item.nextRetryAt   = Date.now.addingTimeInterval(delay)
        if item.attemptCount >= item.maxAttempts { item.isFailed = true }
        try context.save()
    }

    nonisolated func recordFailure(id: String, error: String) async throws {
        try await MainActor.run { try self.recordFailure(id: id, error: error) }
    }
}
