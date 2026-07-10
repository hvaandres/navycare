// UploadFABView.swift
// navycare — Documents Feature
//
// Pulsing Electric Blue FAB that expands radially into 7 upload action buttons.
// Spring animation. Tap outside to collapse.

import SwiftUI

struct UploadFABView: View {
    @Binding var isExpanded: Bool
    let actions: [UploadAction]
    let onAction: (UploadAction) -> Void

    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fabSize: CGFloat    = 58
    private let orbitRadius: CGFloat = 96

    var body: some View {
        ZStack {
            // Dim overlay when expanded
            if isExpanded {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { collapse() }
                    .transition(.opacity)
            }

            ZStack(alignment: .center) {
                // Radial action buttons
                if isExpanded {
                    ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                        let rad    = action.angle * .pi / 180
                        let x      = orbitRadius * CGFloat(cos(rad))
                        let y      = orbitRadius * CGFloat(sin(rad))

                        actionButton(action: action, index: index)
                            .offset(x: x, y: y)
                    }
                }

                // Main FAB
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                        isExpanded.toggle()
                    }
                } label: {
                    ZStack {
                        // Pulse ring (idle only)
                        if !isExpanded && !reduceMotion {
                        Circle()
                            .stroke(Color.vaultBlue.opacity(0.35), lineWidth: 2)
                                .frame(width: fabSize + 14, height: fabSize + 14)
                                .scaleEffect(pulseScale)
                                .opacity(2.0 - pulseScale)
                        }

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.teal, Color.mint.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: fabSize, height: fabSize)
                            .shadow(color: .vaultBlue.opacity(0.55), radius: 16, x: 0, y: 8)

                        Image(systemName: isExpanded ? "xmark" : "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isExpanded)
                    }
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .medium), trigger: isExpanded)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseScale = 1.25
            }
        }
        .accessibilityLabel(isExpanded ? "Close upload menu" : "Upload document")
    }

    // MARK: - Action Button

    private func actionButton(action: UploadAction, index: Int) -> some View {
        Button {
            collapse()
            onAction(action)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.6))
                        .frame(width: 46, height: 46)

                    Image(systemName: action.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text(action.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isExpanded ? 1 : 0.2)
        .opacity(isExpanded ? 1 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.68)
                .delay(Double(index) * 0.04),
            value: isExpanded
        )
    }

    private func collapse() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isExpanded = false
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.vaultNavy.ignoresSafeArea()
        UploadFABView(
            isExpanded: .constant(true),
            actions: FilesViewModel().uploadActions,
            onAction: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
