import SwiftUI

struct TodayTerrainView: View {
    @EnvironmentObject private var auth: AuthState
    @EnvironmentObject private var gamification: GamificationManager
    @State private var snapshot: TerrainSnapshot?
    @State private var dominantPattern: Pattern?
    @State private var dailySignalCard: ArcanaCard?
    @State private var dailySignalIsNew = false
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
                    dashboardSynthesisLead(snapshot)
                    if let dailySignalCard {
                        let chapter = gamification.weeklyChapterProgress
                        DailySignalCardView(
                            card: dailySignalCard,
                            isNewCheckIn: dailySignalIsNew,
                            isTodayComplete: gamification.hasCheckedInToday,
                            streak: gamification.streak,
                            level: gamification.level.title,
                            xp: gamification.xp,
                            weeklyChapterLabel: chapter.label,
                            weeklyChapterFraction: chapter.fraction
                        ) {
                            HapticFeedbackService.shared.mediumImpact()
                            showLogMoment = true
                        }
                    }
                    dashboardSynthesisFollowUp(snapshot)
                    agencyMoveCard(snapshot)
                    logMomentButton
                    readHoroscopeAloudButton(for: snapshot)
                    axesCard(snapshot)
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
        .accessibilityIdentifier("todayTerrainView")
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

    private func dashboardSynthesisLead(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            dashboardGreeting
            archetypeCard
            systemStatusCard(snap)
            todayHypothesisCard(snap)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.dashboard.refreshed")
    }

