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

    func fetchCircle(for lovedOneUID: String) async throws -> SDCircle? {
        let descriptor = FetchDescriptor<SDCircle>(
            predicate: #Predicate { $0.lovedOneUID == lovedOneUID }
        )
        return try context.fetch(descriptor).first
    }

    func fetchMembers(circleId: String) async throws -> [SDCircleMember] {
        let descriptor = FetchDescriptor<SDCircleMember>(
            predicate: #Predicate { $0.circleId == circleId },
            sortBy: [SortDescriptor(\.joinedAt)]
        )
        return try context.fetch(descriptor)
    }

    func saveCircle(_ circle: SDCircle) async throws {
        context.insert(circle)
        try context.save()
    }

    func removeMember(id: String) async throws {
        let descriptor = FetchDescriptor<SDCircleMember>(
            predicate: #Predicate { $0.id == id }
        )
        guard let member = try context.fetch(descriptor).first else { return }
        context.delete(member)
        try context.save()
    }

    func updateMemberCount(circleId: String, count: Int) async throws {
        let descriptor = FetchDescriptor<SDCircle>(
            predicate: #Predicate { $0.id == circleId }
        )
        guard let circle = try context.fetch(descriptor).first else { return }
        circle.memberCount = count
        circle.updatedAt   = .now
        circle.syncStatus  = .synced
        try context.save()
    }
}

// MARK: - Invitation Repository

@MainActor
final class InvitationRepository: InvitationRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchInvitations(senderUID: String) async throws -> [SDInvitation] {
        let descriptor = FetchDescriptor<SDInvitation>(
            predicate: #Predicate { $0.senderUID == senderUID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchPendingInvitation(phone: String, circleId: String) async throws -> SDInvitation? {
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

    func saveInvitation(_ invitation: SDInvitation) async throws {
        context.insert(invitation)
        try context.save()
    }

    func updateInvitationStatus(id: String, status: InvitationStatusBE, acceptedByUID: String?) async throws {
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
}

// MARK: - User Repository

@MainActor
final class UserRepository: UserRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchCurrentUser(uid: String) async throws -> SDUserProfile? {
        let descriptor = FetchDescriptor<SDUserProfile>(
            predicate: #Predicate { $0.uid == uid }
        )
        return try context.fetch(descriptor).first
    }

    func saveUser(_ profile: SDUserProfile) async throws {
        context.insert(profile)
        try context.save()
    }

    func updateFCMToken(uid: String, token: String) async throws {
        guard let profile = try await fetchCurrentUser(uid: uid) else { return }
        profile.fcmToken   = token
        profile.updatedAt  = .now
        profile.syncStatus = .pendingUpdate
        try context.save()
    }

    func updateRole(uid: String, role: UserRole) async throws {
        guard let profile = try await fetchCurrentUser(uid: uid) else { return }
        profile.role       = role
        profile.updatedAt  = .now
        profile.syncStatus = .pendingUpdate
        try context.save()
    }
}

// MARK: - Sync Queue Repository

@MainActor
final class SyncQueueRepository: SyncQueueRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchPendingItems() async throws -> [SDSyncQueueItem] {
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

    func enqueue(_ item: SDSyncQueueItem) async throws {
        context.insert(item)
        try context.save()
    }

    func dequeue(id: String) async throws {
        let descriptor = FetchDescriptor<SDSyncQueueItem>(
            predicate: #Predicate { $0.id == id }
        )
        guard let item = try context.fetch(descriptor).first else { return }
        context.delete(item)
        try context.save()
    }

    func recordFailure(id: String, error: String) async throws {
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
}
