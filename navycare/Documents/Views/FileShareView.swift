// FileShareView.swift
// navycare — Documents Feature

import SwiftUI

struct FileShareView: View {
    let document: DocumentFile

    @State private var selectedPermission: SharePermission = .readOnly
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Document card
                        documentCard
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Permission picker
                        permissionSection
                            .padding(.horizontal, 20)

                        // Current access
                        currentAccessSection
                            .padding(.horizontal, 20)

                        // Share button
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Share with Circle Members")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.vaultBlue, Color(hex: "#1A6AFF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .shadow(color: .vaultBlue.opacity(0.45), radius: 14, x: 0, y: 7)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Share Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Document Card

    private var documentCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(document.category.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: document.thumbnailSymbol)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(document.category.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(document.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    CategoryTagView(category: document.category, compact: false)
                    Text(document.formattedSize)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            Spacer()
        }
        .padding(14)
        .vaultGlass(cornerRadius: 16, opacity: 0.09)
    }

    // MARK: - Permission Picker

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Access Level")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 0) {
                ForEach(SharePermission.allCases, id: \.self) { perm in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedPermission = perm
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: perm.systemImage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(selectedPermission == perm ? Color.vaultBlue : Color.white.opacity(0.5))
                                .frame(width: 20)

                            Text(perm.displayName)
                                .font(.subheadline.weight(selectedPermission == perm ? .semibold : .regular))
                                .foregroundStyle(.white)

                            Spacer()

                            if selectedPermission == perm {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.vaultBlue)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)

                    if perm != SharePermission.allCases.last {
                        Divider().background(.white.opacity(0.07))
                    }
                }
            }
            .vaultGlass(cornerRadius: 16, opacity: 0.08)
        }
    }

    // MARK: - Current Access

    private var currentAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently Shared With")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 0) {
                ForEach(DocumentShare.mockShares) { share in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.vaultBlue, Color(hex: "#1A6AFF")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                            Text(share.contactInitials)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(share.contactName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            Text(share.permission.displayName)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.45))
                        }

                        Spacer()

                        if share.lastViewed != nil {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.vaultCyan.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)

                    if share.id != DocumentShare.mockShares.last?.id {
                        Divider().background(.white.opacity(0.07))
                    }
                }
            }
            .vaultGlass(cornerRadius: 16, opacity: 0.08)
        }
    }
}

#Preview {
    FileShareView(document: DocumentFile.mockData[0])
}
