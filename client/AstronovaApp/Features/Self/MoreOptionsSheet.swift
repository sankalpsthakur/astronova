import SwiftUI

// MARK: - More Options Sheet
// Collapsed secondary options: settings, privacy, support, sign out

struct MoreOptionsSheet: View {
    @EnvironmentObject private var auth: AuthState
    @Environment(\.dismiss) private var dismiss
    @Binding var bookmarks: [BookmarkedReading]

    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPrivacyPolicy = false
    @State private var showingDataPrivacy = false
    @State private var showingExportData = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Cosmic.Spacing.lg) {
                    // Library Section
                    OptionsSection(title: "Library") {
                        OptionRow(
                            icon: "bookmark.fill",
                            iconColor: .cosmicGold,
                            title: "Saved Readings",
                            subtitle: bookmarks.isEmpty ? "None saved" : "\(bookmarks.count) saved"
                        ) {
                            // Navigate to bookmarks
                        }

                        NavigationLink {
                            InlineReportsStoreSheet()
                                .environmentObject(auth)
                        } label: {
                            OptionRowContent(
                                icon: "doc.text.fill",
                                iconColor: .cosmicAmethyst,
                                title: "Reports",
                                subtitle: "Detailed cosmic reports"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Preferences Section
                    OptionsSection(title: "Preferences") {
                        OptionRow(
                            icon: "bell.badge.fill",
                            iconColor: .cosmicCopper,
                            title: "Notifications",
                            subtitle: "Daily insights & updates"
                        ) {
                            // Open notification settings
                        }

                        OptionRow(
                            icon: "paintpalette.fill",
                            iconColor: .planetMercury,
                            title: "Appearance",
                            subtitle: "Auto"
                        ) {
                            // Open appearance settings
                        }
                    }

                    // Privacy Section
                    OptionsSection(title: "Privacy & Data") {
                        Button {
                            showingPrivacyPolicy = true
                        } label: {
                            OptionRowContent(
                                icon: "doc.text.magnifyingglass",
                                iconColor: .cosmicTextSecondary,
                                title: "Privacy Policy",
                                subtitle: nil
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingDataPrivacy = true
                        } label: {
                            OptionRowContent(
                                icon: "lock.shield.fill",
                                iconColor: .cosmicTextSecondary,
                                title: "Data & Privacy",
                                subtitle: nil
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingExportData = true
                        } label: {
                            OptionRowContent(
                                icon: "square.and.arrow.up",
                                iconColor: .cosmicTextSecondary,
                                title: "Export My Data",
                                subtitle: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Support Section
                    OptionsSection(title: "Support") {
                        Link(destination: URL(string: "mailto:admin@100xai.engineering")!) {
                            OptionRowContent(
                                icon: "message.fill",
                                iconColor: .cosmicInfo,
                                title: "Contact Support",
                                subtitle: nil
                            )
                        }

                        Link(destination: URL(string: "https://astronova.app/help")!) {
                            OptionRowContent(
                                icon: "questionmark.circle.fill",
                                iconColor: .cosmicInfo,
                                title: "Help Center",
                                subtitle: nil
                            )
                        }

                        Button {
                            showingAbout = true
                        } label: {
                            OptionRowContent(
                                icon: "star.circle.fill",
                                iconColor: .cosmicGold,
                                title: "About Astronova",
                                subtitle: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Account Section
                    OptionsSection(title: "Account") {
                        Button {
                            showingSignOutConfirmation = true
                        } label: {
                            OptionRowContent(
                                icon: "rectangle.portrait.and.arrow.right",
                                iconColor: .cosmicError,
                                title: "Sign Out",
                                subtitle: nil,
                                isDestructive: true
                            )
                        }
                        .buttonStyle(.plain)
                        if auth.isAuthenticated {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                OptionRowContent(
                                    icon: "trash.fill",
                                    iconColor: .cosmicError,
                                    title: "Delete Account",
                                    subtitle: nil,
                                    isDestructive: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // App version
                    VStack(spacing: Cosmic.Spacing.xxs) {
                        Text("Astronova")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextTertiary.opacity(0.6))
                    }
                    .padding(.top, Cosmic.Spacing.lg)
                    .padding(.bottom, Cosmic.Spacing.xxl)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.md)
            }
            .background(Color.cosmicCosmos.ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                auth.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await APIServices.shared.deleteAccount()
                    } catch {
                        // Continue with local sign out even if API fails
                    }
                    await MainActor.run {
                        auth.signOut()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingPrivacyPolicy = false }
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showingDataPrivacy) {
            NavigationStack {
                DataPrivacyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingDataPrivacy = false }
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showingExportData) {
            NavigationStack {
                ExportDataView(auth: auth)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingExportData = false }
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack {
                AboutView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingAbout = false }
                                .foregroundStyle(Color.cosmicGold)
                        }
                    }
            }
        }
    }
}

// MARK: - Options Section

private struct OptionsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text(title.uppercased())
                .font(.cosmicMicro)
                .tracking(CosmicTypography.Tracking.uppercase)
                .foregroundStyle(Color.cosmicTextTertiary)
                .padding(.leading, Cosmic.Spacing.xs)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(Color.cosmicStardust)
            )
        }
    }
}

// MARK: - Option Row

private struct OptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            OptionRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
                isDestructive: isDestructive
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Option Row Content

private struct OptionRowContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: Cosmic.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isDestructive ? Color.cosmicError : iconColor)
                .frame(width: 28)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cosmicBody)
                    .foregroundStyle(isDestructive ? Color.cosmicError : Color.cosmicTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }

            Spacer()

            // Chevron
            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextTertiary.opacity(0.5))
            }
        }
        .padding(.horizontal, Cosmic.Spacing.md)
        .padding(.vertical, Cosmic.Spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("More Options Sheet") {
    MoreOptionsSheet(bookmarks: .constant([]))
        .environmentObject(AuthState())
}
