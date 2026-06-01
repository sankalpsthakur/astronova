import SwiftUI

/// Bottom-nav Map surface.
///
/// The active product Map is the astrocartography / relocation globe from the
/// design ZIP. Birth-data recovery remains available, but the first impression
/// must be the Apple Maps-backed world surface rather than the retired terrain
/// radar.
struct MyMapView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingBirthEditor = false

    private var completeness: ProfileCompleteness {
        ProfileCompleteness(profile: auth.profileManager.profile)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstrocartographyMapView(data: .sample)

                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityLabel("Map tab")
                    .accessibilityIdentifier("mapTabView")
            }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    accuracyRecoveryBar
                }
                .background(Color.cosmicBackground.ignoresSafeArea())
                .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingBirthEditor) {
            QuickBirthEditView()
                .environmentObject(auth)
        }
    }

    @ViewBuilder
    private var accuracyRecoveryBar: some View {
        if completeness.level != .full, let nextUnlock = completeness.nextUnlock {
            HStack(spacing: Cosmic.Spacing.sm) {
                Image(systemName: nextUnlock.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.cosmicGold)
                    .frame(width: 28, height: 28)
                    .background(Color.cosmicGold.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sharpen this map")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("Add \(nextUnlock.title.lowercased()) for tighter relocation scoring.")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Cosmic.Spacing.xs)

                Button {
                    CosmicHaptics.light()
                    showingBirthEditor = true
                } label: {
                    Text("Improve")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicVoid)
                        .padding(.horizontal, Cosmic.Spacing.md)
                        .padding(.vertical, Cosmic.Spacing.sm)
                        .background(LinearGradient.cosmicAntiqueGold, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Improve chart accuracy")
                .accessibilityHint(nextUnlock.benefit)
                .accessibilityIdentifier(AccessibilityID.completeBirthDataButton)
            }
            .padding(Cosmic.Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.22), lineWidth: Cosmic.Border.thin)
            )
            .padding(.horizontal, Cosmic.Spacing.md)
            .padding(.bottom, Cosmic.Spacing.xs)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.mapAccuracyUpgradeBanner)
        }
    }
}
