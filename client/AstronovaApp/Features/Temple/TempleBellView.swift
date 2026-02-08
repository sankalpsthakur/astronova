//
//  TempleBellView.swift
//  AstronovaApp
//
//  Temple Bell hero section - tap daily to maintain a streak
//

import SwiftUI

struct TempleBellView: View {
    @EnvironmentObject private var gamification: GamificationManager
    @State private var bellState: TempleBellState = TempleBellState.load()
    @State private var isAnimating = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            // Bell Animation
            TempleBellAnimationView(
                isAnimating: $isAnimating,
                hasRungToday: bellState.hasRungToday
            )
            .onTapGesture {
                ringBell()
            }

            // Status text
            if bellState.hasRungToday {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.cosmicSuccess)
                    Text(L10n.Temple.Bell.rungToday)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicSuccess)
                }
            } else {
                Text(L10n.Temple.Bell.ringTheBell)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicGold)
            }

            // Streak display
            HStack(spacing: Cosmic.Spacing.xl) {
                VStack(spacing: Cosmic.Spacing.xxs) {
                    Text("\(bellState.currentStreak)")
                        .font(.cosmicDisplay)
                        .foregroundStyle(Color.cosmicGold)
                    Text(L10n.Temple.Bell.dayStreak)
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Rectangle()
                    .fill(Color.cosmicTextTertiary.opacity(0.3))
                    .frame(width: 1, height: 40)

                VStack(spacing: Cosmic.Spacing.xxs) {
                    Text("\(bellState.longestStreak)")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(L10n.Temple.Bell.longestStreak)
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Rectangle()
                    .fill(Color.cosmicTextTertiary.opacity(0.3))
                    .frame(width: 1, height: 40)

                VStack(spacing: Cosmic.Spacing.xxs) {
                    Text("\(bellState.totalRings)")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Total")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }

            // Reminder toggle
            Button {
                showSettings.toggle()
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: bellState.reminderEnabled ? "bell.badge.fill" : "bell.slash")
                        .font(.cosmicCaption)
                    Text(bellState.reminderEnabled ? L10n.Temple.Bell.reminderTitle : "Reminder Off")
                        .font(.cosmicCaption)
                }
                .foregroundStyle(Color.cosmicTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Cosmic.Spacing.xl)
        .padding(.horizontal, Cosmic.Spacing.screen)
        .background {
            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                .fill(Color.cosmicSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cosmicGold.opacity(0.3), Color.cosmicAmethyst.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .sheet(isPresented: $showSettings) {
            BellSettingsSheet(bellState: $bellState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func ringBell() {
        if bellState.hasRungToday {
            // Already rung - just bounce
            isAnimating = true
            CosmicHaptics.light()
            return
        }

        // Ring the bell
        isAnimating = true
        CosmicHaptics.success()

        // Update streak
        let todayKey = TempleBellState.todayKey()
        let yesterdayKey = TempleBellState.yesterdayKey()

        if bellState.lastRingDay == yesterdayKey {
            bellState.currentStreak += 1
        } else {
            bellState.currentStreak = 1
        }

        bellState.lastRingDay = todayKey
        bellState.totalRings += 1
        bellState.longestStreak = max(bellState.longestStreak, bellState.currentStreak)

        // Award XP
        gamification.markTempleBellRung(streak: bellState.currentStreak)

        // Track analytics
        Analytics.shared.track(.templeBellRung, properties: [
            "streak": "\(bellState.currentStreak)",
            "total_rings": "\(bellState.totalRings)"
        ])

        // Persist state
        bellState.save()

        // Fire-and-forget server sync
        Task {
            await APIServices.shared.recordBellRing(
                streak: bellState.currentStreak,
                totalRings: bellState.totalRings
            )
        }

        // Schedule/refresh notification
        if bellState.reminderEnabled {
            Task {
                await NotificationService.shared.scheduleTempleBellReminder(at: bellState.reminderHour)
            }
        }
    }
}

// MARK: - Bell Settings Sheet

struct BellSettingsSheet: View {
    @Binding var bellState: TempleBellState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Cosmic.Spacing.xl) {
                Toggle(isOn: $bellState.reminderEnabled) {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text(L10n.Temple.Bell.reminderTitle)
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)
                        Text(L10n.Temple.Bell.reminderSubtitle)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
                .tint(Color.cosmicGold)
                .onChange(of: bellState.reminderEnabled) { _, enabled in
                    if enabled {
                        Task {
                            await NotificationService.shared.scheduleTempleBellReminder(at: bellState.reminderHour)
                        }
                    } else {
                        NotificationService.shared.cancelTempleBellReminder()
                    }
                    bellState.save()
                }

                if bellState.reminderEnabled {
                    Picker("Reminder Time", selection: $bellState.reminderHour) {
                        ForEach(5...22, id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .onChange(of: bellState.reminderHour) { _, _ in
                        Task {
                            await NotificationService.shared.scheduleTempleBellReminder(at: bellState.reminderHour)
                        }
                        bellState.save()
                    }
                }

                Spacer()
            }
            .padding(Cosmic.Spacing.screen)
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bell Reminder")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
        }
    }
}
