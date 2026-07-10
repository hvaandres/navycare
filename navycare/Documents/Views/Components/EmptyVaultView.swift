// EmptyVaultView.swift
// navycare — Documents Feature

import SwiftUI

// MARK: - Empty Vault

struct EmptyVaultView: View {
    let onUpload: () -> Void

    @State private var glowPulse = false
    @State private var appeared  = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Vault icon with glow rings
            ZStack {
                if !reduceMotion {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                Color.vaultBlue.opacity(glowPulse ? 0.0 : (0.18 - Double(i) * 0.05)),
                                lineWidth: 1.2
                            )
                            .frame(width: CGFloat(90 + i * 28), height: CGFloat(90 + i * 28))
                            .scaleEffect(glowPulse ? 1.12 + Double(i) * 0.04 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.2 + Double(i) * 0.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: glowPulse
                            )
                    }
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.vaultBlue.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "lock.doc.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.vaultBlue, .vaultCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .vaultBlue.opacity(0.6), radius: 16)
            }
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)

            // Copy
            VStack(spacing: 10) {
                Text("Your Secure Digital Archive")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Start building your secure digital archive.\nEvery important document, protected and always within reach.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)

            // CTA
            Button(action: onUpload) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Upload First Document")
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
                .shadow(color: .vaultBlue.opacity(0.5), radius: 14, x: 0, y: 8)
                .padding(.horizontal, 40)
            }
            .buttonStyle(.plain)
            .offset(y: appeared ? 0 : 16)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
            glowPulse = true
        }
    }
}

// MARK: - Smart Suggestions View

struct SmartSuggestionsView: View {
    let suggestions: [AISuggestion]
    let onDismiss:   (AISuggestion) -> Void

    var body: some View {
        if suggestions.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("AI Insights", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vaultCyan)
                    Spacer()
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(suggestions) { suggestion in
                            suggestionChip(suggestion)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func suggestionChip(_ suggestion: AISuggestion) -> some View {
        HStack(spacing: 7) {
            Image(systemName: suggestion.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: suggestion.color))

            Text(suggestion.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    onDismiss(suggestion)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color(hex: suggestion.color).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: suggestion.color).opacity(0.25), lineWidth: 0.5)
        )
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview("Empty Vault") {
    ZStack {
        AnimatedVaultBackground()
        EmptyVaultView(onUpload: {})
    }
    .preferredColorScheme(.dark)
}
