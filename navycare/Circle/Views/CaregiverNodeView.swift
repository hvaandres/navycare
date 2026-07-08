// CaregiverNodeView.swift
// navycare — Circle Feature
//
// A single caregiver avatar in the orbit — liquid glass, spring tap,
// online indicator, and context menu for quick actions.

import SwiftUI

// MARK: - Constants

private enum CaregiverNodeLayout {
    static let size: CGFloat = 72
}

// MARK: - Gradient Palette

private let avatarPalette: [[Color]] = [
    [.blue,   .indigo ],
    [.purple, .pink   ],
    [.teal,   .blue   ],
    [.orange, .red    ],
    [.green,  .teal   ]
]

// MARK: - View

/// A floating caregiver node in the orbital ring.
struct CaregiverNodeView: View {

    let caregiver:     Caregiver
    let onTap:         () -> Void
    let onRemove:      () -> Void

    @State private var isExpanded: Bool = false
    @State private var isPressed:  Bool = false

    private let size = CaregiverNodeLayout.size

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .center) {

                // Glass backing
                glassDisc

                // Avatar / Initials
                avatarContent
                    .frame(width: size - 8, height: size - 8)
                    .clipShape(Circle())

                // Online indicator
                if caregiver.isOnline {
                    onlineDot
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(isExpanded ? 1.14 : (isPressed ? 0.90 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.62), value: isExpanded)
            .animation(.spring(response: 0.22, dampingFraction: 0.70), value: isPressed)
        }
        .buttonStyle(.plain)
        // Press state tracking
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true  }
                .onEnded   { _ in isPressed = false }
        )
        // Pending status badge floating below
        .overlay(alignment: .bottom) {
            if let status = caregiver.invitationStatus, status == .pending {
                InvitationStatusBadge(status: status)
                    .offset(y: 22)
            }
        }
        // Context menu for quick actions
        .contextMenu {
            Button { onTap() } label: {
                Label("View Details", systemImage: "person.circle")
            }
            Divider()
            Button(role: .destructive) { onRemove() } label: {
                Label("Remove from Circle", systemImage: "minus.circle.fill")
            }
        }
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: isExpanded)
        // Accessibility
        .accessibilityLabel("\(caregiver.name), \(caregiver.relationship)")
        .accessibilityValue(caregiver.isOnline ? "Online" : "Offline")
        .accessibilityHint("Double tap for details. Long press for options.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    private var glassDisc: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.18), .clear],
                            center: .init(x: 0.35, y: 0.2),
                            startRadius: 0,
                            endRadius: size * 0.65
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.65),
                                .white.opacity(0.05),
                                .clear,
                                .white.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 7)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let url = caregiver.profileImageURL {
            AsyncImage(url: url) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                initialsDisc
            }
        } else {
            initialsDisc
        }
    }

    private var initialsDisc: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: avatarPalette[caregiver.colorSeedIndex],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(caregiver.initials)
                .font(.system(size: size * 0.26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var onlineDot: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 11, height: 11)
            .overlay(Circle().stroke(.background, lineWidth: 2))
            .frame(width: size, height: size, alignment: .bottomTrailing)
            .padding(4)
    }

    // MARK: - Actions

    private func handleTap() {
        isExpanded = true
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            isExpanded = false
        }
        onTap()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        HStack(spacing: 20) {
            ForEach(Caregiver.mockData) { caregiver in
                CaregiverNodeView(
                    caregiver: caregiver,
                    onTap: {},
                    onRemove: {}
                )
            }
        }
    }
}
