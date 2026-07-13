import SwiftUI

/// App Store compliance surface (Guideline 5.1.1 / data transparency).
///
/// Explains, in plain language, what Astronova stores, where it lives
/// (local-first vs. synced), how anonymous analytics work, and the two
/// privacy controls the user actually holds: the analytics opt-out and
/// full account deletion.
///
/// Presented inside a host-provided `NavigationStack` (SettingsSheet,
/// MoreOptionsSheet, and the RootView profile menu all wrap it and supply
/// their own "Done" affordance), so this view deliberately does NOT create
/// its own `NavigationStack`.
struct DataPrivacyView: View {
    /// Live analytics opt-in state. `PortfolioAnalytics` is the source of
    /// truth (it persists `isOptedOut` and rotates the random app UUID), so
    /// the summary row always reflects whatever the user last chose in
    /// Settings — there is no separate copy to drift out of sync.
    @State private var analyticsOptedIn: Bool = !PortfolioAnalytics.shared.isOptedOut

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard

                sectionHeader("WHAT WE STORE")
                storageCard(
                    icon: "iphone",
                    tint: .cosmicGold,
                    title: "Stays on this device",
                    detail: "Journal entries, decision simulations, and your personal navigation rules are written to local storage on this iPhone only. They are never uploaded unless you export and share them yourself."
                )
                storageCard(
                    icon: "icloud",
                    tint: .cosmicAmethyst,
                    title: "Synced when you sign in",
                    detail: "Your birth details (name, date, time, place) sync to Astronova's backend after you sign in so charts, reports, and Ask the Oracle work across sessions. That is the only personal profile data that leaves the device."
                )

                sectionHeader("ANALYTICS")
                analyticsCard

                sectionHeader("HOW WE PROTECT IT")
                storageCard(
                    icon: "lock.shield.fill",
                    tint: .cosmicGold,
                    title: "Encrypted in transit",
                    detail: "All traffic to Astronova's servers uses HTTPS. Your sign-in token is stored in the iOS Keychain, not in plain preferences."
                )
                storageCard(
                    icon: "number.square.fill",
                    tint: .cosmicAmethyst,
                    title: "IP addresses are hashed",
                    detail: "When analytics events reach the server, your IP address is one-way hashed (SHA-256 with a server-side salt) before it is recorded. The raw address is never stored, so events can't be traced back to a network address."
                )
                storageCard(
                    icon: "hand.raised.slash.fill",
                    tint: .cosmicGold,
                    title: "We never sell your data",
                    detail: "Astronova does not sell or rent your personal information to anyone."
                )

                sectionHeader("YOUR CONTROL")
                controlCard

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.dataPrivacy.view")
        .onAppear {
            // Re-read in case the analytics toggle was changed elsewhere
            // (e.g. the Settings sheet) while this view was on the stack.
            analyticsOptedIn = !PortfolioAnalytics.shared.isOptedOut
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicGold)
                Text("Your data, mostly on your device")
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            Text("Astronova is built local-first. The reflective work you do — journaling, decisions, and the rules you write for yourself — never leaves this iPhone unless you choose to export it. Only your birth details sync, and only after you sign in.")
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.25), lineWidth: 1)
        )
        .accessibilityIdentifier("settings.dataPrivacy.summary")
    }

    // MARK: - Analytics

    private var analyticsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicAmethyst)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous usage")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(analyticsOptedIn ? "Currently ON" : "Currently OFF")
                        .font(.cosmicLabel)
                        .foregroundStyle(analyticsOptedIn ? Color.cosmicGold : Color.cosmicTextTertiary)
                }
                Spacer()
            }
            Text("If on, Astronova records pseudonymous usage events tied to a random app ID (not your name or Apple ID) to understand which features help. Turn it off in Settings to stop collection — that also clears buffered events, rotates the random ID, and stops session diagnostics.")
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .accessibilityIdentifier("settings.dataPrivacy.analyticsStatus")
    }

    // MARK: - Control summary

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            controlRow(
                icon: "slider.horizontal.3",
                title: "Turn analytics on or off",
                detail: "Settings → Share Anonymous Usage."
            )
            Divider().overlay(Color.cosmicTextTertiary.opacity(0.2))
            controlRow(
                icon: "square.and.arrow.up",
                title: "Export your data",
                detail: "Settings → Export My Data writes a JSON copy you can save or share."
            )
            Divider().overlay(Color.cosmicTextTertiary.opacity(0.2))
            controlRow(
                icon: "trash.fill",
                tint: .cosmicError,
                title: "Delete your account",
                detail: "Settings → Delete Account permanently removes your account and all data from Astronova's servers. We sign you out only once the server confirms the deletion."
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .accessibilityIdentifier("settings.dataPrivacy.controls")
    }

    private func controlRow(icon: String, tint: Color = .cosmicGold, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(detail)
                    .font(.cosmicLabel)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Building blocks

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.cosmicMicro)
                .tracking(2)
                .foregroundStyle(Color.cosmicTextTertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }

    private func storageCard(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(detail)
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cosmicSurface)
        )
    }
}
