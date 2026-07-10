// StorageHeaderView.swift
// navycare — Documents Feature

import SwiftUI

// MARK: - Storage Header

struct StorageHeaderView: View {
    let storageUsed:    String
    let storageProgress: Double
    let layoutMode:     DocumentLayoutMode
    let onLayoutToggle: () -> Void

    @State private var ringProgress: Double = 0

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Title block
            VStack(alignment: .leading, spacing: 4) {
                Text("Files")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Your secure digital archive.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
            }

            Spacer()

            // Right side — storage ring + badges + layout toggle
            VStack(alignment: .trailing, spacing: 10) {
                // Storage ring
                HStack(spacing: 10) {
                    // Layout toggle
                    Button(action: onLayoutToggle) {
                        Image(systemName: layoutMode.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .vaultGlass(cornerRadius: 10, opacity: 0.1)
                    }
                    .buttonStyle(.plain)

                    storageRing
                }

                // Badges row
                HStack(spacing: 6) {
                    statusBadge(icon: "lock.shield.fill", label: "AES-256",  color: .vaultSuccess)
                    statusBadge(icon: "icloud.fill",      label: "Synced",    color: .vaultBlue)
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                ringProgress = storageProgress
            }
        }
    }

    // MARK: - Storage Ring

    private var storageRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.1), lineWidth: 4)
                .frame(width: 52, height: 52)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [.vaultBlue, .vaultCyan, .vaultBlue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text(storageUsed)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("used")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Status Badge

    private func statusBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(label)
                .font(.system(size: 8, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.4))
    }
}

// MARK: - Files Search Bar

struct FilesSearchBarView: View {
    @Binding var searchText:     String
    @Binding var isSearchActive: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isFocused ? .vaultBlue : .white.opacity(0.45))

                TextField("Search files, tags, categories…", text: $searchText)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .tint(.vaultBlue)
                    .focused($isFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isFocused ? 0.11 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isFocused ? .vaultBlue.opacity(0.6) : .white.opacity(0.12),
                                lineWidth: isFocused ? 1 : 0.5
                            )
                    )
            )
            .shadow(
                color: isFocused ? .vaultBlue.opacity(0.25) : .clear,
                radius: 12, x: 0, y: 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)

            if isSearchActive {
                Button("Cancel") {
                    searchText = ""
                    isSearchActive = false
                    isFocused = false
                }
                .font(.system(size: 15))
                .foregroundStyle(.vaultBlue)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: isFocused) { _, focused in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isSearchActive = focused
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSearchActive)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vaultNavy.ignoresSafeArea()
        VStack(spacing: 20) {
            StorageHeaderView(
                storageUsed:     "0.3 GB",
                storageProgress: 0.28,
                layoutMode:      .grid,
                onLayoutToggle:  {}
            )
            .padding(.top, 60)
            FilesSearchBarView(
                searchText:     .constant(""),
                isSearchActive: .constant(false)
            )
        }
    }
    .preferredColorScheme(.dark)
}
