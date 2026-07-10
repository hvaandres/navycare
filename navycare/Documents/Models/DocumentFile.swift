// DocumentFile.swift
// navycare — Documents Feature

import Foundation

// MARK: - File Type

enum FileType: String, Codable, Sendable {
    case pdf    = "pdf"
    case image  = "image"
    case video  = "video"
    case audio  = "audio"
    case doc    = "doc"
    case other  = "other"

    var systemImage: String {
        switch self {
        case .pdf:   return "doc.richtext.fill"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "waveform"
        case .doc:   return "doc.text.fill"
        case .other: return "doc.fill"
        }
    }

    var label: String {
        switch self {
        case .pdf:   return "PDF"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .doc:   return "Document"
        case .other: return "File"
        }
    }
}

// MARK: - Layout Mode

enum DocumentLayoutMode: String, CaseIterable {
    case grid     = "grid"
    case list     = "list"
    case timeline = "timeline"

    var systemImage: String {
        switch self {
        case .grid:     return "square.grid.2x2.fill"
        case .list:     return "list.bullet"
        case .timeline: return "timeline.selection"
        }
    }
}

// MARK: - AI Suggestion

struct AISuggestion: Identifiable, Sendable {
    let id      = UUID()
    let message: String
    let icon:    String
    let color:   String      // hex
    var isRead:  Bool = false
}

// MARK: - Document File

struct DocumentFile: Identifiable, Codable, Sendable {
    let id:          UUID
    var name:        String
    var category:    DocumentCategory
    var fileType:    FileType
    /// Bytes
    var size:        Int64
    var uploadedAt:  Date
    var modifiedAt:  Date
    var isFavorite:  Bool
    var isEncrypted: Bool
    var isOffline:   Bool
    var isVerified:  Bool
    var tags:        [String]
    var notes:       String?
    var sharedCount: Int
    /// SF Symbol name used as placeholder thumbnail
    var thumbnailSymbol: String

    // MARK: Computed

    var formattedSize: String {
        let bytes = Double(size)
        if bytes < 1_024               { return "\(size) B"                              }
        if bytes < 1_048_576           { return String(format: "%.1f KB", bytes / 1_024)        }
        if bytes < 1_073_741_824       { return String(format: "%.1f MB", bytes / 1_048_576)    }
        return String(format: "%.1f GB", bytes / 1_073_741_824)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: uploadedAt, relativeTo: .now)
    }

    var isShared: Bool { sharedCount > 0 }
}

// MARK: - Mock Data

extension DocumentFile {
    static let mockData: [DocumentFile] = [
        DocumentFile(
            id:              UUID(),
            name:            "Health Insurance Card",
            category:        .insurance,
            fileType:        .image,
            size:            1_240_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 2),
            modifiedAt:      .now.addingTimeInterval(-86400 * 1),
            isFavorite:      true,
            isEncrypted:     true,
            isOffline:       true,
            isVerified:      true,
            tags:            ["insurance", "health", "2026"],
            sharedCount:     2,
            thumbnailSymbol: "umbrella.fill"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "Birth Certificate",
            category:        .personal,
            fileType:        .pdf,
            size:            890_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 30),
            modifiedAt:      .now.addingTimeInterval(-86400 * 30),
            isFavorite:      true,
            isEncrypted:     true,
            isOffline:       false,
            isVerified:      true,
            tags:            ["identity", "official"],
            sharedCount:     0,
            thumbnailSymbol: "person.text.rectangle.fill"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "Medical Records — 2026",
            category:        .medical,
            fileType:        .pdf,
            size:            3_400_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 7),
            modifiedAt:      .now.addingTimeInterval(-86400 * 2),
            isFavorite:      false,
            isEncrypted:     true,
            isOffline:       true,
            isVerified:      false,
            tags:            ["medical", "records", "annual"],
            sharedCount:     1,
            thumbnailSymbol: "cross.case.fill"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "Last Will & Testament",
            category:        .legal,
            fileType:        .pdf,
            size:            560_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 180),
            modifiedAt:      .now.addingTimeInterval(-86400 * 180),
            isFavorite:      true,
            isEncrypted:     true,
            isOffline:       false,
            isVerified:      true,
            tags:            ["legal", "estate", "will"],
            sharedCount:     3,
            thumbnailSymbol: "scale.3d"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "Emergency Contacts",
            category:        .emergency,
            fileType:        .doc,
            size:            45_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 14),
            modifiedAt:      .now.addingTimeInterval(-86400 * 1),
            isFavorite:      true,
            isEncrypted:     true,
            isOffline:       true,
            isVerified:      true,
            tags:            ["emergency", "contacts", "urgent"],
            sharedCount:     5,
            thumbnailSymbol: "exclamationmark.shield.fill"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "Investment Portfolio Q2",
            category:        .finance,
            fileType:        .pdf,
            size:            2_100_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 5),
            modifiedAt:      .now.addingTimeInterval(-86400 * 5),
            isFavorite:      false,
            isEncrypted:     true,
            isOffline:       false,
            isVerified:      false,
            tags:            ["finance", "investments", "2026"],
            sharedCount:     1,
            thumbnailSymbol: "banknote.fill"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "School Diploma",
            category:        .education,
            fileType:        .image,
            size:            4_200_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 365),
            modifiedAt:      .now.addingTimeInterval(-86400 * 365),
            isFavorite:      false,
            isEncrypted:     true,
            isOffline:       false,
            isVerified:      true,
            tags:            ["education", "diploma", "official"],
            sharedCount:     0,
            thumbnailSymbol: "graduationcap.fill"
        ),
        DocumentFile(
            id:              UUID(),
            name:            "Family Photos — Summer",
            category:        .family,
            fileType:        .image,
            size:            18_900_000,
            uploadedAt:      .now.addingTimeInterval(-86400 * 3),
            modifiedAt:      .now.addingTimeInterval(-86400 * 3),
            isFavorite:      true,
            isEncrypted:     false,
            isOffline:       true,
            isVerified:      false,
            tags:            ["family", "photos", "summer"],
            sharedCount:     4,
            thumbnailSymbol: "person.3.fill"
        )
    ]

    static let mockSuggestions: [AISuggestion] = [
        AISuggestion(message: "Passport expires in 3 months",          icon: "exclamationmark.triangle.fill",   color: "#FBBF24"),
        AISuggestion(message: "Insurance card detected in Medical",    icon: "sparkles",                        color: "#2F80FF"),
        AISuggestion(message: "Duplicate document found",              icon: "doc.on.doc.fill",                 color: "#FF6B6B"),
        AISuggestion(message: "Add back of insurance card",            icon: "plus.circle.fill",                color: "#4FD1FF"),
        AISuggestion(message: "Share Emergency Contacts with spouse",  icon: "person.2.fill",                   color: "#34D399"),
    ]
}
