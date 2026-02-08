//
//  DIYPoojaCompletionView.swift
//  AstronovaApp
//
//  Celebration screen after completing a DIY Pooja
//

import SwiftUI

struct DIYPoojaCompletionView: View {
    let poojaName: String
    let onDismiss: () -> Void

    @State private var showCheckmark = false
    @State private var showXP = false
    @State private var particlePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: Cosmic.Spacing.xl) {
            Spacer()

            // Celebration animation
            ZStack {
                // Particles
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(Color.cosmicGold)
                        .frame(width: 6, height: 6)
                        .offset(y: -80 * particlePhase)
                        .rotationEffect(.degrees(Double(i) * 30))
                        .opacity(Double(1 - particlePhase))
                }

                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cosmicGold.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.cosmicSuccess)
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)
            }

            // Title
            Text(L10n.Temple.DIYPooja.completionTitle)
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(poojaName)
                .font(.cosmicTitle3)
                .foregroundStyle(Color.cosmicGold)

            // XP badge
            if showXP {
                Text(L10n.Temple.DIYPooja.xpAwarded(25))
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.lg)
                    .padding(.vertical, Cosmic.Spacing.s)
                    .background {
                        Capsule()
                            .fill(Color.cosmicGold.opacity(0.15))
                            .overlay {
                                Capsule()
                                    .stroke(Color.cosmicGold.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .transition(.scale.combined(with: .opacity))
            }

            Text(L10n.Temple.DIYPooja.completionSubtitle)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Cosmic.Spacing.screen)

            Spacer()

            // Return button
            Button {
                CosmicHaptics.light()
                onDismiss()
            } label: {
                Text("Return to Temple")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(maxWidth: .infinity)
                    .frame(height: Cosmic.ButtonHeight.large)
                    .background(LinearGradient.cosmicAntiqueGold)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.bottom, Cosmic.Spacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                particlePhase = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
                showXP = true
            }
            CosmicHaptics.success()
        }
    }
}
