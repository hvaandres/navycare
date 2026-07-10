// FileDetailView.swift
// navycare — Documents Feature

import SwiftUI

struct FileDetailView: View {
    let document:   DocumentFile
    let onFavorite: () -> Void
    let onShare:    () -> Void
    let onDelete:   () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vaultNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Preview area
                        previewArea
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Meta info
                        metaSection
                            .padding(.horizontal, 20)

                        // Action buttons
                        actionGrid
                            .padding(.horizontal, 20)

                        // Sharing section
                        if document.isShared {
                            sharingSection
                                .padding(.horizontal, 20)
                        }

                        // Tags
                        if !document.tags.isEmpty {
                            tagsSection
                                .padding(.horizontal, 20)
                        }

                        // Delete
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Document", systemImage: "trash.fill")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.red.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onFavorite()
                    } label: {
                        Image(systemName: document.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(document.isFavorite ? .vaultWarning : .white.opacity(0.6))
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        ZStack {
            LinearGradient(
                colors: [
                    document.category.color.opacity(0.3),
                    document.category.color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image(systemName: document.thumbnailSymbol)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(document.category.color.opacity(0.8))

                EncryptedBadgeView()
            }
        }
    }

    // MARK: - Meta

    private var metaSection: some View {
        VStack(spacing: 0) {
            metaRow(icon: "calendar",        label: "Uploaded",  value: document.relativeDate)
            Divider().background(.white.opacity(0.08))
            metaRow(icon: "doc.fill",        label: "Type",      value: document.fileType.label)
            Divider().background(.white.opacity(0.08))
            metaRow(icon: "internaldrive",   label: "Size",      value: document.formattedSize)
            Divider().background(.white.opacity(0.08))
            metaRow(icon: document.category.systemImage, label: "Category", value: document.category.displayName)
        }
        .vaultGlass(cornerRadius: 16, opacity: 0.08)
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)
                .padding(8)
                .background(.white.opacity(0.07), in: Circle())
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Action Grid

    private var actionGrid: some View {
        let actions: [(String, String, Color)] = [
            ("Share",      "square.and.arrow.up", .vaultBlue),
            ("Download",   "arrow.down.circle",   .vaultCyan),
            ("Annotate",   "pencil.and.scribble", .vaultWarning),
            ("Print",      "printer.fill",         .white.opacity(0.5)),
        ]

        return HStack(spacing: 12) {
            ForEach(actions, id: \.0) { label, icon, color in
                Button {
                    if label == "Share" { onShare() }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(color)
                            .frame(width: 44, height: 44)
                            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        Text(label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Sharing

    private var sharingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared with \(document.sharedCount) people")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: -8) {
                ForEach(DocumentShare.mockShares.prefix(3)) { share in
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#2563EB").opacity(0.8))
                            .frame(width: 34, height: 34)
                        Text(share.contactInitials)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .overlay(Circle().stroke(.vaultNavy, lineWidth: 2))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .vaultGlass(cornerRadius: 16, opacity: 0.08)
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))

            FlowLayout(spacing: 6) {
                ForEach(document.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.vaultCyan.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.vaultCyan.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(.vaultCyan.opacity(0.2), lineWidth: 0.5))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .vaultGlass(cornerRadius: 16, opacity: 0.08)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: frame.minX + bounds.minX, y: frame.minY + bounds.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0; y += rowHeight + spacing; rowHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    FileDetailView(
        document:   DocumentFile.mockData[0],
        onFavorite: {},
        onShare:    {},
        onDelete:   {}
    )
}
