// CircleView.swift
// navycare — Circle Feature
//
// Root screen for the care circle. Composes the orbit, Loved One node,
// and all sheet flows into a single cohesive experience.

import SwiftUI

/// The care circle screen — a living, animated constellation of trust.
struct CircleView: View {

    @State private var viewModel = CircleViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let shortSide    = min(geo.size.width, geo.size.height)
                let orbitRadius  = shortSide * 0.37

                ZStack {
                    // Adaptive background gradient
                    backgroundGradient

                    // Orbit + nodes
                    orbitLayer(orbitRadius: orbitRadius)
                        .position(
                            x: geo.size.width  / 2,
                            y: geo.size.height / 2 - 16
                        )

                    // Caregiver count badge (bottom)
                    caregiverSummary
                        .frame(
                            maxWidth:  .infinity,
                            maxHeight: .infinity,
                            alignment: .bottom
                        )
                        .padding(.bottom, 20)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { CircleToolbar(onSettingsTapped: {}) }
            // Invite sheet
            .sheet(isPresented: $viewModel.showingInviteSheet) {
                InviteCaregiverSheet { caregiver in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        viewModel.addCaregiver(caregiver)
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            // Member detail card — use isPresented to avoid race with TimelineView redraws
            .sheet(isPresented: $viewModel.showingMemberCard, onDismiss: {
                viewModel.selectedCaregiver = nil
            }) {
                if let caregiver = viewModel.selectedCaregiver {
                    CircleMemberCard(
                        caregiver: caregiver,
                        onSave: { updated in
                            viewModel.updateCaregiver(updated)
                        },
                        onRemove: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                viewModel.removeCaregiver(caregiver)
                            }
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                }
            }
        }
    }

    // MARK: - Subviews

    private func orbitLayer(orbitRadius: CGFloat) -> some View {
        ZStack {
            OrbitAnimationView(
                slots:             viewModel.caregiverSlots,
                orbitRadius:       orbitRadius,
                onCaregiverTap:    viewModel.tapCaregiver,
                onCaregiverRemove: { caregiver in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        viewModel.removeCaregiver(caregiver)
                    }
                },
                onSlotTap:         viewModel.tapSlot
            )

            // Center — Loved One
            VStack(spacing: 8) {
                LovedOneView(
                    lovedOne: viewModel.lovedOne,
                    onTap:    viewModel.tapLovedOne
                )
                Text(viewModel.lovedOne.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(viewModel.lovedOne.status)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground),
                Color.teal.opacity(0.04)
            ],
            startPoint: .top,
            endPoint:   .bottom
        )
        .ignoresSafeArea()
    }

    private var caregiverSummary: some View {
        let count  = viewModel.caregivers.count
        let online = viewModel.onlineCaregiverCount

        return HStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .font(.caption2)
                .symbolRenderingMode(.hierarchical)
            Text("\(count) caregiver\(count == 1 ? "" : "s")")
            if online > 0 {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("\(online) online")
                    .foregroundStyle(.green)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) caregivers, \(online) online")
    }
}

// MARK: - Preview

#Preview {
    CircleView()
}
