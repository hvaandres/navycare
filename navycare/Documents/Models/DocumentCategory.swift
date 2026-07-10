// DocumentCategory.swift
// navycare — Documents Feature
//
// Each category owns a distinct color identity, icon, and display name.

import SwiftUI

enum DocumentCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case medical    = "medical"
    case finance    = "finance"
    case legal      = "legal"
    case emergency  = "emergency"
    case education  = "education"
    case insurance  = "insurance"
    case personal   = "personal"
    case family     = "family"
    case other      = "other"

    var id: String { rawValue }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .medical:   return "Medical"
        case .finance:   return "Finance"
        case .legal:     return "Legal"
        case .emergency: return "Emergency"
        case .education: return "Education"
        case .insurance: return "Insurance"
        case .personal:  return "Personal"
        case .family:    return "Family"
        case .other:     return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .medical:   return "cross.case.fill"
        case .finance:   return "banknote.fill"
        case .legal:     return "scale.3d"
        case .emergency: return "exclamationmark.shield.fill"
        case .education: return "graduationcap.fill"
        case .insurance: return "umbrella.fill"
        case .personal:  return "person.fill"
        case .family:    return "person.3.fill"
        case .other:     return "doc.fill"
        }
    }

    // MARK: - Color Identity

    var color: Color {
        switch self {
        case .medical:   return Color(hex: "#2563EB") // Sapphire Blue
        case .finance:   return Color(hex: "#059669") // Emerald Green
        case .legal:     return Color(hex: "#7C3AED") // Royal Purple
        case .emergency: return Color(hex: "#DC2626") // Crimson Red
        case .education: return Color(hex: "#4338CA") // Indigo
        case .insurance: return Color(hex: "#0891B2") // Cyan
        case .personal:  return Color(hex: "#EA580C") // Warm Orange
        case .family:    return Color(hex: "#8B5CF6") // Lavender
        case .other:     return Color(hex: "#6B7280") // Gray
        }
    }

    var gradientColors: [Color] {
        [color, color.opacity(0.6)]
    }
}
