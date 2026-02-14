//
//  TempleBellAnimationView.swift
//  AstronovaApp
//
//  Bell ring animation with rotation, scale, particles, and sound
//

import SwiftUI
import AVFoundation

struct TempleBellAnimationView: View {
    @Binding var isAnimating: Bool
    let hasRungToday: Bool

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var particlePhase: CGFloat = 0
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cosmicGold.opacity(0.3 * glowOpacity), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)

            // Particle burst
            if isAnimating && !hasRungToday {
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(Color.cosmicGold)
                        .frame(width: 4, height: 4)
                        .offset(y: -60 * particlePhase)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .opacity(Double(1 - particlePhase))
                }
            }

            // Bell icon
            Image(systemName: hasRungToday ? "bell.badge.fill" : "bell.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    hasRungToday
                        ? AnyShapeStyle(Color.cosmicSuccess)
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color.cosmicGold, Color.cosmicCopper],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                )
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .accessibilityLabel(hasRungToday ? "Bell rung today" : "Ring the temple bell")
                .accessibilityHint(hasRungToday ? "You've already rung the bell today" : "Double tap to ring")
        }
        .frame(width: 100, height: 100)
        .onChange(of: isAnimating) { _, animating in
            if animating {
                playAnimation()
            }
        }
        .onAppear {
            prepareAudio()
        }
    }

    private func playAnimation() {
        if hasRungToday {
            // Simple bounce for already rung
            withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                scale = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.0
                }
                isAnimating = false
            }
            return
        }

        // Full ring animation
        playBellSound()

        // Rotation oscillation
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 5).speed(1.2)) {
            rotation = 15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 5).speed(1.2)) {
                rotation = -12
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 8)) {
                rotation = 8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 10)) {
                rotation = -5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                rotation = 0
            }
        }

        // Scale pulse
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }

        // Glow
        withAnimation(.easeIn(duration: 0.2)) {
            glowOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                glowOpacity = 0
            }
        }

        // Particles
        withAnimation(.easeOut(duration: 0.8)) {
            particlePhase = 1.0
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particlePhase = 0
            isAnimating = false
        }
    }

    private func prepareAudio() {
        guard let url = Bundle.main.url(forResource: "bell", withExtension: "wav") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
    }

    private func playBellSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
