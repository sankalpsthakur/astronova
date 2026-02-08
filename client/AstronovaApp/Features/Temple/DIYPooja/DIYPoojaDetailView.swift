//
//  DIYPoojaDetailView.swift
//  AstronovaApp
//
//  Walkthrough container for a DIY Pooja guide
//

import SwiftUI

struct DIYPoojaDetailView: View {
    let pooja: DIYPooja
    @EnvironmentObject private var gamification: GamificationManager
    @State private var isPerformingPooja = false
    @State private var currentStepIndex = 0
    @State private var showCompletion = false
    @State private var showIngredients = true

    var body: some View {
        Group {
            if showCompletion {
                DIYPoojaCompletionView(poojaName: pooja.name) {
                    showCompletion = false
                    isPerformingPooja = false
                }
            } else if isPerformingPooja {
                DIYPoojaStepView(
                    steps: pooja.steps,
                    currentStepIndex: $currentStepIndex,
                    onComplete: {
                        Analytics.shared.track(.diyPoojaCompleted, properties: [
                            "pooja_name": pooja.name,
                            "steps_count": "\(pooja.steps.count)"
                        ])
                        gamification.markDIYPoojaCompleted(poojaName: pooja.name)
                        showCompletion = true
                    }
                )
            } else {
                overviewContent
            }
        }
        .background(Color.cosmicVoid)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(pooja.name)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
        }
        .onAppear {
            Analytics.shared.track(.diyPoojaStarted, properties: [
                "pooja_name": pooja.name
            ])
        }
    }

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                // Header
                VStack(spacing: Cosmic.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.cosmicGold.opacity(0.3), Color.cosmicVoid],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: pooja.iconName)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(Color.cosmicGold)
                    }

                    Text(pooja.name)
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(pooja.deity)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicGold)

                    Text(pooja.description)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: Cosmic.Spacing.lg) {
                        Label("\(pooja.durationMinutes) min", systemImage: "clock.fill")
                        Label("\(pooja.steps.count) steps", systemImage: "list.number")
                    }
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                }
                .padding(.top, Cosmic.Spacing.xl)
                .padding(.horizontal, Cosmic.Spacing.screen)

                // Significance
                if !pooja.significance.isEmpty {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        Text(L10n.Temple.DIYPooja.significance)
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Text(pooja.significance)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }

                // Start Pooja CTA
                Button {
                    CosmicHaptics.medium()
                    currentStepIndex = 0
                    isPerformingPooja = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(L10n.Temple.DIYPooja.startPooja)
                    }
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(maxWidth: .infinity)
                    .frame(height: Cosmic.ButtonHeight.large)
                    .background(LinearGradient.cosmicAntiqueGold)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                }
                .padding(.horizontal, Cosmic.Spacing.screen)

                // Ingredients
                DIYPoojaIngredientsView(ingredients: pooja.ingredients)

                // Steps preview
                VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                    Text("Steps")
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, Cosmic.Spacing.screen)

                    ForEach(Array(pooja.steps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: Cosmic.Spacing.md) {
                            Text("\(index + 1)")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicGold)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.cosmicGold.opacity(0.15)))

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                                Text(step.title)
                                    .font(.cosmicCalloutEmphasis)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                Text(step.description)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)
                    }
                }

                Spacer().frame(height: 60)
            }
        }
    }
}
