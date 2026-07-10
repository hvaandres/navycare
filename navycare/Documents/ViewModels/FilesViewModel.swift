// FilesViewModel.swift
// navycare — Documents Feature

import Foundation
import Observation

// MARK: - Smart Card

struct SmartCard: Identifiable {
    let id      = UUID()
    let title:   String
    let metric:  String
    let icon:    String
    let color:   DocumentCategory?
    let accentHex: String
}

// MARK: - Upload Action

struct UploadAction: Identifiable {
    let id      = UUID()
    let label:   String
    let icon:    String
    let angle:   Double  // radial position in degrees
}

// MARK: - Files View Model

@MainActor
@Observable
final class FilesViewModel {

    // MARK: - State

    var documents:         [DocumentFile]     = DocumentFile.mockData
    var searchText:        String             = ""
    var isSearchActive:    Bool               = false
    var selectedCategory:  DocumentCategory?  = nil
    var layoutMode:        DocumentLayoutMode = .grid
    var selectedDocument:  DocumentFile?      = nil
    var showingDetail:     Bool               = false
    var showingShare:      Bool               = false
    var showingUploadMenu: Bool               = false
    var suggestions:       [AISuggestion]     = DocumentFile.mockSuggestions
    var isLoading:         Bool               = false

    // MARK: - Smart Cards

    var smartCards: [SmartCard] {[
        SmartCard(
            title: "Recent",
            metric: "\(recentCount)",
            icon: "clock.fill",
            color: nil,
            accentHex: "#2F80FF"
        ),
        SmartCard(
            title: "Shared Today",
            metric: "\(sharedTodayCount)",
            icon: "person.2.fill",
            color: nil,
            accentHex: "#4FD1FF"
        ),
        SmartCard(
            title: "Emergency",
            metric: "\(emergencyCount)",
            icon: "exclamationmark.shield.fill",
            color: .emergency,
            accentHex: "#DC2626"
        ),
        SmartCard(
            title: "Expiring Soon",
            metric: "1",
            icon: "timer",
            color: nil,
            accentHex: "#FBBF24"
        ),
        SmartCard(
            title: "Encrypted",
            metric: "\(encryptedCount)",
            icon: "lock.fill",
            color: nil,
            accentHex: "#34D399"
        ),
    ]}

    // MARK: - Upload Actions

    let uploadActions: [UploadAction] = [
        UploadAction(label: "Scan",    icon: "camera.viewfinder",    angle: 270),
        UploadAction(label: "Camera",  icon: "camera.fill",          angle: 315),
        UploadAction(label: "Photos",  icon: "photo.on.rectangle",   angle: 0),
        UploadAction(label: "PDF",     icon: "doc.richtext.fill",     angle: 45),
        UploadAction(label: "Files",   icon: "folder.fill",           angle: 90),
        UploadAction(label: "Audio",   icon: "waveform",              angle: 135),
        UploadAction(label: "iCloud",  icon: "icloud.fill",           angle: 180),
    ]

    // MARK: - Computed

    var filteredDocuments: [DocumentFile] {
        var result = documents

        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(query)
                || $0.tags.contains { $0.lowercased().contains(query) }
                || $0.category.displayName.lowercased().contains(query)
            }
        }

        return result
    }

    var isEmpty: Bool { documents.isEmpty }

    var totalStorageBytes: Int64 { documents.reduce(0) { $0 + $1.size } }

    var formattedStorage: String {
        let gb = Double(totalStorageBytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    /// 0.0 – 1.0 representing used / total (capped at 5 GB demo limit)
    var storageProgress: Double {
        min(Double(totalStorageBytes) / (5 * 1_073_741_824), 1.0)
    }

    private var recentCount: Int {
        documents.filter { $0.uploadedAt > .now.addingTimeInterval(-86400 * 7) }.count
    }

    private var sharedTodayCount: Int {
        documents.filter { $0.isShared && $0.uploadedAt > .now.addingTimeInterval(-86400) }.count
    }

    private var emergencyCount: Int {
        documents.filter { $0.category == .emergency }.count
    }

    private var encryptedCount: Int {
        documents.filter { $0.isEncrypted }.count
    }

    // MARK: - Actions

    func selectDocument(_ doc: DocumentFile) {
        selectedDocument = doc
        showingDetail    = true
    }

    func toggleFavorite(_ doc: DocumentFile) {
        guard let idx = documents.firstIndex(where: { $0.id == doc.id }) else { return }
        documents[idx].isFavorite.toggle()
    }

    func deleteDocument(_ doc: DocumentFile) {
        documents.removeAll { $0.id == doc.id }
    }

    func dismissSuggestion(_ suggestion: AISuggestion) {
        suggestions.removeAll { $0.id == suggestion.id }
    }
}
