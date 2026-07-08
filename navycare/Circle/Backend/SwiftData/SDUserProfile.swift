// SDUserProfile.swift
// navycare — Circle Backend
//
// Persistent local user profile. Written by the app after first sign-in.
// Firestore /users/{uid} is created by the onUserCreated Cloud Function —
// the client never writes the Firestore document directly.

import Foundation
import SwiftData

@Model
final class SDUserProfile {

    // MARK: - Identity

    @Attribute(.unique) var uid: String
    var firstName: String
    var lastName: String
    var email: String
    /// E.164 format, verified via Firebase Phone Auth OTP.
    var phoneNumber: String
    var dateOfBirth: Date

    // MARK: - Role

    /// Raw string backing for `UserRole` enum.
    var roleRaw: String

    // MARK: - Push

    /// The active FCM device token for this installation.
    var fcmToken: String?

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Sync

    /// Raw string backing for `SyncStatus` enum.
    var syncStatusRaw: String

    // MARK: - Init

    init(
        uid:           String,
        firstName:     String,
        lastName:      String,
        email:         String,
        phoneNumber:   String,
        dateOfBirth:   Date,
        role:          UserRole     = .lovedOne,
        fcmToken:      String?      = nil,
        createdAt:     Date         = .now,
        updatedAt:     Date         = .now,
        syncStatus:    SyncStatus   = .pendingCreate
    ) {
        self.uid           = uid
        self.firstName     = firstName
        self.lastName      = lastName
        self.email         = email
        self.phoneNumber   = phoneNumber
        self.dateOfBirth   = dateOfBirth
        self.roleRaw       = role.rawValue
        self.fcmToken      = fcmToken
        self.createdAt     = createdAt
        self.updatedAt     = updatedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}

// MARK: - Computed

extension SDUserProfile {

    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .lovedOne }
        set { roleRaw = newValue.rawValue; updatedAt = .now }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingCreate }
        set { syncStatusRaw = newValue.rawValue }
    }

    var fullName: String { "\(firstName) \(lastName)" }

    var initials: String {
        [firstName.first, lastName.first]
            .compactMap { $0 }
            .map(String.init)
            .joined()
            .uppercased()
    }
}
