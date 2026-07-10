// VaultDesignSystem.swift
// navycare — Documents Feature
//
// Shared design tokens, Color extensions, and view modifiers
// for the secure document vault UI.

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // Background palette
    static let vaultNavy      = Color(hex: "#071A2D")
    static let vaultOcean     = Color(hex: "#0D2744")
    static let vaultSurface   = Color(hex: "#0F2E52")

    // Accent palette — matched to Circle feature's mint/teal signature
    static let vaultBlue      = Color.teal          // matches Circle's LovedOne + online indicator
    static let vaultCyan      = Color.mint          // matches Circle's glow rings

    // Status palette
    static let vaultSuccess   = Color(hex: "#34D399")
    static let vaultWarning   = Color(hex: "#FBBF24")
    static let vaultError     = Color(hex: "#FF6B6B")

    // Hex initialiser
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        let value = UInt64(cleaned, radix: 16) ?? 0
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8)  & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Glass Modifier (dark vault variant)

struct VaultGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.28),
                                        .white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint:   .bottomTrailing
                                ),
                                lineWidth: 0.6
                            )
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func vaultGlass(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.08
    ) -> some View {
        modifier(VaultGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Category Tag

struct CategoryTagView: View {
    let category: DocumentCategory
    var compact: Bool = false

    var body: some View {
        if compact {
            Image(systemName: category.systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(category.color)
                .padding(5)
                .background(category.color.opacity(0.18), in: Circle())
        } else {
            Label(category.displayName, systemImage: category.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.color.opacity(0.15), in: Capsule())
                .overlay(Capsule().stroke(category.color.opacity(0.3), lineWidth: 0.5))
        }
    }
}

// MARK: - Badge Row

struct DocumentBadgeRow: View {
    let document: DocumentFile

    var body: some View {
        HStack(spacing: 6) {
            if document.isEncrypted {
                badge(icon: "lock.fill", color: .vaultSuccess)
            }
            if document.isOffline {
                badge(icon: "arrow.down.circle.fill", color: .vaultCyan)
            }
            if document.isShared {
                badge(icon: "person.2.fill", color: .vaultBlue)
            }
            if document.isVerified {
                badge(icon: "checkmark.seal.fill", color: .vaultSuccess)
            }
            Spacer(minLength: 0)
        }
    }

    private func badge(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
    }
}

// MARK: - Encrypted Badge

struct EncryptedBadgeView: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8, weight: .bold))
            Text("Encrypted")
                .font(.system(size: 8, weight: .semibold))
        }
        .foregroundStyle(Color.vaultSuccess)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.vaultSuccess.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(Color.vaultSuccess.opacity(0.3), lineWidth: 0.4))
    }
}