    private func dashboardSynthesisFollowUp(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            guardrailCard(snap)
            actionQueueCard(snap)
        }
        .accessibilityElement(children: .contain)
    }

    private var dashboardGreeting: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLabel.uppercased())
                    .font(.cosmicCaptionEmphasis)
                    .tracking(2.2)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text("Good evening, \(firstName).")
                    .font(.cosmicTitle3)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            Spacer()
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.cosmicGold, tintColor, Color.cosmicAmethyst],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)
                .overlay(Circle().stroke(Color.cosmicTextPrimary.opacity(0.14), lineWidth: 1))
        }
        .accessibilityIdentifier("today.dashboard.header")
    }

    private var firstName: String {
        let name = auth.profileManager.profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.split(separator: " ").first.map(String.init) ?? "Seeker"
    }

    private var archetypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ARCHETYPE · SYNTHESIS v3")
                .font(.cosmicCaptionEmphasis)
                .tracking(2.2)
                .foregroundStyle(Color.cosmicGold)

            (Text("Sovereign-Creator\n")
                + Text("+ Capital Engine").italic().foregroundColor(Color.cosmicGold))
                .font(.cosmicTitle)
                .foregroundStyle(Color.cosmicTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("You build systems, then turn attention into durable leverage. Today is about one clean signal, one useful response, and one logged loop.")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                synthesisPill("Sun · Leo")
                synthesisPill("Moon · Taurus")
                synthesisPill("Asc · Scorpio")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.cosmicGold.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.archetype.card")
    }

    private func synthesisPill(_ text: String) -> some View {
        Text(text)
            .font(.cosmicCaptionEmphasis)
            .foregroundStyle(Color.cosmicTextSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.cosmicSurface))
            .overlay(Capsule().stroke(Color.cosmicTextPrimary.opacity(0.10), lineWidth: 1))
    }

    private func systemStatusCard(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYSTEM STATUS · LIVE")
                .font(.cosmicCaptionEmphasis)
                .tracking(2.2)
                .foregroundStyle(Color.cosmicTextTertiary)
            HStack(spacing: 10) {
                metricBlock(label: "CURRENT DASHA", value: snap.dasha.map { "\($0.graha) / live" } ?? "Live sky", detail: "active window")
                metricBlock(label: "STRENGTH", value: "0.82", detail: "7 of 9 processes healthy", tint: Color.cosmicSuccess)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cosmicTextPrimary.opacity(0.10), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.systemStatus.live")
    }

    private func metricBlock(label: String, value: String, detail: String, tint: Color = Color.cosmicGold) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.cosmicCaption)
                .tracking(1.4)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(value)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func todayHypothesisCard(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY · HYPOTHESIS")
                .font(.cosmicCaptionEmphasis)
                .tracking(2.2)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text("One useful reply unlocks the next room.")
                .font(.cosmicTitle3)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text(snap.axes.highestAgencyMove)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            timelineStrip
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cosmicGold.opacity(0.16), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.hypothesis.card")
    }

    private var timelineStrip: some View {
        HStack {
            ForEach(["FRI", "SAT", "SUN", "MON", "TUE"], id: \.self) { day in
                Text(day == "SUN" ? "\(day) *" : day)
                    .font(.cosmicCaption)
                    .foregroundStyle(day == "SUN" ? Color.cosmicGold : Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.cosmicVoid.opacity(0.45)))
    }

    private func guardrailCard(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GUARDRAIL · FAILURE MODE")
                .font(.cosmicCaptionEmphasis)
                .tracking(1.8)
                .foregroundStyle(Color.cosmicError)
            Text(snap.axes.avoid)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicError.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cosmicError.opacity(0.24), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.guardrail.card")
    }

    private func actionQueueCard(_ snap: TerrainSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACTION QUEUE")
                    .font(.cosmicCaptionEmphasis)
                    .tracking(2.2)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Spacer()
                Text("3 OPEN")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)
            }
            actionRow(date: "NOW", title: snap.axes.highestAgencyMove, priority: "P1", tint: Color.cosmicGold)
            actionRow(date: "NEXT", title: snap.axes.bestUse, priority: "P1", tint: Color.cosmicSuccess)
            actionRow(date: "AVOID", title: snap.axes.avoid, priority: "P2", tint: Color.cosmicError)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cosmicSurface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cosmicTextPrimary.opacity(0.10), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.actionQueue.card")
    }

    private func actionRow(date: String, title: String, priority: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Text(date)
                .font(.cosmicCaption)
                .foregroundStyle(tint)
                .frame(width: 44, alignment: .leading)
            Text(title)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(2)
            Spacer()
            Text(priority)
                .font(.cosmicCaption)
                .foregroundStyle(tint)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(tint.opacity(0.75), lineWidth: 1))
        }
        .padding(.vertical, 6)
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

    private func agencyMoveCard(_ snap: TerrainSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.cosmicBodyEmphasis)
                .foregroundStyle(Color.cosmicVoid)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tintColor))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("DO THIS NOW")
                    .font(.cosmicMicro)
                    .tracking(1.4)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(snap.axes.highestAgencyMove)
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tintColor.opacity(0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tintColor.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Do this now. \(snap.axes.highestAgencyMove)")
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
        .accessibilityIdentifier("today.logMoment.button")
    }

    private func patternStrip(_ pattern: Pattern) -> some View {
        Button {
            HapticFeedbackService.shared.selection()
            showPatternDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("DOMINANT PATTERN")
                    .font(.cosmicMicro)
                    .tracking(1.4)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(pattern.name)
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(pattern.loop.optimalAction)
                    .font(.cosmicFootnote)
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
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private var footer: some View {
        Text("PAUSE · NAME · ROUTE · USE")
            .font(.cosmicMicro)
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
        loadDailySignal()
        if let id = next.dominantPatternId {
            dominantPattern = TopoContentLoader.shared.pattern(id: id)
        } else {
            dominantPattern = nil
        }

        guard TopoSubstitutionsService.shared.current == nil else { return }
        Task.detached(priority: .utility) {
            _ = TopoSubstitutionsService.shared.awaitCurrent(timeout: 1.5)
            await MainActor.run {
                let refreshed = TerrainComputer.shared.todaysTerrain()
                snapshot = refreshed
                if let id = refreshed.dominantPatternId {
                    dominantPattern = TopoContentLoader.shared.pattern(id: id)
                } else {
                    dominantPattern = nil
                }
            }
        }
    }

    private func loadDailySignal() {
        let dailySignal = gamification.drawTodaysSignal()
        dailySignalCard = dailySignal.card
        dailySignalIsNew = dailySignal.isNewCheckIn
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
            .accessibilityIdentifier("today.logMoment.sheet")
        }
    }

    private var header: some View {
        HStack {
            Text("Log a Moment")
                .font(.cosmicTitle1)
                .foregroundStyle(Color.cosmicTextPrimary)
            Spacer()
            Button {
                HapticFeedbackService.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.cosmicCalloutEmphasis)
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
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .accessibilityIdentifier("today.logMoment.editor")
        }
        .frame(minHeight: 180)
    }

    private var moodSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MOOD")
                    .font(.cosmicMicro)
                    .tracking(1.4)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Spacer()
                Text("\(Int(mood))")
                    .font(.cosmicFootnoteEmphasis)
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
                .font(.cosmicBodyEmphasis)
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
        .accessibilityIdentifier("today.logMoment.save")
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
        .environmentObject(GamificationManager())
}
