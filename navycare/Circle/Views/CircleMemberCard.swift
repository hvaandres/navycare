// CircleMemberCard.swift
// navycare — Circle Feature
//
// A detailed bottom sheet for a single caregiver — avatar, info rows,
// permission level, and a destructive remove action.

import SwiftUI

private let avatarPalette: [[Color]] = [
    [.blue,   .indigo ],
    [.purple, .pink   ],
    [.teal,   .blue   ],
    [.orange, .red    ],
    [.green,  .teal   ]
]

/// Full-detail sheet for a Circle member.
struct CircleMemberCard: View {

    let caregiver: Caregiver
    let onRemove:  () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Avatar
                    avatarSection

                    // Name, relationship & badges
                    identitySection

                    // Info rows
                    infoSection

                    // Permission description
                    permissionSection

                    // Remove button
                    removeButton
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .navigationTitle("Circle Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: avatarPalette[caregiver.colorSeedIndex],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .overlay(Circle().stroke(.background.opacity(0.2), lineWidth: 2))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)

            Text(caregiver.initials)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var identitySection: some View {
        VStack(spacing: 8) {
            Text(caregiver.name)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text(caregiver.relationship)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                PermissionBadge(permission: caregiver.permission)
                if let status = caregiver.invitationStatus {
                    InvitationStatusBadge(status: status)
                }
            }
        }
    }

    private var infoSection: some View {
        VStack(spacing: 0) {
            if let phone = caregiver.invitation?.receiverPhone {
                infoRow(icon: "phone.fill",    label: "Phone",      value: phone)
                rowDivider
            }
            infoRow(icon: "person.fill",       label: "Role",       value: caregiver.relationship)
            rowDivider
            infoRow(
                icon:       "circle.fill",
                label:      "Status",
                value:      caregiver.isOnline ? "Online" : "Offline",
                valueColor: caregiver.isOnline ? .green : .secondary
            )
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12), lineWidth: 0.5))
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Access Level", systemImage: caregiver.permission.systemImage)
                .font(.subheadline.weight(.semibold))

            Text(caregiver.permission.accessDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12), lineWidth: 0.5))
    }

    private var removeButton: some View {
        Button(role: .destructive) {
            onRemove()
            dismiss()
        } label: {
            Label("Remove from Circle", systemImage: "minus.circle.fill")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.red.opacity(0.2), lineWidth: 0.5))
        }
        .foregroundStyle(.red)
        .accessibilityLabel("Remove \(caregiver.firstName) from the circle")
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 52)
    }

    private func infoRow(
        icon:       String,
        label:      String,
        value:      String,
        valueColor: Color = .primary
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)
                .padding(8)
                .background(.secondary.opacity(0.1), in: Circle())

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview {
    CircleMemberCard(
        caregiver: Caregiver.mockData[0],
        onRemove:  {}
    )
}
