import SwiftUI
import Diagnostics

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @StateObject private var storeKit = StoreKitManager.shared
    @StateObject private var quota = ProQuotaManager.shared
    @AppStorage("hasAstronovaPro") private var hasPro: Bool = false
    // Wave 3b A1 — Voice reading toggle. Re-wired into SettingsSheet after
    // the TopoSelf redesign sunset MoreOptionsSheet (the original home for
    // this toggle). Backed by the same UserDefaults key SpeechService reads.
    @AppStorage("astronova.voice_reading_enabled") private var voiceReadingEnabled: Bool = true

    @State private var showingPaywall = false
    @State private var showingReportsLibrary = false
    @State private var showingReportShop = false
    @State private var showingOracle = false
    @State private var showingPrivacy = false
    @State private var showingDataPrivacy = false
    @State private var showingExportData = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteFailed = false
    @State private var analyticsOptedIn: Bool = !PortfolioAnalytics.shared.isOptedOut
    @State private var restoreMessage: String?
    @State private var diagnosticsURL: URL?
    @State private var diagnosticsError: String?
    @State private var isGeneratingDiagnostics = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicVoid.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        proStatusCard
                        sectionHeader("REPORTS")
                        actionRow(
                            icon: "doc.text.fill",
                            title: "My Reports",
                            subtitle: "Open the reports you already have"
                        ) { showingReportsLibrary = true }
                        actionRow(
                            icon: "cart.fill",
                            title: "Buy Reports",
                            subtitle: "Birth, compatibility, career, more"
                        ) { showingReportShop = true }

                        sectionHeader("ASK")
                        actionRow(
                            icon: "sparkles",
                            title: "Ask the Oracle",
                            subtitle: "Open chat with token packs"
                        ) { showingOracle = true }

                        sectionHeader("ACCOUNT")
                        if auth.isAuthenticated || auth.state == .signedIn {
                            actionRow(
                                icon: "person.crop.circle.fill",
                                title: "Signed in",
                                subtitle: auth.profileManager.profile.fullName.isEmpty ? "Apple ID" : auth.profileManager.profile.fullName,
                                showsChevron: false
                            ) {}
                            actionRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign out",
                                subtitle: nil,
                                tint: .cosmicError,
                                accessibilityIdentifier: AccessibilityID.settingsSignOutButton
                            ) {
                                auth.signOut()
                                dismiss()
                            }
                            actionRow(
                                icon: "trash.fill",
                                title: "Delete Account",
                                subtitle: "Permanently remove this account and local session",
                                tint: .cosmicError,
                                accessibilityIdentifier: "settings.deleteAccount.button"
                            ) {
                                showingDeleteConfirmation = true
                            }
                        } else {
                            actionRow(
                                icon: "person.crop.circle.badge.plus",
                                title: "Sign in",
                                subtitle: "Return to onboarding to sign in with Apple",
                                accessibilityIdentifier: AccessibilityID.settingsSignInButton
                            ) {
                                dismiss()
                            }
                        }

                        sectionHeader("VOICE")
                        voiceReadingToggleRow

                        sectionHeader("LEGAL")
                        actionRow(icon: "hand.raised.fill", title: "Privacy", subtitle: nil) { showingPrivacy = true }
                        actionRow(
                            icon: "lock.shield.fill",
                            title: "Data & Privacy",
                            subtitle: "See what Astronova stores and how to control it",
                            accessibilityIdentifier: "settings.dataPrivacy.button"
                        ) {
                            showingDataPrivacy = true
                        }
                        actionRow(
                            icon: "square.and.arrow.up",
                            title: "Export My Data",
                            subtitle: "Prepare a local JSON export for sharing",
                            accessibilityIdentifier: "settings.exportData.button"
                        ) {
                            showingExportData = true
                        }
                        anonymousUsageToggleRow
                        sectionHeader("SUPPORT")
                        actionRow(
                            icon: "wrench.and.screwdriver.fill",
                            title: isGeneratingDiagnostics ? "Preparing Diagnostics…" : "Share Diagnostics Report",
                            subtitle: "App and system details with privacy-safe support events",
                            showsChevron: false,
                            accessibilityIdentifier: "settings.shareDiagnostics.button"
                        ) {
                            generateDiagnosticsReport()
                        }
                        .disabled(isGeneratingDiagnostics)
                        actionRow(
                            icon: "arrow.counterclockwise",
                            title: "Restore purchases",
                            subtitle: restoreMessage
                        ) {
                            Task {
                                let ok = await storeKit.restorePurchases()
                                restoreMessage = ok ? "Restored." : "No previous purchases found."
                            }
                        }

                        Spacer(minLength: 32)
                        appVersionFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.cosmicCalloutEmphasis)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            // Route through PaywallVariantRouter so RemoteConfig
            // (astronova_paywall_v1) can serve tiered_v1 / tiered_v2 designs.
            // Previously called PaywallView directly, which silently bypassed
            // the variant experiment and pinned everyone to control.
            PaywallVariantRouter(context: .general)
        }
        .sheet(isPresented: $showingReportsLibrary) {
            ReportsLibraryView(reports: [])
        }
        .sheet(isPresented: $showingReportShop) {
            InlineReportsStoreSheet()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showingOracle) {
            OracleView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showingPrivacy) {
            NavigationStack {
                ScrollView {
                    Text("Astronova does not sell your data. Birth details sync to Astronova's backend when you sign in so charts, reports, and Ask can work across sessions. Journal entries, decisions, and navigation rules stay on this device unless you choose to share them. See the in-app Privacy policy for details.")
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .padding(20)
                }
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showingDataPrivacy) {
            NavigationStack {
                DataPrivacyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingDataPrivacy = false }
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
                        }
                    }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { diagnosticsURL != nil },
                set: { if !$0 { cleanUpDiagnosticsReport() } }
            ),
            onDismiss: cleanUpDiagnosticsReport
        ) {
            if let diagnosticsURL {
                ShareSheet(items: [diagnosticsURL])
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        // Privacy (App Store Guideline 5.1.1): only sign out
                        // locally once the server confirms the account is gone.
                        // A failed server delete must NOT sign the user out, or
                        // their data is orphaned while they believe it's deleted.
                        try await APIServices.shared.deleteAccount()
                        await MainActor.run {
                            auth.signOut()
                            dismiss()
                        }
                    } catch {
                        await MainActor.run { deleteFailed = true }
                    }
                }
            }
        } message: {
            Text("This cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Couldn't Delete Account", isPresented: $deleteFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We couldn't delete your account just now. Your data has not been removed. Please check your connection and try again.")
        }
        .alert(
            "Couldn't Prepare Diagnostics",
            isPresented: Binding(
                get: { diagnosticsError != nil },
                set: { if !$0 { diagnosticsError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { diagnosticsError = nil }
        } message: {
            Text(diagnosticsError ?? "Please try again.")
        }
    }

    private func generateDiagnosticsReport() {
        guard !isGeneratingDiagnostics else { return }
        isGeneratingDiagnostics = true
        Task {
            await DiagnosticsSupportLog.shared.record("Diagnostics report requested from Settings")
            let reporters = DiagnosticsReporter.DefaultReporter.allCases.filter {
                if case .logs = $0 { return false }
                return true
            }.map(\.reporter) + [AstronovaSupportReporter()]
            let report = await DiagnosticsReporter.create(
                filename: "Astronova-Diagnostics.html",
                using: reporters,
                reportTitle: "Astronova Diagnostics Report"
            )

            do {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                    .appendingPathComponent(report.filename)
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try report.data.write(to: url, options: .atomic)
                diagnosticsURL = url
            } catch {
                diagnosticsError = "The report couldn't be saved for sharing."
            }
            isGeneratingDiagnostics = false
        }
    }

    private func cleanUpDiagnosticsReport() {
        guard let diagnosticsURL else { return }
        try? FileManager.default.removeItem(at: diagnosticsURL.deletingLastPathComponent())
        self.diagnosticsURL = nil
    }

    // MARK: - Voice reading toggle (Wave 3b A1)

    private var voiceReadingToggleRow: some View {
        Toggle(isOn: $voiceReadingEnabled) {
            HStack(spacing: 14) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice reading")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Read horoscope and confirmations aloud.")
                        .font(.cosmicLabel)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(2)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .cosmicGold))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .accessibilityIdentifier("settings.voiceReading.toggle")
        .onChange(of: voiceReadingEnabled) { _, newValue in
            if !newValue {
                SpeechService.shared.stop()
            }
        }
    }

    private var anonymousUsageToggleRow: some View {
        Toggle(isOn: $analyticsOptedIn) {
            HStack(spacing: 14) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share Anonymous Usage")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Helps us improve using a random app ID.")
                        .font(.cosmicLabel)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(2)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .cosmicGold))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .accessibilityIdentifier("settings.analyticsOptIn.toggle")
        .onChange(of: analyticsOptedIn) { _, newValue in
            PortfolioAnalytics.shared.isOptedOut = !newValue
            let projectKey = Bundle.main.infoDictionary?["SMARTLOOK_PROJECT_KEY"] as? String
            AnalyticsConsentController.applySmartlookConsent(projectKey: projectKey)
        }
    }

    // MARK: - Pro status

    private var proStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: hasPro ? "checkmark.seal.fill" : "sparkle")
                    .font(.cosmicHeadline)
                    .foregroundStyle(hasPro ? Color.cosmicGold : Color.cosmicAmethyst)
                Text(hasPro ? "Astronova Pro" : "Free plan")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
            }
            if !hasPro {
                Text("Quota:")
                    .font(.cosmicMicro)
                    .tracking(2)
                    .foregroundStyle(Color.cosmicTextTertiary)
                quotaLine("Decisions this month", used: quota.decisionsUsedThisMonth, limit: ProQuotaManager.decisionMonthlyLimit)
                quotaLine("Pattern details this week", used: quota.patternViewsUsedThisWeek, limit: ProQuotaManager.patternWeeklyLimit)
                quotaLine("Insights this month", used: quota.insightsViewsUsedThisMonth, limit: ProQuotaManager.insightsMonthlyLimit)
                Button {
                    showingPaywall = true
                } label: {
                    Text("Get Pro")
                        .font(.cosmicBodyEmphasis)
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cosmicGold)
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text("Unlimited decisions, full pattern library, full insights.")
                    .font(.cosmicFootnote)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(hasPro ? Color.cosmicGold.opacity(0.4) : Color.cosmicAmethyst.opacity(0.25), lineWidth: 1)
        )
    }

    private func quotaLine(_ label: String, used: Int, limit: Int) -> some View {
        HStack {
            Text(label)
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
            Spacer()
            Text("\(min(used, limit)) / \(limit)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(used >= limit ? Color.cosmicError : Color.cosmicTextPrimary)
        }
    }

    // MARK: - Section + Action row

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.cosmicMicro)
                .tracking(2)
                .foregroundStyle(Color.cosmicTextTertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }

    private func actionRow(
        icon: String,
        title: String,
        subtitle: String?,
        tint: Color = .cosmicTextPrimary,
        showsChevron: Bool = true,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticFeedbackService.shared.selection()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(tint)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.cosmicLabel)
                            .foregroundStyle(Color.cosmicTextTertiary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.cosmicLabel)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cosmicSurface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier ?? title)
    }

    private var appVersionFooter: some View {
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?"
        return Text("Astronova \(version) (\(build))")
            .font(.cosmicMicro)
            .tracking(1)
            .foregroundStyle(Color.cosmicTextTertiary)
            .padding(.bottom, 24)
    }
}
