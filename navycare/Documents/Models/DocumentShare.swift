// DocumentShare.swift
// navycare — Documents Feature

import Foundation

enum SharePermission: String, Codable, Sendable, CaseIterable {
    case readOnly      = "read_only"
    case editable      = "editable"
    case temporary     = "temporary"
    case emergency     = "emergency"

    var displayName: String {
        switch self {
        case .readOnly:  return "View Only"
        case .editable:  return "Can Edit"
        case .temporary: return "Temporary"
        case .emergency: return "Emergency"
        }
    }

    var systemImage: String {
        switch self {
        case .readOnly:  return "eye.fill"
        case .editable:  return "pencil"
        case .temporary: return "clock.fill"
        case .emergency: return "exclamationmark.shield.fill"
        }
    }
}

struct DocumentShare: Identifiable, Codable, Sendable {
    let id:         UUID
    let contactName: String
    let contactInitials: String
    let permission:  SharePermission
    let sharedAt:    Date
    var expiresAt:   Date?
    var lastViewed:  Date?
    var hasDownloaded: Bool
}

extension DocumentShare {
    static let mockShares: [DocumentShare] = [
        DocumentShare(
            id:              UUID(),
            contactName:     "Sarah Johnson",
            contactInitials: "SJ",
            permission:      .readOnly,
            sharedAt:        .now.addingTimeInterval(-86400 * 3),
            expiresAt:       nil,
            lastViewed:      .now.addingTimeInterval(-3600),
            hasDownloaded:   false
        ),
        DocumentShare(
            id:              UUID(),
            contactName:     "Dr. Emily Chen",
            contactInitials: "EC",
            permission:      .readOnly,
            sharedAt:        .now.addingTimeInterval(-86400),
            expiresAt:       .now.addingTimeInterval(86400 * 30),
            lastViewed:      nil,
            hasDownloaded:   false
        ),
    ]
}
