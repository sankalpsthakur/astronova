import SwiftUI

/// App Store compliance surface (data portability / account-data access).
///
/// Lets the user export a copy of everything Astronova holds about them — the
/// birth profile, the most recently generated chart, and the local-first
/// journal entries, decision simulations, and navigation rules — as a single
/// human-readable JSON file they can save to Files, AirDrop, or email via the
/// system share sheet.
///
/// Presented inside a host-provided `NavigationStack` (SettingsSheet,
/// MoreOptionsSheet, RootView profile menu), so it does NOT create its own.
struct ExportDataView: View {
    @ObservedObject var auth: AuthState

    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    /// Lightweight, user-facing tally of what the export will contain, computed
    /// once on appear so the summary doesn't recompute on every redraw.
    @State private var summary = ExportSummary()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                contentsCard

                Button(action: generateAndShare) {
                    HStack(spacing: 10) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.cosmicVoid)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isGenerating ? "Preparing…" : "Export My Data")
                    }
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.cosmicGold)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isGenerating)
                .accessibilityIdentifier("settings.exportData.exportButton")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.cosmicFootnote)
                        .foregroundStyle(Color.cosmicError)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("The export is created on this device and only leaves it through the destination you pick in the share sheet. Astronova does not keep a copy.")
                    .font(.cosmicLabel)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle("Export My Data")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.exportData.view")
        .onAppear { summary = ExportSummary.current(auth: auth) }
        .sheet(isPresented: $showingShareSheet, onDismiss: cleanUpExportFile) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.cosmicGold)
            Text("Take your data with you")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Download everything Astronova stores about you as a single JSON file.")
                .font(.cosmicFootnote)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var contentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT'S INCLUDED")
                .font(.cosmicMicro)
                .tracking(2)
                .foregroundStyle(Color.cosmicTextTertiary)

            contentRow(icon: "person.text.rectangle", label: "Birth profile",
                       value: summary.hasProfile ? "Included" : "Empty")
            contentRow(icon: "circle.hexagongrid.fill", label: "Latest saved chart",
                       value: summary.hasChart ? "Included" : "None yet")
            contentRow(icon: "book.closed.fill", label: "Journal entries",
                       value: countLabel(summary.journalCount))
            contentRow(icon: "arrow.triangle.branch", label: "Decisions",
                       value: countLabel(summary.decisionCount))
            contentRow(icon: "list.bullet.rectangle", label: "Navigation rules",
                       value: countLabel(summary.ruleCount))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .accessibilityIdentifier("settings.exportData.contents")
    }

    private func contentRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(Color.cosmicAmethyst)
                .frame(width: 26)
            Text(label)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
            Spacer()
            Text(value)
                .font(.cosmicFootnoteEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
    }

    private func countLabel(_ n: Int) -> String {
        n == 0 ? "None" : "\(n)"
    }

    // MARK: - Export

    private func generateAndShare() {
        HapticFeedbackService.shared.selection()
        errorMessage = nil
        isGenerating = true

        do {
            let url = try ExportPayloadBuilder.writeExportFile(auth: auth)
            exportURL = url
            isGenerating = false
            showingShareSheet = true
        } catch {
            isGenerating = false
            errorMessage = "Couldn't prepare your export. Please try again.\n(\(error.localizedDescription))"
        }
    }

    /// Remove the temp file once the share sheet closes so exports don't
    /// accumulate in the app's tmp directory.
    private func cleanUpExportFile() {
        if let exportURL {
            try? FileManager.default.removeItem(at: exportURL)
        }
        exportURL = nil
    }
}

// MARK: - Summary model

/// Counts shown in the "What's included" card. Cheap to compute; reflects the
/// same live stores the actual export reads from.
private struct ExportSummary {
    var hasProfile = false
    var hasChart = false
    var journalCount = 0
    var decisionCount = 0
    var ruleCount = 0

    @MainActor
    static func current(auth: AuthState) -> ExportSummary {
        var s = ExportSummary()
        let profile = auth.profileManager.profile
        s.hasProfile = !profile.fullName.isEmpty || profile.birthPlace != nil
        s.hasChart = auth.profileManager.lastChart != nil
        s.journalCount = JournalStore.shared.entries.count
        s.decisionCount = DecisionStore.shared.decisions.count
        s.ruleCount = NavigationRuleStore.shared.rules.count
        return s
    }
}

// MARK: - Payload builder

/// Builds the on-disk JSON export. Kept separate from the view so the
/// serialization is testable and the view stays declarative.
enum ExportPayloadBuilder {

    /// Top-level export document. Encodes to stable, human-readable JSON with
    /// ISO-8601 dates and sorted keys.
    private struct ExportDocument: Encodable {
        let app: String
        let schemaVersion: Int
        let appVersion: String
        let exportedAt: Date
        let isSignedIn: Bool
        let profile: UserProfile
        let latestChart: ChartResponse?
        let journalEntries: [JournalEntry]
        let decisions: [Decision]
        let navigationRules: [NavigationRule]
    }

    enum ExportError: LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Encoding failed"
            }
        }
    }

    /// Gathers the user's local + profile data, encodes it, writes it to a
    /// uniquely named JSON file in the temporary directory, and returns the
    /// file URL for sharing. Runs on the main actor because the Topo stores
    /// are main-actor isolated.
    @MainActor
    static func writeExportFile(auth: AuthState) throws -> URL {
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"

        let document = ExportDocument(
            app: "Astronova",
            schemaVersion: 1,
            appVersion: appVersion,
            exportedAt: Date(),
            isSignedIn: auth.isAuthenticated,
            profile: auth.profileManager.profile,
            latestChart: auth.profileManager.lastChart,
            journalEntries: JournalStore.shared.entries,
            decisions: DecisionStore.shared.decisions,
            navigationRules: NavigationRuleStore.shared.rules
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let data: Data
        do {
            data = try encoder.encode(document)
        } catch {
            throw ExportError.encodingFailed
        }

        let stamp = Self.fileStampFormatter.string(from: Date())
        let filename = "Astronova-Export-\(stamp).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static let fileStampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f
    }()
}
