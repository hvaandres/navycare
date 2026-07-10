// AnimatedVaultBackground.swift
// navycare — Documents Feature
//
// Full-screen animated background: midnight navy gradient, 3 floating
// radial gradient orbs, and 12 drifting star particles.
// All motion is paused when accessibilityReduceMotion is enabled.

import SwiftUI

// MARK: - Particle

private struct Particle {
    let x:        CGFloat  // 0–1 normalized
    let y:        CGFloat
    let size:     CGFloat
    let speed:    Double   // seconds per full cycle
    let phase:    Double   // initial phase offset
    let opacity:  Double
}

private let particles: [Particle] = (0..<14).map { i in
    let seed = Double(i) * 0.73
    return Particle(
        x:       CGFloat((sin(seed * 2.3) * 0.5 + 0.5)),
        y:       CGFloat((cos(seed * 1.7) * 0.5 + 0.5)),
        size:    CGFloat(1.5 + (sin(seed) * 0.5 + 0.5) * 2.5),
        speed:   8 + (sin(seed * 3.1) * 0.5 + 0.5) * 12,
        phase:   seed * 6.28,
        opacity: 0.25 + (sin(seed * 1.1) * 0.5 + 0.5) * 0.35
    )
}

// MARK: - Orb Definition

private struct OrbDef {
    let xFrac:   CGFloat
    let yFrac:   CGFloat
    let radius:  CGFloat
    let color:   Color
    let speed:   Double
    let phase:   Double
}

private let orbs: [OrbDef] = [
    OrbDef(xFrac: 0.15, yFrac: 0.25, radius: 200, color: Color(hex: "#0D3A3A"), speed: 18, phase: 0.0),
    OrbDef(xFrac: 0.80, yFrac: 0.55, radius: 160, color: Color(hex: "#0A2E35"), speed: 22, phase: 2.1),
    OrbDef(xFrac: 0.45, yFrac: 0.80, radius: 140, color: Color.teal.opacity(0.6), speed: 28, phase: 4.2),
]

// MARK: - View

/// Full-screen animated vault background — use as the base layer of FilesView.
struct AnimatedVaultBackground: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [.vaultNavy, .vaultOcean],
                    startPoint: .topLeading,
                    endPoint:   .bottomTrailing
                )

                if reduceMotion {
                    staticOrbs(size: geo.size)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        animatedContent(size: geo.size, t: t)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Static fallback

    private func staticOrbs(size: CGSize) -> some View {
        ZStack {
            ForEach(orbs.indices, id: \.self) { i in
                let orb = orbs[i]
                RadialGradient(
                    colors: [orb.color.opacity(0.35), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: orb.radius
                )
                .frame(width: orb.radius * 2, height: orb.radius * 2)
                .position(
                    x: orb.xFrac * size.width,
                    y: orb.yFrac * size.height
                )
                .blur(radius: 40)
            }
        }
    }

    // MARK: - Animated content

    private func animatedContent(size: CGSize, t: Double) -> some View {
        ZStack {
            // Floating orbs
            ForEach(orbs.indices, id: \.self) { i in
                let orb = orbs[i]
                let angle  = (t / orb.speed + orb.phase) * 2 * .pi
                let offsetX = CGFloat(sin(angle)) * 30
                let offsetY = CGFloat(cos(angle * 0.7)) * 20

                RadialGradient(
                    colors: [orb.color.opacity(0.40), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: orb.radius
                )
                .frame(width: orb.radius * 2, height: orb.radius * 2)
                .position(
                    x: orb.xFrac * size.width  + offsetX,
                    y: orb.yFrac * size.height + offsetY
                )
                .blur(radius: 38)
            }

            // Drifting star particles
            ForEach(particles.indices, id: \.self) { i in
                let p     = particles[i]
                let drift = (t / p.speed + p.phase)
                let dx    = CGFloat(sin(drift * 2) * 15)
                let dy    = CGFloat(cos(drift)      * 10)
                let pulse = (sin(drift * 3 + p.phase) * 0.5 + 0.5) * p.opacity

                Circle()
                    .fill(Color.vaultCyan.opacity(pulse))
                    .frame(width: p.size, height: p.size)
                    .position(
                        x: p.x * size.width  + dx,
                        y: p.y * size.height + dy
                    )
            }

            // Subtle grid overlay
            Color.white.opacity(0.012)
                .blendMode(.screen)
        }
    }
}

#Preview {
    AnimatedVaultBackground()
        .frame(width: 390, height: 844)
}
