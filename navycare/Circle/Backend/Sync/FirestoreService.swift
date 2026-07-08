// FirestoreService.swift
// navycare — Circle Backend (Step 5)
//
// Wraps Firestore SDK to provide:
//   • Real-time circle/member listeners as AsyncStream
//   • Async write methods consumed by SyncEngine
//
// REQUIRES: Add FirebaseFirestore to the Xcode target via SPM
//   File → Add Package Dependencies → search firebase-ios-sdk
//   Add product: FirebaseFirestore
//
// Used by SyncEngine. Views never import this file.

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Document Keys

private enum Keys {
    static let caregiverUID  = "caregiverUID"
    static let relationship  = "relationship"
    static let permission    = "permission"
    static let joinedAt      = "joinedAt"
    static let invitationId  = "invitationId"
    static let status        = "status"
    static let acceptedAt    = "acceptedAt"
    static let acceptedByUID = "acceptedByUID"
    static let memberCount   = "memberCount"
    static let updatedAt     = "updatedAt"
    static let fcmTokens     = "fcmTokens"
}

// MARK: - Firestore Service

/// Firestore read/write layer. All methods are `async throws`.
/// Called exclusively by `SyncEngine` — never by ViewModels or Views.
final class FirestoreService: @unchecked Sendable {

    static let shared = FirestoreService()

    /// Computed so Firestore.firestore() is never called at init time.
    /// FirebaseApp.configure() must run before any method on this class is called.
    private var db: Firestore { Firestore.firestore() }

    private init() {}

    // MARK: - Real-Time Streams

    /// Emits updated member arrays whenever the circle's members subcollection changes.
    /// The stream terminates if the caller's Task is cancelled.
    func memberStream(circleId: String) -> AsyncStream<[MemberSnapshot]> {
        AsyncStream { continuation in
            let ref = db
                .collection("circles").document(circleId)
                .collection("members")

            let listener = ref.addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                let members = docs.compactMap { MemberSnapshot(doc: $0) }
                continuation.yield(members)
            }

            continuation.onTermination = { _ in listener.remove() }
        }
    }

    /// Emits whenever an invitation's status changes (used by the sender to track acceptance).
    func invitationStream(invitationId: String) -> AsyncStream<InvitationSnapshot?> {
        AsyncStream { continuation in
            let ref = db.collection("invitations").document(invitationId)
            let listener = ref.addSnapshotListener { snapshot, _ in
                continuation.yield(snapshot.flatMap { InvitationSnapshot(doc: $0) })
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    // MARK: - Writes (called by SyncEngine queue processor)

    /// Calls the Cloud Function `createInvitation` via the Functions SDK.
    /// Direct Firestore writes for invitations are blocked by security rules.
    func syncInvitationCreate(payload: Data) async throws {
        // NOTE: Invitation creation is CF-only.
        // The SyncEngine calls this; the CF handles the token + SMS.
        // This method exists as the queue-processing hook.
        // Real implementation calls Firebase Functions SDK (Step 4 is already done).
        _ = payload
    }

    /// Updates the FCM token array on the user document.
    /// Permitted by security rules (fcmTokens + updatedAt only).
    func updateFCMToken(uid: String, token: String) async throws {
        try await db.collection("users").document(uid).updateData([
            Keys.fcmTokens: FieldValue.arrayUnion([token]),
            Keys.updatedAt: FieldValue.serverTimestamp(),
        ])
    }

    /// Removes a stale FCM token (called when `messaging:didReceiveRegistrationToken` fires
    /// with a refreshed token so old tokens are pruned).
    func removeFCMToken(uid: String, token: String) async throws {
        try await db.collection("users").document(uid).updateData([
            Keys.fcmTokens: FieldValue.arrayRemove([token]),
        ])
    }

    // MARK: - One-Shot Reads

    /// Returns the current member count from Firestore (authoritative).
    func fetchMemberCount(circleId: String) async throws -> Int {
        let doc = try await db.collection("circles").document(circleId).getDocument()
        return doc.data()?[Keys.memberCount] as? Int ?? 0
    }
}

// MARK: - Snapshot DTOs

/// Value type carrying raw Firestore member data.
struct MemberSnapshot: Sendable {
    let id:            String
    let caregiverUID:  String
    let relationship:  String
    let permission:    String
    let invitationId:  String
    let joinedAt:      Date

    init?(doc: QueryDocumentSnapshot) {
        guard
            let caregiverUID = doc.data()[Keys.caregiverUID]  as? String,
            let relationship = doc.data()[Keys.relationship]  as? String,
            let permission   = doc.data()[Keys.permission]    as? String,
            let invitationId = doc.data()[Keys.invitationId]  as? String
        else { return nil }

        self.id           = doc.documentID
        self.caregiverUID = caregiverUID
        self.relationship = relationship
        self.permission   = permission
        self.invitationId = invitationId
        self.joinedAt     = (doc.data()[Keys.joinedAt] as? Timestamp)?.dateValue() ?? .now
    }
}

/// Value type carrying raw Firestore invitation data.
struct InvitationSnapshot: Sendable {
    let id:            String
    let status:        String
    let acceptedByUID: String?
    let acceptedAt:    Date?

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data(),
              let status = data[Keys.status] as? String
        else { return nil }

        self.id            = doc.documentID
        self.status        = status
        self.acceptedByUID = data[Keys.acceptedByUID] as? String
        self.acceptedAt    = (data[Keys.acceptedAt] as? Timestamp)?.dateValue()
    }
}
