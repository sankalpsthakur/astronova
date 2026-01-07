import SwiftUI

// MARK: - Foundation Section
// Collapsible birth data and chart access
// Secondary to the living cosmic data above

struct FoundationSection: View {
    @EnvironmentObject private var auth: AuthState
    @Binding var isExpanded: Bool

    let onEditBirth: () -> Void
    let onViewChart: () -> Void

    private var profile: UserProfile {
        auth.profileManager.profile
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapse header
            collapseHeader

            // Expandable content
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicStardust.opacity(0.4))
        )
        .animation(.cosmicSpring, value: isExpanded)
    }

    // MARK: - Collapse Header

    private var collapseHeader: some View {
        Button {
            CosmicHaptics.light()
            withAnimation(.cosmicSpring) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.cosmicTextSecondary)

                Text("Foundation")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Spacer()

                // Completeness indicator
                if auth.profileManager.isProfileComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.cosmicSuccess)
                } else {
                    Text("Incomplete")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicWarning)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(Cosmic.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("foundationToggle")
        .accessibilityLabel("Foundation section, \(isExpanded ? "expanded" : "collapsed")")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Divider()
                .background(Color.cosmicTextTertiary.opacity(0.2))

            // Birth details
            VStack(spacing: Cosmic.Spacing.sm) {
                FoundationRow(
                    icon: "calendar",
                    label: "Born",
                    value: formattedBirthDate
                )

                FoundationRow(
                    icon: "clock",
                    label: "Time",
                    value: formattedBirthTime,
                    isMissing: profile.birthTime == nil
                )

                FoundationRow(
                    icon: "location",
                    label: "Place",
                    value: profile.birthPlace ?? "Not set",
                    isMissing: profile.birthPlace == nil
                )
            }

            // Action buttons
            HStack(spacing: Cosmic.Spacing.sm) {
                Button(action: onEditBirth) {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Edit Details")
                            .font(.cosmicCaptionEmphasis)
                    }
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                            .stroke(Color.cosmicGold.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button(action: onViewChart) {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "circle.hexagongrid")
                            .font(.system(size: 12))
                        Text("View Chart")
                            .font(.cosmicCaptionEmphasis)
                    }
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                            .fill(Color.cosmicNebula)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.horizontal, Cosmic.Spacing.md)
        .padding(.bottom, Cosmic.Spacing.md)
    }

    // MARK: - Formatters

    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: profile.birthDate)
    }

    private var formattedBirthTime: String {
        guard let time = profile.birthTime else { return "Not set" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}

// MARK: - Foundation Row

private struct FoundationRow: View {
    let icon: String
    let label: String
    let value: String
    var isMissing: Bool = false

    var body: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isMissing ? Color.cosmicWarning : Color.cosmicTextTertiary)
                .frame(width: 20)

            Text(label)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .frame(width: 40, alignment: .leading)

            Text(value)
                .font(.cosmicCallout)
                .foregroundStyle(isMissing ? Color.cosmicTextTertiary : Color.cosmicTextPrimary)

            Spacer()
        }
    }
}

// MARK: - Account Footer

struct AccountFooter: View {
    let isPro: Bool
    let onUpgrade: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: Cosmic.Spacing.md) {
            // Subscription status - more prominent indicator
            Button(action: onUpgrade) {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: isPro ? "crown.fill" : "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isPro ? Color.cosmicGold : Color.cosmicTextSecondary)

                    Text(isPro ? "Pro" : "Free")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(isPro ? Color.cosmicGold : Color.cosmicTextSecondary)

                    if !isPro {
                        Text("Upgrade")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicVoid)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.cosmicGold))
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.sm)
                .padding(.vertical, Cosmic.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isPro ? Color.cosmicGold.opacity(0.15) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isPro ? Color.cosmicGold.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(isPro ? "subscriptionStatusPro" : "subscriptionStatusFree")
            .accessibilityLabel(isPro ? "Pro subscription active" : "Free plan, tap to upgrade")

            Spacer()

            // Settings
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settingsButton")

            // Help
            Link(destination: URL(string: "https://astronova.app/help")!) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .accessibilityIdentifier("helpButton")
        }
        .padding(.horizontal, Cosmic.Spacing.md)
        .padding(.vertical, Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicStardust.opacity(0.3))
        )
    }
}

// MARK: - Preview

#Preview("Foundation Section") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        VStack(spacing: 20) {
            FoundationSection(
                isExpanded: .constant(true),
                onEditBirth: {},
                onViewChart: {}
            )
            .padding()

            AccountFooter(
                isPro: false,
                onUpgrade: {},
                onSettings: {}
            )
            .padding()

            AccountFooter(
                isPro: true,
                onUpgrade: {},
                onSettings: {}
            )
            .padding()
        }
        .environmentObject(AuthState())
    }
}
