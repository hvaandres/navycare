// PlaceholderNodeView.swift
// navycare — Circle Feature
//
// An empty orbit slot. Gently breathes to invite the user to add a caregiver.

import SwiftUI

private let placeholderSize: CGFloat = 64

/// A glass placeholder shown in unoccupied orbit positions.
struct PlaceholderNodeView: View {

    let onTap: () -> Void

    @State private var breatheScale: CGFloat = 1.0
    @State private var isPressed:    Bool    = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack {

                // Outer breathing ring
                Circle()
                    .stroke(
                        Color.primary.opacity(0.12),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .scaleEffect(breatheScale)

                // Glass disc
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.14), .clear],
                                    center: .init(x: 0.35, y: 0.25),
                                    startRadius: 0,
                                    endRadius: placeholderSize * 0.6
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 5)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.primary.opacity(0.4))
            }
            .frame(width: placeholderSize, height: placeholderSize)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.88 : 1.0)
        .animation(.spring(response: 0.26, dampingFraction: 0.65), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true  }
                .onEnded   { _ in isPressed = false }
        )
        .sensoryFeedback(.selection, trigger: isPressed)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 2.4)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0 ... 0.8))
            ) {
                breatheScale = 1.06
            }
        }
        .accessibilityLabel("Add caregiver")
        .accessibilityHint("Double tap to invite someone to the care circle")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        HStack(spacing: 24) {
            PlaceholderNodeView(onTap: {})
            PlaceholderNodeView(onTap: {})
        }
    }
}
