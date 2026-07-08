// OrbitAnimationView.swift
// navycare — Circle Feature
//
// Positions caregiver nodes in a circular orbit using TimelineView for
// smooth 60fps continuous animation without @State mutation overhead.

import SwiftUI

// MARK: - Orbit Parameters

private enum OrbitParameters {
    /// Seconds for one complete revolution.
    static let period: Double      = 90
    /// Seconds for one float cycle (up → down → up).
    static let floatPeriod: Double = 4.0
    /// Max vertical float offset in points.
    static let floatAmplitude: CGFloat = 9
    /// Starting angle offset so slot 0 begins at 12 o'clock.
    static let startAngleOffset: Double = -.pi / 2
}

// MARK: - View

/// Renders all five orbit slots with continuous orbit rotation and gentle floating.
struct OrbitAnimationView: View {

    let slots:                [CaregiverSlot]
    let orbitRadius:          CGFloat
    let onCaregiverTap:       (Caregiver) -> Void
    let onCaregiverRemove:    (Caregiver) -> Void
    let onSlotTap:            (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(
            .animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)
        ) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            ZStack {
                orbitRing

                ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                    let position = nodePosition(index: index, total: slots.count, t: t)
                    let floatY   = floatOffset(index: index, t: t)

                    nodeView(for: slot)
                        .offset(x: position.x, y: position.y + floatY)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.25).combined(with: .opacity),
                                removal:   .scale(scale: 0.10).combined(with: .opacity)
                            )
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: slots.count)
                }
            }
        }
    }

    // MARK: - Subviews

    private var orbitRing: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.09), .white.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .frame(width: orbitRadius * 2, height: orbitRadius * 2)
    }

    @ViewBuilder
    private func nodeView(for slot: CaregiverSlot) -> some View {
        switch slot {
        case .filled(let caregiver):
            CaregiverNodeView(
                caregiver: caregiver,
                onTap:    { onCaregiverTap(caregiver)    },
                onRemove: { onCaregiverRemove(caregiver) }
            )
        case .empty(let index):
            PlaceholderNodeView(onTap: { onSlotTap(index) })
        }
    }

    // MARK: - Math

    /// Returns the XY position for a node in the orbit at time `t`.
    private func nodePosition(index: Int, total: Int, t: Double) -> CGPoint {
        let base  = (2 * .pi * Double(index)) / Double(total)
        let sweep = reduceMotion ? 0.0 : (t.truncatingRemainder(dividingBy: OrbitParameters.period)
                                          / OrbitParameters.period * (2 * .pi))
        let angle = base + OrbitParameters.startAngleOffset + sweep

        return CGPoint(
            x: orbitRadius * CGFloat(cos(angle)),
            y: orbitRadius * CGFloat(sin(angle))
        )
    }

    /// Returns the vertical floating offset for a node at time `t`.
    private func floatOffset(index: Int, t: Double) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let phaseShift = Double(index) * (2 * .pi / Double(max(slots.count, 1)))
        return OrbitParameters.floatAmplitude
               * CGFloat(sin(t * (2 * .pi / OrbitParameters.floatPeriod) + phaseShift))
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geo in
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            OrbitAnimationView(
                slots: {
                    let filled = Caregiver.mockData.map { CaregiverSlot.filled($0) }
                    let empty  = (0 ..< (5 - filled.count)).map {
                        CaregiverSlot.empty(slotIndex: filled.count + $0)
                    }
                    return filled + empty
                }(),
                orbitRadius:       min(geo.size.width, geo.size.height) * 0.36,
                onCaregiverTap:    { _ in },
                onCaregiverRemove: { _ in },
                onSlotTap:         { _ in }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
