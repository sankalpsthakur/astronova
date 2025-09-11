import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum ZodiacSystem: String, CaseIterable, Identifiable {
    case western = "Western"
    case vedic = "Vedic"
    var id: String { rawValue }
}

struct DashasResponse: Codable {
    struct Period: Codable { let lord: String; let start: String?; let end: String?; let annotation: String }
    let mahadasha: Period
    let antardasha: Period
}

struct TimeTravelView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var planets: [DetailedPlanetaryPosition] = []
    @State private var dashas: DashasResponse?
    @State private var isLoading = false
    @State private var aspects: [Aspect] = []
    @State private var lastMahadashaLord: String?
    @State private var showInsightChip: Bool = false
    @State private var stickyTargets: Set<Int> = [] // years that contain dasha boundaries
    @State private var planetAnimVersion: Int = 0
    @State private var zodiacSystem: ZodiacSystem = .western

    private let api = APIServices.shared
    private let yearRange = (1900...2100)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                // Year slider (sticky to Dasha boundaries) + system toggle
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Year")
                            .font(.headline)
                        Spacer()
                        Text("\(selectedYear)")
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                    }
                    Picker("Zodiac", selection: $zodiacSystem) {
                        Text("Western").tag(ZodiacSystem.western)
                        Text("Vedic").tag(ZodiacSystem.vedic)
                    }
                    .pickerStyle(.segmented)
                    Slider(
                        value: yearBinding,
                        in: Double(yearRange.lowerBound)...Double(yearRange.upperBound),
                        step: 1,
                        onEditingChanged: { editing in
                            if !editing { snapToNearbyDashaBoundary() }
                        }
                    )
                }
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Computing planetary positions…")
                        .padding()
                }
                
                // Planetary Visual
                PlanetariumCanvasView(planets: planets, dasha: dashas, year: selectedYear, mode: zodiacSystem)
                    .frame(height: 320)
                    .padding(.horizontal)
                    // Animations can be reintroduced after stabilizing type-checker
                    .overlay(alignment: .top) {
                        if showInsightChip, let d = dashas, let end = d.mahadasha.end, let endDate = isoDate(end) {
                            InlineInsightChip(text: "\(d.mahadasha.lord) period until \(displayMonthYear(endDate)). Tap for glossary.") {
                                showGlossary.toggle()
                            }
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                // Planet list (scrolls with the page)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(planets) { p in
                        HStack(spacing: 12) {
                            Text(p.symbol)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(p.name)
                                    .font(.headline)
                                Text("\(p.sign) \(String(format: "%.2f°", p.degree))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if p.retrograde {
                                Text("℞")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal)
                        Divider()
                            .padding(.leading, 44)
                    }
                }

                // Dashas panel
                if let d = dashas {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vimshottari Dashas")
                            .font(.headline)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Mahadasha: \(d.mahadasha.lord)")
                                    .font(.subheadline.weight(.semibold))
                                Text(d.mahadasha.annotation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Antardasha: \(d.antardasha.lord)")
                                    .font(.subheadline.weight(.semibold))
                                Text(d.antardasha.annotation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let info = dashaRangeAndProgress(for: selectedYear) {
                            DashaRingView(
                                mahadasha: d.mahadasha.lord,
                                antardasha: d.antardasha.lord,
                                progress: info.progress
                            )
                            .frame(width: 120, height: 120)
                            .padding(.top, 6)
                            Text("\(displayMonthYear(info.start)) → \(displayMonthYear(info.end))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                } else {
                    // Prompt to enable Dashas if profile incomplete
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.purple)
                            Text("Add your birth details to see Dashas for any year")
                                .font(.subheadline)
                        }
                        Button {
                            NotificationCenter.default.post(name: .switchToTab, object: 4)
                            NotificationCenter.default.post(name: .switchToProfileSection, object: 0)
                        } label: {
                            Label("Complete Profile", systemImage: "person.crop.circle.badge.plus")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Aspects panel
                if !aspects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aspects")
                            .font(.headline)
                        ForEach(Array(aspects.prefix(8).enumerated()), id: \.offset) { _, a in
                            HStack {
                                Text("\(a.planet1.capitalized) – \(a.planet2.capitalized)")
                                Spacer()
                                Text("\(a.type.capitalized) (orb \(String(format: "%.1f", a.orb)))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                }
                .padding(.vertical)
            }
            .navigationTitle("Time Travel")
            .task { await loadData() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGlossary.toggle()
                    } label: {
                        Label("Planet Impacts", systemImage: "book")
                    }
                    .accessibilityLabel("Planet impacts glossary")
                }
            }
            .sheet(isPresented: $showGlossary) {
                InlinePlanetImpactGlossaryView(activeMahadasha: dashas?.mahadasha.lord, activeAntardasha: dashas?.antardasha.lord)
            }
            .onChange(of: zodiacSystem) { _ in
                Task { await loadData() }
            }
        }
    }
    
    private func loadData() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        do {
            // Build date for Jan 1 of selected year
            var comps = DateComponents()
            comps.year = selectedYear
            comps.month = 1
            comps.day = 1
            let date = Calendar.current.date(from: comps) ?? Date()
            
            // Fetch planetary positions
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateStr = dateFormatter.string(from: date)
            
            struct PlanetaryDataResponse: Codable { let planets: [DetailedPlanetaryPosition] }
            var endpoint = "/api/v1/ephemeris/at?date=\(dateStr)"
            if zodiacSystem == .vedic { endpoint += "&system=vedic" }
            let response: PlanetaryDataResponse = try await api.directGET(
                endpoint: endpoint,
                responseType: PlanetaryDataResponse.self
            )
            await MainActor.run { planets = response.planets; planetAnimVersion &+= 1 }
            
            // Fetch dashas based on profile if available
            if let bd = try? BirthData(from: auth.profileManager.profile) {
                // Build encoded URL to avoid issues with timezone or time formats
                var comps = URLComponents()
                comps.path = "/api/v1/astrology/dashas"
                comps.queryItems = [
                    URLQueryItem(name: "birth_date", value: bd.date),
                    URLQueryItem(name: "birth_time", value: bd.time),
                    URLQueryItem(name: "timezone", value: bd.timezone),
                    URLQueryItem(name: "target_date", value: dateStr),
                    URLQueryItem(name: "lat", value: String(bd.latitude)),
                    URLQueryItem(name: "lon", value: String(bd.longitude))
                ]
                let dashaEndpoint = comps.path + "?" + (comps.percentEncodedQuery ?? comps.query ?? "")
                let d: DashasResponse = try await api.directGET(
                    endpoint: dashaEndpoint,
                    responseType: DashasResponse.self
                )
                // Update dasha, sticky targets and insight chip
                await MainActor.run {
                    let previous = lastMahadashaLord
                    dashas = d
                    lastMahadashaLord = d.mahadasha.lord
                    updateStickyTargets()
                    if let prev = previous, prev != d.mahadasha.lord {
                        hapticInsight()
                        withAnimation(.spring()) { showInsightChip = true }
                        // Auto-hide after a moment
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeInOut) { showInsightChip = false }
                        }
                    }
                }
            } else {
                await MainActor.run { dashas = nil }
            }

            // Fetch aspects for date
            let asp: [Aspect] = try await api.directGET(
                endpoint: "/api/v1/chart/aspects?date=\(dateStr)",
                responseType: [Aspect].self
            )
            await MainActor.run { aspects = asp }
        } catch {
            // Fallback: compute approximate positions locally and synthesize simple dashas
            var comps = DateComponents(); comps.year = selectedYear; comps.month = 1; comps.day = 1
            let date = Calendar.current.date(from: comps) ?? Date()
            let fallback = computeFallbackPositions(for: date)
            await MainActor.run {
                self.planets = fallback
                self.aspects = []
                // Always recompute fallback dashas so they update with year changes
                let previous = self.lastMahadashaLord
                let synthesized = synthesizeDashas(for: date)
                self.dashas = synthesized
                self.lastMahadashaLord = synthesized.mahadasha.lord
                self.updateStickyTargets()
                if let prev = previous, prev != synthesized.mahadasha.lord {
                    hapticInsight()
                    withAnimation(.spring()) { showInsightChip = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut) { showInsightChip = false }
                    }
                }
                self.planetAnimVersion &+= 1
            }
        }
    }
    
    private func computeFallbackPositions(for date: Date) -> [DetailedPlanetaryPosition] {
        // Deterministic, offline-friendly approximation based on year and simple speeds
        let year = Double(Calendar.current.component(.year, from: date))
        let speeds: [String: Double] = [
            "Sun": 360.0,
            "Mercury": 1400.0,
            "Venus": 1200.0,
            "Mars": 500.0,
            "Jupiter": 30.0,
            "Saturn": 12.0,
            "Uranus": 4.0,
            "Neptune": 2.0
        ]
        let offsets: [String: Double] = [
            "Sun": 0, "Mercury": 45, "Venus": 90, "Mars": 135,
            "Jupiter": 180, "Saturn": 225, "Uranus": 270, "Neptune": 315
        ]
        let names = ["Sun", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
        return names.map { name in
            let speed = speeds[name] ?? 10.0
            let offset = offsets[name] ?? 0.0
            let longitude = fmod(year * speed + offset, 360.0)
            let (sign, deg) = signAndDegree(from: longitude < 0 ? longitude + 360.0 : longitude)
            return DetailedPlanetaryPosition(
                id: name.lowercased(),
                symbol: symbol(for: name),
                name: name,
                sign: sign,
                degree: deg,
                retrograde: false,
                house: nil,
                significance: nil
            )
        }
    }

    private func signAndDegree(from eclipticLongitude: Double) -> (String, Double) {
        let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
        let normalized = (eclipticLongitude.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let index = Int(floor(normalized / 30.0)) % 12
        let degree = normalized - Double(index) * 30.0
        return (signs[index], degree)
    }

    private func symbol(for planet: String) -> String {
        switch planet {
        case "Sun": return "☉"
        case "Mercury": return "☿"
        case "Venus": return "♀"
        case "Mars": return "♂"
        case "Jupiter": return "♃"
        case "Saturn": return "♄"
        case "Uranus": return "♅"
        case "Neptune": return "♆"
        default: return "●"
        }
    }

    private func synthesizeDashas(for date: Date) -> DashasResponse {
        let lords = ["Ketu","Venus","Sun","Moon","Mars","Rahu","Jupiter","Saturn","Mercury"]
        let year = Calendar.current.component(.year, from: date)
        let mahadasha = lords[year % lords.count]
        let antardasha = lords[(year / 3) % lords.count]
        return DashasResponse(
            mahadasha: .init(lord: mahadasha, start: nil, end: nil, annotation: "Approximate period (offline)"),
            antardasha: .init(lord: antardasha, start: nil, end: nil, annotation: "Approximate sub-period")
        )
    }

    // MARK: - Sticky + Helpers

    @State private var showGlossary = false

    private func isoDate(_ s: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .init(secondsFromGMT: 0)
        return f.date(from: s)
    }

    private func displayMonthYear(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f.string(from: d)
    }

    private func progressFraction(for start: Date, end: Date, year: Int) -> Double {
        var comps = DateComponents(); comps.year = year; comps.month = 1; comps.day = 1
        let ref = Calendar.current.date(from: comps) ?? Date()
        let total = max(1.0, end.timeIntervalSince(start))
        let elapsed = max(0.0, min(total, ref.timeIntervalSince(start)))
        return elapsed / total
    }

    private var yearBinding: Binding<Double> {
        Binding(
            get: { Double(selectedYear) },
            set: { newVal in
                let newYear = Int(newVal.rounded())
                if newYear != selectedYear {
                    selectedYear = newYear
                    Task { await loadData() }
                }
            }
        )
    }

    private func dashaRangeAndProgress(for year: Int) -> (start: Date, end: Date, progress: Double)? {
        guard let d = dashas, let s = d.mahadasha.start, let e = d.mahadasha.end,
              let sd = isoDate(s), let ed = isoDate(e) else { return nil }
        return (sd, ed, progressFraction(for: sd, end: ed, year: year))
    }

    private func updateStickyTargets() {
        guard let d = dashas, let s = d.mahadasha.start, let e = d.mahadasha.end, let sd = isoDate(s), let ed = isoDate(e) else {
            stickyTargets = []
            return
        }
        let y1 = Calendar.current.component(.year, from: sd)
        let y2 = Calendar.current.component(.year, from: ed)
        stickyTargets = [y1, y2]
    }

    private func snapToNearbyDashaBoundary() {
        guard !stickyTargets.isEmpty else { return }
        // If close to a boundary year (within +/- 0), snap to that exact year
        if stickyTargets.contains(selectedYear) {
            // Already at a boundary year; emphasize with haptic
            hapticSelection()
            return
        }
        // If we are one year away from boundary and the end is in early/late year, snap to boundary year
        if stickyTargets.contains(selectedYear + 1) || stickyTargets.contains(selectedYear - 1) {
            hapticSelection()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if stickyTargets.contains(selectedYear + 1) { selectedYear += 1 } else { selectedYear -= 1 }
            }
            Task { await loadData() }
        }
    }

    private func hapticSelection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    private func hapticInsight() {
        #if canImport(UIKit)
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        #endif
    }
}

