// InviteCaregiverSheet.swift
// navycare — Circle Feature
//
// Liquid Glass bottom sheet for inviting a new caregiver.
// Wraps CNContactPickerViewController for native contact selection.

import SwiftUI
import Contacts
import ContactsUI

// MARK: - Sheet

/// Full invite flow: contact selection → form → async send.
struct InviteCaregiverSheet: View {

    let onCaregiverAdded: (Caregiver) -> Void

    @State private var viewModel = InviteCaregiverViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    contactSection
                    if viewModel.selectedContact != nil {
                        formSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer(minLength: 24)
                }
                .padding(20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedContact != nil)
            }
            .navigationTitle("Invite Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    sendButtonOrProgress
                }
            }
            .sheet(isPresented: $viewModel.showingContactPicker) {
                ContactPickerRepresentable(selectedContact: $viewModel.selectedContact)
                    .ignoresSafeArea()
            }
            .onChange(of: viewModel.hasSent) { _, sent in
                if sent { dismiss() }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 46))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Add to Circle")
                .font(.title2.weight(.bold))

            Text("Invite someone you trust to help support your loved one.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var contactSection: some View {
        if let contact = viewModel.selectedContact {
            selectedContactCard(contact)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
        } else {
            selectContactButton
        }
    }

    private var selectContactButton: some View {
        Button { viewModel.showingContactPicker = true } label: {
            HStack {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                Text("Select from Contacts")
                    .font(.body.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .glassCard(cornerRadius: 14)
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Select a contact to invite")
    }

    private func selectedContactCard(_ contact: CNContact) -> some View {
        HStack(spacing: 14) {
            initialsCircle(name: viewModel.receiverName, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.receiverName)
                    .font(.body.weight(.semibold))
                Text(viewModel.formattedPhone)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Change") { viewModel.showingContactPicker = true }
                .font(.subheadline)
                .foregroundStyle(.tint)
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private var formSection: some View {
        VStack(spacing: 18) {

            // Relationship
            formField(
                icon: "person.2.fill",
                label: "Relationship"
            ) {
                TextField("e.g. Daughter, Doctor, Friend", text: $viewModel.relationship)
                    .textFieldStyle(.plain)
                    .submitLabel(.next)
            }

            // Permission
            VStack(alignment: .leading, spacing: 8) {
                Label("Access Level", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Permission", selection: $viewModel.permission) {
                    ForEach(Permission.allCases, id: \.self) { perm in
                        Text(perm.displayName).tag(perm)
                    }
                }
                .pickerStyle(.segmented)

                Text(viewModel.permission.accessDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
            }

            // Message
            formField(
                icon: "message.fill",
                label: "Personal Message (optional)"
            ) {
                TextField(
                    "Add a personal note…",
                    text: $viewModel.personalMessage,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .lineLimit(3 ... 5)
            }
        }
    }

    @ViewBuilder
    private var sendButtonOrProgress: some View {
        if viewModel.isSending {
            ProgressView().scaleEffect(0.85)
        } else {
            Button("Send Invite") {
                Task {
                    if let caregiver = await viewModel.sendInvitation() {
                        onCaregiverAdded(caregiver)
                    }
                }
            }
            .fontWeight(.semibold)
            .disabled(!viewModel.canSend)
        }
    }

    // MARK: - Helpers

    private func initialsCircle(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(name.nameInitials)
                .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private func formField<Content: View>(
        icon:    String,
        label:   String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
                .padding(14)
                .glassCard(cornerRadius: 12)
        }
    }
}

// MARK: - Glass Card Modifier

private extension View {
    func glassCard(cornerRadius: CGFloat) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.14), lineWidth: 0.5)
            )
    }
}

// MARK: - String Extension

private extension String {
    var nameInitials: String {
        components(separatedBy: " ")
            .compactMap(\.first)
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

// MARK: - Contact Picker Representable

/// UIViewControllerRepresentable wrapper for CNContactPickerViewController.
struct ContactPickerRepresentable: UIViewControllerRepresentable {

    @Binding var selectedContact: CNContact?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    // MARK: Coordinator

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerRepresentable
        init(_ parent: ContactPickerRepresentable) { self.parent = parent }

        func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contact: CNContact
        ) {
            parent.selectedContact = contact
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    InviteCaregiverSheet(onCaregiverAdded: { _ in })
        .presentationDetents([.large])
}
