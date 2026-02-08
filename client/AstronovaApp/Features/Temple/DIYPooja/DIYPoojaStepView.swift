//
//  DIYPoojaStepView.swift
//  AstronovaApp
//
//  Individual step display with timer and mantra
//

import SwiftUI

struct DIYPoojaStepView: View {
    let steps: [DIYPoojaStep]
    @Binding var currentStepIndex: Int
    let onComplete: () -> Void

    @State private var timerRemaining: Int = 0
    @State private var timerTotal: Int = 0
    @State private var timerActive = false
    @State private var timer: Timer?

    private var currentStep: DIYPoojaStep {
        steps[currentStepIndex]
    }

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: Cosmic.Spacing.xxs) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStepIndex ? Color.cosmicGold : Color.cosmicTextTertiary.opacity(0.3))
                        .frame(height: 3)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.top, Cosmic.Spacing.md)

            // Step counter
            Text(L10n.Temple.DIYPooja.step(currentStepIndex + 1, steps.count))
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicGold)
                .padding(.top, Cosmic.Spacing.md)

            ScrollView {
                VStack(spacing: Cosmic.Spacing.xl) {
                    // Step title and description
                    VStack(spacing: Cosmic.Spacing.md) {
                        Text(currentStep.title)
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .multilineTextAlignment(.center)

                        Text(currentStep.description)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)

                    // Mantra section
                    if let sanskrit = currentStep.mantraSanskrit, !sanskrit.isEmpty {
                        VStack(spacing: Cosmic.Spacing.md) {
                            Text(L10n.Temple.DIYPooja.mantra)
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextTertiary)

                            // Sanskrit text
                            Text(sanskrit)
                                .font(.system(size: 20, weight: .medium, design: .serif))
                                .foregroundStyle(Color.cosmicGold)
                                .multilineTextAlignment(.center)
                                .padding(Cosmic.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                                        .fill(Color.cosmicGold.opacity(0.08))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                                                .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 1)
                                        }
                                }

                            // Transliteration
                            if let transliteration = currentStep.mantraTransliteration, !transliteration.isEmpty {
                                Text(transliteration)
                                    .font(.cosmicBody.italic())
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .multilineTextAlignment(.center)
                            }

                            // Meaning
                            if let meaning = currentStep.mantraMeaning, !meaning.isEmpty {
                                Text(meaning)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextTertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)
                    }

                    // Timer
                    if let duration = currentStep.timerDurationSeconds, duration > 0 {
                        timerSection(duration: duration)
                    }
                }
                .padding(.top, Cosmic.Spacing.xl)
            }

            // Navigation buttons
            HStack(spacing: Cosmic.Spacing.md) {
                if currentStepIndex > 0 {
                    Button {
                        CosmicHaptics.light()
                        stopTimer()
                        currentStepIndex -= 1
                        resetTimer()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text(L10n.Actions.back)
                        }
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: Cosmic.ButtonHeight.medium)
                        .background {
                            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                                .stroke(Color.cosmicTextTertiary.opacity(0.3), lineWidth: 1)
                        }
                    }
                }

                Button {
                    CosmicHaptics.medium()
                    stopTimer()
                    Analytics.shared.track(.diyPoojaStepCompleted, properties: [
                        "step": "\(currentStepIndex + 1)",
                        "step_title": currentStep.title
                    ])

                    if isLastStep {
                        onComplete()
                    } else {
                        currentStepIndex += 1
                        resetTimer()
                    }
                } label: {
                    HStack {
                        Text(isLastStep ? L10n.Temple.DIYPooja.complete : L10n.Actions.next)
                        if !isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(maxWidth: .infinity)
                    .frame(height: Cosmic.ButtonHeight.medium)
                    .background(LinearGradient.cosmicAntiqueGold)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.bottom, Cosmic.Spacing.lg)
        }
        .onDisappear {
            stopTimer()
        }
    }

    @ViewBuilder
    private func timerSection(duration: Int) -> some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Text(L10n.Temple.DIYPooja.timer)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: 6)
                    .frame(width: 100, height: 100)

                // Progress ring
                Circle()
                    .trim(from: 0, to: timerTotal > 0 ? CGFloat(timerRemaining) / CGFloat(timerTotal) : 1)
                    .stroke(Color.cosmicGold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerRemaining)

                // Time display
                Text(formatTime(timerRemaining > 0 ? timerRemaining : duration))
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .monospacedDigit()
            }

            // Timer controls
            HStack(spacing: Cosmic.Spacing.lg) {
                Button {
                    if timerActive {
                        stopTimer()
                    } else {
                        startTimer(duration: timerRemaining > 0 ? timerRemaining : duration)
                    }
                } label: {
                    Image(systemName: timerActive ? "pause.fill" : "play.fill")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.cosmicGold.opacity(0.15)))
                }

                Button {
                    stopTimer()
                    timerRemaining = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.cosmicSurface))
                }
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    private func startTimer(duration: Int) {
        timerTotal = currentStep.timerDurationSeconds ?? duration
        timerRemaining = duration
        timerActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerRemaining > 0 {
                timerRemaining -= 1
            } else {
                stopTimer()
                CosmicHaptics.success()
            }
        }
    }

    private func stopTimer() {
        timerActive = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        timerRemaining = 0
        timerTotal = 0
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