// Uses Aspect defined in APIModels.swift

// MARK: - Planetary Visuals (Canvas renderer)

struct PlanetariumCanvasView: View {
    let planets: [DetailedPlanetaryPosition]
    let dasha: DashasResponse?
    let year: Int
    let mode: ZodiacSystem
    
    private let order: [String] = ["Mercury","Venus","Sun","Mars","Jupiter","Saturn","Uranus","Neptune"]
    private let colors: [String: Color] = [
        "Sun": .yellow,
        "Mercury": .gray,
        "Venus": .pink,
        "Mars": .red,
        "Jupiter": .orange,
        "Saturn": .brown,
        "Uranus": .teal,
        "Neptune": .indigo
    ]
    private static let westernSigns = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
    private static let vedicSigns = ["Mesha","Vrishabha","Mithuna","Karka","Simha","Kanya","Tula","Vrischika","Dhanu","Makara","Kumbha","Meena"]
    
    var body: some View {
        ZStack {
            // Background gradient + faint stars
            LinearGradient(colors: [.black.opacity(0.9), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            Canvas { context, size in
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let maxR = min(size.width, size.height) / 2 - 18

                drawStarfield(&context, size: size)
                drawZodiac(&context, center: center, ringR: maxR)
                drawOrbitGuides(&context, center: center, maxR: maxR)
                drawPlanets(&context, center: center, maxR: maxR)
            }

            // Dasha inline label
            VStack(spacing: 4) {
                if let d = dasha {
                    Text("Mahadasha: \(d.mahadasha.lord) • Antardasha: \(d.antardasha.lord)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.08), in: Capsule())
                } else {
                    Text("Add birth details for precise Dashas")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(6)
                        .background(.white.opacity(0.06), in: Capsule())
                }
            }
        }
    }

    // MARK: - Canvas helpers
    private func drawStarfield(_ context: inout GraphicsContext, size: CGSize) {
        var starPath = Path()
        var x = 10.0
        while x < Double(size.width) {
            var y = 8.0
            while y < Double(size.height) {
                starPath.addEllipse(in: CGRect(x: x, y: y, width: 1.2, height: 1.2))
                y += 24.0
            }
            x += 28.0
        }
        context.stroke(starPath, with: .color(.white.opacity(0.12)))
    }

    private func drawZodiac(_ context: inout GraphicsContext, center: CGPoint, ringR: CGFloat) {
        var ring = Path()
        ring.addEllipse(in: CGRect(x: center.x - ringR, y: center.y - ringR, width: ringR*2, height: ringR*2))
        context.stroke(ring, with: .color(.white.opacity(0.25)))

        for i in 0..<12 {
            let angle = CGFloat((Double(i)*30.0 - 90) * .pi/180)
            let inner = CGPoint(x: center.x + (ringR-10)*cos(angle), y: center.y + (ringR-10)*sin(angle))
            let outer = CGPoint(x: center.x + (ringR+6)*cos(angle), y: center.y + (ringR+6)*sin(angle))
            var tick = Path(); tick.move(to: inner); tick.addLine(to: outer)
            let lw: CGFloat = (i % 3 == 0) ? 2.0 : 1.0
            context.stroke(tick, with: .color(.white.opacity(0.35)), lineWidth: lw)

            // Dual-friendly labels: Western + Vedic
            let midAngle = CGFloat(((Double(i)*30.0 + 15.0) - 90) * .pi/180)
            let outerR = ringR + 20
            let innerR = ringR + 10
            let posOuter = CGPoint(x: center.x + outerR*cos(midAngle), y: center.y + outerR*sin(midAngle))
            let posInner = CGPoint(x: center.x + innerR*cos(midAngle), y: center.y + innerR*sin(midAngle))
            let west = String(Self.westernSigns[i].prefix(3))
            let vedi = String(Self.vedicSigns[i].prefix(3))
            let t1 = Text(west).font(.system(size: 8, weight: .semibold))
            let t2 = Text(vedi).font(.system(size: 7, weight: .regular))
            context.draw(t1, at: posOuter, anchor: .center)
            context.draw(t2, at: posInner, anchor: .center)
        }
    }

    private func orbitRadius(index: Int, maxR: CGFloat) -> CGFloat {
        maxR * (0.25 + 0.7 * CGFloat(index+1)/CGFloat(order.count))
    }

    private func drawOrbitGuides(_ context: inout GraphicsContext, center: CGPoint, maxR: CGFloat) {
        for idx in order.indices {
            let r = orbitRadius(index: idx, maxR: maxR)
            var o = Path(); o.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r*2, height: r*2))
            let style = StrokeStyle(lineWidth: 1, dash: [3,3])
            context.stroke(o, with: .color(.white.opacity(0.15)), style: style)
        }
    }

    private func drawPlanets(_ context: inout GraphicsContext, center: CGPoint, maxR: CGFloat) {
        for p in visiblePlanets() {
            let idx = (order.firstIndex(of: p.name) ?? 0)
            let r = orbitRadius(index: idx, maxR: maxR)
            let angle = angleFor(sign: p.sign, degree: p.degree)
            let pos = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            let sizePx: CGFloat = 10 + CGFloat(idx) * 1.4
            let rect = CGRect(x: pos.x - sizePx/2, y: pos.y - sizePx/2, width: sizePx, height: sizePx)
            let path = Path(ellipseIn: rect)
            let shading: GraphicsContext.Shading = .radialGradient(
                Gradient(colors: [colors[p.name] ?? .white, .white.opacity(0.0)]),
                center: pos,
                startRadius: 0,
                endRadius: sizePx
            )
            context.fill(path, with: shading)
            context.stroke(path, with: .color(.white.opacity(0.25)))

            let text = Text(p.symbol).font(.system(size: 9))
            let label = CGPoint(x: pos.x, y: pos.y - sizePx)
            context.draw(text, at: label, anchor: .center)
        }
    }
    
    private func visiblePlanets() -> [DetailedPlanetaryPosition] {
        let allowed = Set(order)
        return planets.filter { allowed.contains($0.name) }
    }
    
    private func angleFor(sign: String, degree: Double) -> CGFloat {
        // Determine index based on selected zodiac system but be resilient to server naming
        let idx: Int = {
            if mode == .vedic {
                if let i = Self.vedicSigns.firstIndex(where: { $0.caseInsensitiveCompare(sign) == .orderedSame }) { return i }
                if let i = Self.westernSigns.firstIndex(where: { $0.caseInsensitiveCompare(sign) == .orderedSame }) { return i }
            } else {
                if let i = Self.westernSigns.firstIndex(where: { $0.caseInsensitiveCompare(sign) == .orderedSame }) { return i }
                if let i = Self.vedicSigns.firstIndex(where: { $0.caseInsensitiveCompare(sign) == .orderedSame }) { return i }
            }
            return 0
        }()
        let base = Double(idx) * 30.0 + degree
        // Place 0° Aries/Mesha at top and progress clockwise
        let radians = (base - 90) * .pi / 180
        return CGFloat(radians)
    }
    
    private func point(on center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

struct DashaRingView: View {
    let lords = ["Ketu","Venus","Sun","Moon","Mars","Rahu","Jupiter","Saturn","Mercury"]
    let mahadasha: String
    let antardasha: String
    var progress: Double = 0.0 // 0..1 along the current Mahadasha
    
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: 10)
            
            // Segments
            ForEach(lords.indices, id: \.self) { i in
                let start = Angle(degrees: Double(i) * (360.0 / 9.0) - 90)
                let end = Angle(degrees: Double(i+1) * (360.0 / 9.0) - 90)
                let lord = lords[i]
                Circle()
                    .trim(from: CGFloat(i)/9.0, to: CGFloat(i+1)/9.0)
                    .stroke(color(for: lord).opacity(0.6), style: StrokeStyle(lineWidth: lord == mahadasha ? 8 : 4))
                    .rotationEffect(.degrees(-90))
                
                // Labels
                let labelPos = labelPosition(radius: 48, start: start, end: end)
                Text(String(lord.prefix(3)))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(lord == antardasha ? .white : .white.opacity(0.7))
                    .position(labelPos)
            }

            // Progress comet along active Mahadasha
            let idx = lords.firstIndex(of: mahadasha) ?? 0
            let from = Double(idx)/9.0
            let to = Double(idx+1)/9.0
            let t = from + (to - from) * min(max(progress, 0.0), 1.0)
            Circle()
                .trim(from: CGFloat(t-0.001), to: CGFloat(t))
                .stroke(color(for: mahadasha), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
    
    private func color(for lord: String) -> Color {
        switch lord {
        case "Sun": return .yellow
        case "Moon": return .cyan
        case "Mars": return .red
        case "Mercury": return .green
        case "Jupiter": return .orange
        case "Venus": return .pink
        case "Saturn": return .brown
        case "Rahu": return .purple
        case "Ketu": return .indigo
        default: return .white
        }
    }
    
    private func labelPosition(radius: CGFloat, start: Angle, end: Angle) -> CGPoint {
        let mid = Angle(degrees: (start.degrees + end.degrees) / 2)
        return CGPoint(x: 60 + radius * cos(CGFloat(mid.radians)), y: 60 + radius * sin(CGFloat(mid.radians)))
    }
}

// MARK: - Inline lightweight components (avoid target membership issues)

struct InlineInsightChip: View {
    let text: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles").foregroundStyle(.yellow)
            Text(text).font(.caption).foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
        .onTapGesture { action?() }
        .accessibilityAddTraits(.isButton)
    }
}

struct InlinePlanetImpactGlossaryView: View {
    var activeMahadasha: String?
    var activeAntardasha: String?
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private struct Item: Identifiable { let id = UUID(); let name: String; let symbol: String; let summary: String }
    private var items: [Item] {
        let base: [Item] = [
            .init(name: "Sun", symbol: "☉", summary: "Identity, vitality, leadership, purpose."),
            .init(name: "Moon", symbol: "☽", summary: "Emotions, intuition, home, needs."),
            .init(name: "Mars", symbol: "♂", summary: "Drive, action, courage, will."),
            .init(name: "Mercury", symbol: "☿", summary: "Thinking, speech, learning, commerce."),
            .init(name: "Jupiter", symbol: "♃", summary: "Growth, wisdom, generosity, faith."),
            .init(name: "Venus", symbol: "♀", summary: "Love, beauty, values, pleasure."),
            .init(name: "Saturn", symbol: "♄", summary: "Structure, mastery, patience, responsibility."),
            .init(name: "Rahu", symbol: "☊", summary: "Ambition, innovation, obsession, disruption."),
            .init(name: "Ketu", symbol: "☋", summary: "Release, insight, spirituality, detachment.")
        ]
        if query.isEmpty { return base }
        let q = query.lowercased()
        return base.filter { $0.name.lowercased().contains(q) || $0.summary.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            List(items) { p in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(p.symbol).font(.title3)
                        Text(p.name).font(.headline)
                        if p.name == activeMahadasha || p.name == activeAntardasha {
                            Text("active")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                    Text(p.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Planet Impacts")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
