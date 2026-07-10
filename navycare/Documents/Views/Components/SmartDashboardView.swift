// SmartDashboardView.swift
// navycare — Documents Feature
//
// Horizontal scroll of animated insight cards + category filter pills.

import SwiftUI

// MARK: - Smart Dashboard

struct SmartDashboardView: View {
    let cards: [SmartCard]

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        SmartCardView(card: card)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.75)
                                    .delay(Double(index) * 0.06),
                                value: appeared
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Smart Card

private struct SmartCardView: View {
    let card: SmartCard

    var accentColor: Color { Color(hex: card.accentHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: card.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 9))

                Spacer()
            }

            Text(card.metric)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(card.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(width: 110)
        .padding(14)
        .vaultGlass(cornerRadius: 16, opacity: 0.09)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.35), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.6
                )
        )
    }
}

// MARK: - Category Bubble View

struct CategoryBubbleView: View {
    @Binding var selectedCategory: DocumentCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                categoryPill(
                    label: "All",
                    icon:  "square.grid.2x2.fill",
                    color: .vaultBlue,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedCategory = nil
                    }
                }

                ForEach(DocumentCategory.allCases) { category in
                    categoryPill(
                        label: category.displayName,
                        icon:  category.systemImage,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    private func categoryPill(
        label:      String,
        icon:       String,
        color:      Color,
        isSelected: Bool,
        action:     @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : color.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? color.opacity(0.85)
                    : color.opacity(0.1),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? color.opacity(0.0) : color.opacity(0.3),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.4) : .clear,
                radius: 8, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    ZStack {
        Color.vaultNavy.ignoresSafeArea()
        VStack(spacing: 20) {
            SmartDashboardView(cards: FilesViewModel().smartCards)
            CategoryBubbleView(selectedCategory: .constant(nil))
        }
    }
    .preferredColorScheme(.dark)
}
