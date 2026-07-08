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

/// Full-detail sheet for a Circle member, with inline editing for relationship and access level.
struct CircleMemberCard: View {

    let caregiver: Caregiver
    let onSave:    (Caregiver) -> Void
    let onRemove:  () -> Void

    // Editable copies of mutable fields
    @State private var editedRelationship: String
    @State private var editedPermission:   Permission
    @State private var isEditing:          Bool = false
    @State private var showRemoveAlert:    Bool = false

    @Environment(\.dismiss) private var dismiss

    init(caregiver: Caregiver, onSave: @escaping (Caregiver) -> Void, onRemove: @escaping () -> Void) {
        self.caregiver = caregiver
        self.onSave    = onSave
        self.onRemove  = onRemove
        _editedRelationship = State(initialValue: caregiver.relationship)
        _editedPermission   = State(initialValue: caregiver.permission)
    }

    private var hasChanges: Bool {
        editedRelationship != caregiver.relationship ||
        editedPermission   != caregiver.permission
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    avatarSection
                    identitySection
                    editSection
                    infoSection
                    removeButton
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .navigationTitle(isEditing ? "Edit Member" : "Circle Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            // revert
                            editedRelationship = caregiver.relationship
                            editedPermission   = caregiver.permission
                            isEditing = false
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") { saveChanges() }
                            .fontWeight(.semibold)
                            .disabled(!hasChanges)
                    } else {
                        Button("Edit") { isEditing = true }
                            .fontWeight(.medium)
                    }
                }
            }
            .alert("Remove \(caregiver.firstName)?" , isPresented: $showRemoveAlert) {
                Button("Remove", role: .destructive) {
                    onRemove()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(caregiver.firstName) will lose access to the care circle.")
            }
        }
    }

    // MARK: - Save

    private func saveChanges() {
        var updated = caregiver
        updated.relationship = editedRelationship.trimmingCharacters(in: .whitespaces)
        updated.permission   = editedPermission
        onSave(updated)
        isEditing = false
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

            Text(isEditing ? editedRelationship : caregiver.relationship)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                PermissionBadge(permission: isEditing ? editedPermission : caregiver.permission)
                if let status = caregiver.invitationStatus {
                    InvitationStatusBadge(status: status)
                }
            }
        }
    }

    /// Editable fields — shown always, locked when not editing.
    private var editSection: some View {
        VStack(spacing: 16) {

            // Relationship
            VStack(alignment: .leading, spacing: 6) {
                Label("Relationship", systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if isEditing {
                    TextField("e.g. Daughter, Doctor, Friend", text: $editedRelationship)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                        )
                        .submitLabel(.done)
                } else {
                    Text(caregiver.relationship)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.12), lineWidth: 0.5)
                        )
                }
            }

            // Access Level
            VStack(alignment: .leading, spacing: 6) {
                Label("Access Level", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if isEditing {
                    Picker("Access Level", selection: $editedPermission) {
                        ForEach(Permission.allCases, id: \.self) { perm in
                            Text(perm.displayName).tag(perm)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(editedPermission.accessDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                        .animation(.easeInOut(duration: 0.2), value: editedPermission)
                } else {
                    HStack {
                        PermissionBadge(permission: caregiver.permission)
                        Spacer()
                        Text(caregiver.permission.accessDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEditing ? Color.accentColor.opacity(0.3) : .white.opacity(0.12), lineWidth: 0.5)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isEditing)
    }

    private var infoSection: some View {
        VStack(spacing: 0) {
            if let phone = caregiver.invitation?.receiverPhone {
                infoRow(icon: "phone.fill", label: "Phone", value: phone)
                rowDivider
            }
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

    private var removeButton: some View {
        Button(role: .destructive) {
            showRemoveAlert = true
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
        onSave:    { _ in },
        onRemove:  {}
    )
}
