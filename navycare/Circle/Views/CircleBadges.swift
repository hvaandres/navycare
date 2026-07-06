// CircleBadges.swift
// navycare — Circle Feature
//
// Compact, glass-styled status and permission badges.

import SwiftUI

// MARK: - Invitation Status Badge

/// A pill badge communicating the lifecycle state of a Circle invitation.
struct InvitationStatusBadge: View {
    let status: InvitationStatus

    private var tint: Color {
        switch status {
        case .pending:  return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired:  return .secondary
        }
    }

    var body: some View {
        Label(status.displayName, systemImage: status.systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Permission Badge

/// Displays a caregiver's access level as a glass-styled badge.
struct PermissionBadge: View {
    let permission: Permission
    /// When `true`, renders as an icon-only circle instead of a full pill.
    var compact: Bool = false

    private var tint: Color {
        switch permission {
        case .admin:     return .purple
        case .caregiver: return .blue
        case .viewer:    return .secondary
        }
    }

    var body: some View {
        if compact {
            Image(systemName: permission.systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .padding(6)
                .background(tint.opacity(0.15), in: Circle())
                .accessibilityLabel(permission.displayName)
        } else {
            Label(permission.displayName, systemImage: permission.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(tint.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 0.5))
                .accessibilityLabel("\(permission.displayName) access")
        }
    }
}

// MARK: - Previews

#Preview("Invitation Status Badges") {
    VStack(spacing: 10) {
        ForEach(InvitationStatus.allCases, id: \.self) {
            InvitationStatusBadge(status: $0)
        }
    }
    .padding()
}

#Preview("Permission Badges") {
    VStack(spacing: 12) {
        ForEach(Permission.allCases, id: \.self) { perm in
            HStack(spacing: 12) {
                PermissionBadge(permission: perm)
                PermissionBadge(permission: perm, compact: true)
            }
        }
    }
    .padding()
}
