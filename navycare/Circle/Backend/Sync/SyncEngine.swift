// SyncEngine.swift
// navycare — Circle Backend
//
// Swift Actor that owns the synchronization loop between SwiftData and Firestore.
// Runs off the main actor to avoid blocking the UI.
// Firestore SDK calls are wired in when Step 5 of the plan is implemented.

import Foundation
import BackgroundTasks

// MARK: - Sync Engine

/// Coordinates all SwiftData ↔ Firestore synchronization.
/// Using `actor` eliminates data races on queue access.
actor SyncEngine {

    // MARK: - Dependencies

    private let syncQueueRepo:     SyncQueueRepository
    private let conflictResolver:  ConflictResolver
    private let networkMonitor:    NetworkMonitor

    // MARK: - State

    private var isProcessing: Bool = false
    private var activeListeners: [String: Any] = [:] // circleId → ListenerRegistration

    // MARK: - Background task identifier

    static let bgTaskIdentifier = "com.navycare.sync"

    // MARK: - Init

    init(
        syncQueueRepo:    SyncQueueRepository,
        conflictResolver: ConflictResolver,
        networkMonitor:   NetworkMonitor
    ) {
        self.syncQueueRepo    = syncQueueRepo
        self.conflictResolver = conflictResolver
        self.networkMonitor   = networkMonitor
    }

    // MARK: - Public API

    /// Processes all pending sync queue items, with exponential-backoff retry.
    /// Called on app foreground, connectivity restore, and background task wakeup.
    func processSyncQueue() async {
        guard !isProcessing else { return }
        guard await networkMonitor.isConnected else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let items = try await syncQueueRepo.fetchPendingItems()
            for item in items {
                await processItem(item)
            }
        } catch {
            print("SyncEngine: fetchPendingItems failed — \(error.localizedDescription)")
        }
    }

    /// Schedules a `BGAppRefreshTask` to run sync in the background.
    nonisolated func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: SyncEngine.bgTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Registers the background task handler. Call from `navycareApp.init()`.
    nonisolated func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SyncEngine.bgTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self, let task = task as? BGAppRefreshTask else { return }
            self.handleBackgroundTask(task)
        }
    }

    // MARK: - Internal

    private func processItem(_ item: SDSyncQueueItem) async {
        do {
            // TODO (Step 5): Route to appropriate Firestore operation
            // switch item.operation {
            // case .create: try await FirestoreWriter.create(item)
            // case .update: try await FirestoreWriter.update(item)
            // case .delete: try await FirestoreWriter.delete(item)
            // }
            try await syncQueueRepo.dequeue(id: item.id)
        } catch {
            try? await syncQueueRepo.recordFailure(id: item.id, error: error.localizedDescription)
        }
    }

    private nonisolated func handleBackgroundTask(_ task: BGAppRefreshTask) {
        Task {
            await processSyncQueue()
            task.setTaskCompleted(success: true)
            scheduleBackgroundSync() // reschedule for next interval
        }
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
    }
}

// MARK: - Conflict Resolver

/// Pure-function conflict resolution. No mutable state.
struct ConflictResolver {

    /// Determines whether the local record should be pushed to Firestore
    /// or the remote record should overwrite local.
    ///
    /// Strategy: Last Write Wins based on `updatedAt`.
    /// Special cases:
    /// - Invitation status is append-only (accepted/declined/expired never revert to pending).
    /// - memberCount is always authoritative from Firestore.
    enum Resolution {
        case useLocal
        case useRemote
        case noConflict
    }

    func resolve(
        localUpdatedAt:  Date,
        remoteUpdatedAt: Date
    ) -> Resolution {
        if localUpdatedAt > remoteUpdatedAt  { return .useLocal  }
        if remoteUpdatedAt > localUpdatedAt  { return .useRemote }
        return .noConflict
    }

    /// Invitation status is append-only — only forward transitions are allowed.
    func resolveInvitationStatus(
        local:  InvitationStatusBE,
        remote: InvitationStatusBE
    ) -> InvitationStatusBE {
        // Priority order: expired > declined > accepted > pending
        let priority: [InvitationStatusBE: Int] = [
            .pending: 0, .accepted: 1, .declined: 2, .expired: 3
        ]
        let localPriority  = priority[local]  ?? 0
        let remotePriority = priority[remote] ?? 0
        return remotePriority >= localPriority ? remote : local
    }
}
