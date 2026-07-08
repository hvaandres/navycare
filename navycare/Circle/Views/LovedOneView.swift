// LovedOneView.swift
// navycare — Circle Feature
//
// The dominant center node — renders the Loved One with liquid glass,
// a pulsing online glow, and smooth touch feedback.

import SwiftUI

// MARK: - Constants

private enum LovedOneLayout {
    static let nodeSize: CGFloat    = 124
    static let glowRings: Int       = 3
    static let glowSpacing: CGFloat = 18
}

// MARK: - View

/// The center of the care circle. Always visually dominant.
struct LovedOneView: View {

    let lovedOne: LovedOne
    let onTap: () -> Void

    @State private var glowPulse: Bool  = false
    @State private var isPressed: Bool  = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size = LovedOneLayout.nodeSize

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Animated online glow rings
                if lovedOne.isOnline && !reduceMotion {
                    glowRings
                }

                // Liquid Glass disc
                glassDisc

                // Avatar / Initials
                avatarContent
                    .frame(width: size - 12, height: size - 12)
                    .clipShape(Circle())

                // Online indicator dot
                if lovedOne.isOnline {
                    onlineDot
                }
            }
            .frame(width: size + CGFloat(LovedOneLayout.glowRings) * LovedOneLayout.glowSpacing,
                   height: size + CGFloat(LovedOneLayout.glowRings) * LovedOneLayout.glowSpacing)
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true  }
                .onEnded   { _ in isPressed = false }
        )
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: isPressed)
        .onAppear(perform: startGlowAnimation)
        // Accessibility
        .accessibilityLabel(lovedOne.name)
        .accessibilityValue(lovedOne.status)
        .accessibilityHint("Double tap to view \(lovedOne.firstName)'s profile")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    private var glowRings: some View {
        ForEach(0 ..< LovedOneLayout.glowRings, id: \.self) { i in
            Circle()
                .stroke(
                    Color.mint.opacity(glowPulse ? 0.0 : max(0, 0.28 - Double(i) * 0.07)),
                    lineWidth: 1.5
                )
                .frame(
                    width:  size + CGFloat(i + 1) * LovedOneLayout.glowSpacing,
                    height: size + CGFloat(i + 1) * LovedOneLayout.glowSpacing
                )
                .scaleEffect(glowPulse ? 1.08 + Double(i) * 0.03 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0 + Double(i) * 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                    value: glowPulse
                )
        }
    }

    private var glassDisc: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                // Inner highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.22), .clear],
                            center: .init(x: 0.3, y: 0.2),
                            startRadius: 0,
                            endRadius: size * 0.7
                        )
                    )
            )
            .overlay(
                // Rim light
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.75),
                                .white.opacity(0.08),
                                .white.opacity(0.0),
                                .white.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let url = lovedOne.profileImageURL {
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
                        colors: [.mint, .teal, .cyan.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(lovedOne.initials)
                .font(.system(size: size * 0.27, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var onlineDot: some View {
        Circle()
            .fill(Color.mint)
            .frame(width: 15, height: 15)
            .overlay(Circle().stroke(.background, lineWidth: 2.5))
            .frame(width: size, height: size, alignment: .bottomTrailing)
            .padding(8)
    }

    // MARK: - Helpers

    private func startGlowAnimation() {
        guard lovedOne.isOnline && !reduceMotion else { return }
        glowPulse = true
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        LovedOneView(lovedOne: .mock, onTap: {})
    }
}
