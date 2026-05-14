//
//  PaywallPreamble.swift
//  AstronovaApp
//
//  Wave 11 polish — Move 1 (peak→pitch paywall sequences).
//
//  The redesign brief (P7, P10) asks for IAP nudges only AFTER a peak moment,
//  with brief amplification before the wall. Each peak surface owns its own
//  lead-in. This file collects the reusable components.
//
//  Routing model (see PaywallView.swift):
//  - `PaywallTrigger.fire()` posts `.paywallPreambleRequested`
//  - The owning surface observes the notification *for its trigger*, plays the
//    lead-in (delay, line, or overlay), then calls `firePaywallNow()`
//  - `.paywallRequested` is observed by RootView, which presents PaywallView
//
//  Why per-surface routing instead of one universal preamble view: the three
//  amplifications live in three different visual contexts. The chart admiration
//  must happen on the Time Travel chart itself (no interruption). The Oracle
//  line lives inside the chat thread. The reports overlay sits over the shop.
//  Trying to render all three from one view would require either a global
//  presenter that knows everything, or three nearly-empty subclasses.
//

import SwiftUI

// MARK: - Chart admiration (afterFirstChartReading)

/// A single quiet line that fades in after the user has admired their first
/// chart for ~5 seconds. Tapping it advances to the paywall. The line itself
/// is the only UI affordance — the chart is not interrupted.
///
/// The 5-second admire window is anchored in the calling surface: the surface
/// schedules a timer when the preamble is observed, then mounts this view.
struct PaywallChartAdmireLine: View {
    let onAdvance: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        Button(action: onAdvance) {
            HStack(spacing: Cosmic.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
                Text("Your chart holds more. Tap to explore.")
                    .font(.cosmicCallout.italic())
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold.opacity(0.7))
            }
            .padding(.horizontal, Cosmic.Spacing.md)
            .padding(.vertical, Cosmic.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .accessibilityIdentifier("paywallPreamble.chartAdmire")
        .accessibilityHint("Opens an upgrade option to explore your chart in depth")
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appeared = true }
        }
    }
}

// MARK: - Oracle "wants to say more" line

/// The line inserted into the Oracle chat thread after the user's 3rd session.
/// Visually mirrors a Shastriji message but is non-interactive in the thread —
/// tapping it transitions to the paywall.
struct PaywallOracleMoreLine: View {
    let onAdvance: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        Button(action: onAdvance) {
            HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shastriji")
                        .font(.cosmicCaption.weight(.bold))
                        .foregroundStyle(Color.cosmicGold)
                    Text("…wants to say more. Tap to continue.")
                        .font(.cosmicBody.italic())
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold.opacity(0.6))
            }
            .padding(Cosmic.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(Color.cosmicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .accessibilityIdentifier("paywallPreamble.oracleMore")
        .accessibilityHint("Opens an upgrade option to continue the conversation")
        .onAppear {
            withAnimation(.easeIn(duration: 0.45)) { appeared = true }
        }
    }
}

// MARK: - Reports "unlock deeper time" overlay

/// Full-screen translucent overlay shown after a user browses the Reports shop
/// for the first time. Auto-advances after a short hold, or on tap.
struct PaywallReportsOverlay: View {
    let onAdvance: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            Color.cosmicVoid
                .opacity(appeared ? 0.78 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onAdvance() }

            VStack(spacing: Cosmic.Spacing.lg) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.cosmicGold)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)

                Text("Reports unlock deeper time.")
                    .font(.cosmicTitle2.italic())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                Text("Each one is a long-form chapter of your life.\nTap to continue.")
                    .font(.cosmicCaption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(Cosmic.Spacing.xl)
        }
        .accessibilityIdentifier("paywallPreamble.reportsOverlay")
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tap to view upgrade options")
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) { appeared = true }
        }
    }
}

// MARK: - Preamble notification helper

/// Decodes a `.paywallPreambleRequested` notification into a typed trigger.
///
/// Surfaces use this in `.onReceive` so they only react to their own peak:
/// ```swift
/// .onReceive(NotificationCenter.default.publisher(for: .paywallPreambleRequested)) { note in
///     guard PaywallPreambleEvent(note)?.trigger == .afterFirstChartReading else { return }
///     // ... start admire timer / show line / etc.
/// }
/// ```
struct PaywallPreambleEvent {
    let trigger: PaywallTrigger
    let context: PaywallContext

    init?(_ notification: Notification) {
        guard let info = notification.userInfo,
              let triggerRaw = info["trigger"] as? String,
              let trigger = PaywallTrigger(rawValue: triggerRaw),
              let contextRaw = info["context"] as? String,
              let context = PaywallContext(rawValue: contextRaw) else { return nil }
        self.trigger = trigger
        self.context = context
    }
}
