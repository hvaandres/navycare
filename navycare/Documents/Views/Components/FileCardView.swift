// FileCardView.swift
// navycare — Documents Feature
//
// Glass document card with category strip, badges, and spring tap animation.
// Used in both grid and list layout modes.

import SwiftUI

// MARK: - File Card (Grid)

struct FileCardView: View {
    let document:    DocumentFile
    let onTap:       () -> Void
    let onFavorite:  () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: { onTap() }) {
            VStack(alignment: .leading, spacing: 0) {

                // Thumbnail area
                thumbnailArea
                    .frame(height: 100)
                    .clipped()

                // Info area
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(document.formattedSize)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer()
                        Text(document.relativeDate)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.40))
                    }

                    DocumentBadgeRow(document: document)
                }
                .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.22), .white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            // Category color left strip (visible in grid via top bar)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(document.category.color.opacity(0.75))
                    .frame(height: 3)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
            }
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true  }
                .onEnded   { _ in isPressed = false }
        )
        // Favorite button overlay
        .overlay(alignment: .topTrailing) {
            Button(action: onFavorite) {
                Image(systemName: document.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(document.isFavorite ? Color.vaultWarning : Color.white.opacity(0.4))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .accessibilityLabel(document.name)
        .accessibilityHint("Double tap to open. Category: \(document.category.displayName)")
    }

    // MARK: Thumbnail

    private var thumbnailArea: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    document.category.color.opacity(0.25),
                    document.category.color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Type icon
            Image(systemName: document.thumbnailSymbol)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(document.category.color.opacity(0.75))

            // Category tag overlay
            CategoryTagView(category: document.category, compact: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(8)
        }
        .cornerRadius(16, corners: [.topLeft, .topRight])
    }
}

// MARK: - File Row (List)

struct FileRowView: View {
    let document:   DocumentFile
    let onTap:      () -> Void
    let onFavorite: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(document.category.color.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: document.thumbnailSymbol)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(document.category.color)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(document.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        CategoryTagView(category: document.category, compact: true)
                        Text(document.formattedSize)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                        Text(document.relativeDate)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.40))
                    }
                }

                Spacer()

                // Badges
                VStack(alignment: .trailing, spacing: 4) {
                    if document.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.vaultWarning)
                    }
                    if document.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.vaultSuccess)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .vaultGlass(cornerRadius: 14, opacity: 0.07)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.70), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true  }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Document Grid View

struct DocumentGridView: View {
    let documents:  [DocumentFile]
    let layoutMode: DocumentLayoutMode
    let onTap:      (DocumentFile) -> Void
    let onFavorite: (DocumentFile) -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("\(documents.count) Document\(documents.count == 1 ? "" : "s")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 20)

            if documents.isEmpty {
                Text("No documents match your filter.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if layoutMode == .grid {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(documents) { doc in
                        FileCardView(
                            document:   doc,
                            onTap:      { onTap(doc) },
                            onFavorite: { onFavorite(doc) }
                        )
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: documents.count)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(documents) { doc in
                        FileRowView(
                            document:   doc,
                            onTap:      { onTap(doc) },
                            onFavorite: { onFavorite(doc) }
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: documents.count)
            }
        }
    }
}

// MARK: - Rounded Corner Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius:  CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vaultNavy.ignoresSafeArea()
        ScrollView {
            DocumentGridView(
                documents:  DocumentFile.mockData,
                layoutMode: .grid,
                onTap:      { _ in },
                onFavorite: { _ in }
            )
            .padding(.top, 20)
        }
    }
    .preferredColorScheme(.dark)
}
