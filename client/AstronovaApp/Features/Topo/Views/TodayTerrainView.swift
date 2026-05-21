import SwiftUI

struct TodayTerrainView: View {
    @State private var snapshot: TerrainSnapshot?
    @State private var dominantPattern: Pattern?
    @State private var showPauseLayer = false
    @State private var showLogMoment = false
    @State private var showPatternDetail = false
    @State private var showSettings = false
    @StateObject private var speech = SpeechService.shared

    var body: some View {
        ZStack {
            backdrop
            content
        }
        .task { loadTerrain() }
        .fullScreenCover(isPresented: $showPauseLayer) {
            PauseLayerView()
        }
        .sheet(isPresented: $showLogMoment) {
            LogMomentSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPatternDetail) {
            if let pattern = dominantPattern {
                PatternDetailView(pattern: pattern)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    // MARK: - Layout

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                topBar
                hero
                if let snapshot {
                    readHoroscopeAloudButton(for: snapshot)
                    axesCard(snapshot)
                    logMomentButton
                    if let pattern = dominantPattern {
                        patternStrip(pattern)
                    }
                    if let dasha = snapshot.dasha {
                        dashaStrip(dasha)
                    }
                } else {
                    ProgressView()
                        .tint(Color.cosmicTextPrimary)
                        .padding(.top, 40)
                }
                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .refreshable { loadTerrain() }
    }

    private var backdrop: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            LinearGradient(
                colors: [tintColor.opacity(0.18), Color.cosmicVoid],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Text(dateLabel)
                .font(.cosmicFootnoteEmphasis)
                .foregroundStyle(Color.cosmicTextSecondary)
                .tracking(0.5)
            Spacer()
            Button {
                HapticFeedbackService.shared.lightImpact()
                showPauseLayer = true
            } label: {
                Image(systemName: "pause.circle")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .accessibilityLabel("Pause")
            .accessibilityHint("Opens the pause protocol")
            Button {
                HapticFeedbackService.shared.lightImpact()
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings, including subscription and reports")
        }
        .padding(.top, 4)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.cosmicHero)
                .foregroundStyle(Color.cosmicTextPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Wave 3b A4 — "Read horoscope aloud" button.
    /// Synthesizes a short narration from the day's terrain axes and pipes it
    /// through `SpeechService`. Re-wired into TodayTerrainView after the
    /// TopoSelf redesign sunset the legacy HomeView (see launch-artifacts
    /// /feedback-design-wave-2026-05-18.md §0.3).
    private func readHoroscopeAloudButton(for snap: TerrainSnapshot) -> some View {
        let body = composeReadAloudBody(for: snap)
        return Button {
            HapticFeedbackService.shared.selection()
            if speech.isSpeaking {
                speech.stop()
            } else {
                speech.speak(body)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: speech.isSpeaking
                      ? "stop.circle.fill"
                      : "speaker.wave.2.fill")
                    .font(.cosmicBodyEmphasis)
                Text(speech.isSpeaking ? "Stop reading" : "Read horoscope aloud")
                    .font(.cosmicCalloutEmphasis)
                Spacer()
            }
            .foregroundStyle(Color.cosmicGold)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.cosmicGold.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.readHoroscopeAloud")
        .accessibilityLabel(speech.isSpeaking
                            ? "Stop reading horoscope"
                            : "Read horoscope aloud")
        .accessibilityHint("Uses voice synthesis to narrate today's terrain")
    }

    /// Glue today's axes into a coherent sentence we can hand to TTS.
    private func composeReadAloudBody(for snap: TerrainSnapshot) -> String {
        let segments = [
            "Today's weather. \(snap.axes.currentWeather)",
            "Your most likely default. \(snap.axes.mostLikelyDefault)",
            "Highest agency move. \(snap.axes.highestAgencyMove)"
        ].filter { !$0.isEmpty }
        return segments.joined(separator: " ")
    }

    private func axesCard(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            axisRow(caption: "CURRENT WEATHER", body: snap.axes.currentWeather, size: 17)
            divider
            axisRow(caption: "MOST LIKELY DEFAULT", body: snap.axes.mostLikelyDefault, size: 17)
            divider
            axisRow(caption: "HIGHEST AGENCY MOVE", body: snap.axes.highestAgencyMove, size: 17, dotted: true)
            divider
            axisRow(caption: "BEST USE", body: snap.axes.bestUse, size: 15)
            divider
            axisRow(caption: "AVOID", body: snap.axes.avoid, size: 15)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tintColor.opacity(0.35), lineWidth: 1)
        )
    }

    private func axisRow(caption: String, body: String, size: CGFloat, dotted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.cosmicMicro)
                .tracking(1.4)
                .foregroundStyle(Color.cosmicTextTertiary)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 10) {
                if dotted {
                    Circle().fill(tintColor).frame(width: 8, height: 8).padding(.top, 7)
                        .accessibilityHidden(true)
                }
                // size argument (15/17) is preserved as a relative weighting
                // hint — we map the *larger* legacy 17pt rows to cosmicBody and
                // the smaller 15pt rows to cosmicCallout. Both scale with the
                // user's Dynamic Type preference, unlike the prior
                // Font.system(size:) calls which were fixed.
                Text(body)
                    .font(size >= 17 ? .cosmicBody : .cosmicCallout)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption). \(body)")
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.cosmicTextTertiary.opacity(0.15))
            .frame(height: 1)
    }

    private var logMomentButton: some View {
        Button {
            HapticFeedbackService.shared.mediumImpact()
            showLogMoment = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.cosmicFootnoteEmphasis)
                Text("Log a Moment")
                    .font(.cosmicBodyEmphasis)
            }
            .foregroundStyle(Color.cosmicVoid)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cosmicTextPrimary)
            )
        }
        .buttonStyle(.plain)
    }

    private func patternStrip(_ pattern: Pattern) -> some View {
        Button {
            HapticFeedbackService.shared.selection()
            showPatternDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("DOMINANT PATTERN")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(pattern.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(pattern.loop.optimalAction)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cosmicSurfaceSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private func dashaStrip(_ dasha: DashaOverlay) -> some View {
        let ctx = truncated(dasha.context, max: 80)
        return HStack(spacing: 8) {
            Circle()
                .fill(planetTint(for: dasha.graha))
                .frame(width: 5, height: 5)
            Text("in \(dasha.graha) dasha — \(ctx)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.cosmicTextTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private var footer: some View {
        Text("PAUSE · NAME · ROUTE · USE")
            .font(.system(size: 10, weight: .medium))
            .tracking(2.5)
            .foregroundStyle(Color.cosmicTextTertiary.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
    }

    // MARK: - Derived

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE · MMM d"
        return formatter.string(from: snapshot?.date ?? Date()).uppercased()
    }

    private var subtitle: String {
        guard let snap = snapshot else { return "Reading the sky…" }
        var parts = snap.drivers.map { $0.label }
        if let dasha = snap.dasha {
            parts.append("\(dasha.graha) dasha")
        }
        return parts.isEmpty ? "Conditions normal" : parts.joined(separator: " + ")
    }

    private var tintColor: Color {
        if let pattern = dominantPattern,
           let planet = pattern.westernDrivers.first?.planet ?? pattern.vedicDrivers.first?.graha {
            return planetTint(for: planet)
        }
        if let graha = snapshot?.dasha?.graha {
            return planetTint(for: graha)
        }
        return Color.cosmicAccent
    }

    // MARK: - Actions

    private func loadTerrain() {
        let next = TerrainComputer.shared.todaysTerrain()
        snapshot = next
        if let id = next.dominantPatternId {
            dominantPattern = TopoContentLoader.shared.pattern(id: id)
        } else {
            dominantPattern = nil
        }
    }

    private func truncated(_ text: String, max: Int) -> String {
        guard text.count > max else { return text }
        let idx = text.index(text.startIndex, offsetBy: max)
        return text[..<idx].trimmingCharacters(in: .whitespaces) + "…"
    }
}

// MARK: - Log a Moment sheet

private struct LogMomentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var mood: Double = 50

    var body: some View {
        ZStack {
            Color.cosmicVoid.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                header
                editor
                moodSlider
                Spacer(minLength: 0)
                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
    }

    private var header: some View {
        HStack {
            Text("Log a Moment")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.cosmicTextPrimary)
            Spacer()
            Button {
                HapticFeedbackService.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cosmicSurface)
            if text.isEmpty {
                Text("What just happened?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.cosmicTextPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
        }
        .frame(minHeight: 180)
    }

    private var moodSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MOOD")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Spacer()
                Text("\(Int(mood))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .monospacedDigit()
            }
            Slider(value: $mood, in: 0...100, step: 1) {
                Text("Mood")
            }
            .tint(Color.cosmicGold)
            .onChange(of: mood) { _, _ in
                HapticFeedbackService.shared.selection()
            }
        }
        .padding(.horizontal, 4)
    }

    private var saveButton: some View {
        Button {
            Task { @MainActor in save() }
        } label: {
            Text("Save")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.cosmicVoid)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(canSave ? Color.cosmicTextPrimary : Color.cosmicTextTertiary.opacity(0.35))
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func save() {
        let entry = JournalEntry(
            whatHappened: text.trimmingCharacters(in: .whitespacesAndNewlines),
            moodBefore: Int(mood)
        )
        JournalStore.shared.add(entry)
        HapticFeedbackService.shared.success()
        dismiss()
    }
}

#Preview {
    TodayTerrainView()
}
