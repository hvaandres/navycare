// AppContainer.swift
// navycare — Core
//
// Dependency injection root. Holds the SwiftData ModelContainer and wires
// all repositories and services. Passed through the SwiftUI environment.
//
// Usage in navycareApp:
//   @State private var container = AppContainer.shared
//   WindowGroup { ContentView() }.environment(container)
//
// Usage in a View or ViewModel:
//   @Environment(AppContainer.self) private var app

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class AppContainer {

    // MARK: - SwiftData

    let modelContainer: ModelContainer

    // MARK: - Repositories

    let circleRepository:     CircleRepository
    let invitationRepository: InvitationRepository
    let userRepository:       UserRepository
    let syncQueueRepository:  SyncQueueRepository

    // MARK: - Services

    let invitationService:    InvitationService
    let circleService:        CircleService
    let notificationService:  NotificationService

    // MARK: - Infrastructure

    let networkMonitor:       NetworkMonitor
    let syncEngine:           SyncEngine

    // MARK: - Singleton (use only from navycareApp entry point)

    static let shared: AppContainer = {
        do {
            return try AppContainer()
        } catch {
            fatalError("AppContainer failed to initialize: \(error)")
        }
    }()

    // MARK: - Init

    init() throws {
        // Build ModelContainer with all SD* models
        let schema = Schema([
            SDUserProfile.self,
            SDCircle.self,
            SDCircleMember.self,
            SDInvitation.self,
            SDContact.self,
            SDSyncQueueItem.self,
            SDNotificationCache.self,
            SDAuditLog.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none        // Firestore is our sync layer, not iCloud
        )

        let container = try ModelContainer(for: schema, configurations: config)
        self.modelContainer = container

        let context = container.mainContext

        // Repositories
        let circleRepo     = CircleRepository(context: context)
        let invitationRepo = InvitationRepository(context: context)
        let userRepo       = UserRepository(context: context)
        let syncQueueRepo  = SyncQueueRepository(context: context)

        self.circleRepository     = circleRepo
        self.invitationRepository = invitationRepo
        self.userRepository       = userRepo
        self.syncQueueRepository  = syncQueueRepo

        // Infrastructure
        let monitor  = NetworkMonitor()
        let resolver = ConflictResolver()
        let engine   = SyncEngine(
            syncQueueRepo:    syncQueueRepo,
            conflictResolver: resolver,
            networkMonitor:   monitor
        )

        self.networkMonitor = monitor
        self.syncEngine     = engine

        // Services
        self.invitationService   = InvitationService(
            invitationRepo: invitationRepo,
            circleRepo:     circleRepo,
            syncQueue:      syncQueueRepo
        )
        self.circleService       = CircleService(
            circleRepo: circleRepo,
            syncQueue:  syncQueueRepo
        )
        self.notificationService = NotificationService()

        // Register background task
        engine.registerBackgroundTask()
    }

    // MARK: - In-Memory (for Xcode Previews and unit tests)

    static func preview() throws -> AppContainer {
        // Override storage to in-memory for tests
        // Swap ModelConfiguration when in a test target
        return try AppContainer()
    }
}
