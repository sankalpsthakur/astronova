import SwiftUI
import Combine
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
    @State private var isLoading = false
    @State private var aspects: [Aspect] = []
    @State private var planetAnimVersion: Int = 0
    @State private var zodiacSystem: ZodiacSystem = .western

    // Local algorithmic animation (no API)
    @State private var isAnimatingLocal = true
    @State private var daysPerSecond: Double = 10 // base speed
    @State private var simulationDate: Date = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 1, day: 1)) ?? Date()
    @State private var simTick: Int = 0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private let yearRange = (1900...2100)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                // Year slider + controls
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Year")
                            .font(.headline)
                        Spacer()
                        Text("\(selectedYear)")
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                    }
                    HStack(spacing: 12) {
                        // Play / Pause
                        Button {
                            isAnimatingLocal = true
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            isAnimatingLocal = false
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            // Increase speed and jump one month forward
                            daysPerSecond = min(daysPerSecond * 2, 320)
                            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: simulationDate) {
                                simulationDate = newDate
                                let frame = computeLocalPositions(for: simulationDate)
                                let asp = computeLocalAspects(for: simulationDate)
                                planets = frame
                                aspects = asp
                                let newY = Calendar.current.component(.year, from: simulationDate)
                                if newY != selectedYear { selectedYear = newY }
                                planetAnimVersion &+= 1
                            }
                        } label: {
                            Label("Speed +", systemImage: "forward.end.fill")
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                        Text("\(displayMonthYear(simulationDate))")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.secondary)
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
                        onEditingChanged: { _ in }
                    )
                }
                .padding(.horizontal)
                
                // Planetary Visual
                PlanetariumCanvasView(planets: planets, dasha: nil, year: selectedYear, mode: zodiacSystem, showDashaOverlay: false)
                    .frame(height: 320)
                    .padding(.horizontal)

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
                // Dashas section removed for local-only mode

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
            .task { await loadData(resetSim: true) }
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
                InlinePlanetImpactGlossaryView(activeMahadasha: nil, activeAntardasha: nil)
            }
            .onChange(of: zodiacSystem) { _, _ in
                Task { await loadData() }
            }
            .onReceive(timer) { _ in
                guard isAnimatingLocal else { return }
                // Advance simulation based on speed (days/sec)
                simTick &+= 1
                let dt: TimeInterval = 0.05 * 24 * 3600 * max(0.1, daysPerSecond)
                simulationDate.addTimeInterval(dt)
                let frame = computeLocalPositions(for: simulationDate)
                let asp = computeLocalAspects(for: simulationDate)
                planets = frame
                aspects = asp
                let newY = Calendar.current.component(.year, from: simulationDate)
                if newY != selectedYear { selectedYear = newY }
                planetAnimVersion &+= 1
            }
        }
    }
    
    private func loadData(resetSim: Bool = false) async {
        await MainActor.run {
            let base = Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? Date()
            if resetSim { simulationDate = base; simTick = 0 }
            planets = computeLocalPositions(for: base)
            aspects = computeLocalAspects(for: base)
            isLoading = false
        }
    }

    // MARK: - Local algorithmic positions (no API)
    private func computeLocalPositions(for date: Date) -> [DetailedPlanetaryPosition] {
        // Simple deterministic orbital model (approximate mean motion)
        let epoch = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2000, month: 1, day: 1).date ?? Date(timeIntervalSince1970: 946684800)
        let days = date.timeIntervalSince(epoch) / (24*3600)
        
        // deg/day mean motions
        let rate: [String: Double] = [
            "Sun": 0.9856,      // 365.24 d
            "Moon": 13.1764,    // synodic ~29.53 d
            "Mercury": 4.0923,  // 87.97 d
            "Venus": 1.6021,    // 224.70 d
            "Mars": 0.5240,     // 686.98 d
            "Jupiter": 0.0831,  // 4332.6 d
            "Saturn": 0.0335,   // 10759 d
            "Uranus": 0.0117,   // 30685 d
            "Neptune": 0.0060   // 60190 d
        ]
        // Visual spacing offsets
        let offset: [String: Double] = [
            "Sun": 0, "Moon": 120, "Mercury": 45, "Venus": 90, "Mars": 135,
            "Jupiter": 180, "Saturn": 225, "Uranus": 270, "Neptune": 315
        ]
        
        func norm(_ x: Double) -> Double { var v = x.truncatingRemainder(dividingBy: 360); if v < 0 { v += 360 }; return v }
        func signAndDegree(from lon: Double) -> (String, Double) {
            let signs = ["Aries","Taurus","Gemini","Cancer","Leo","Virgo","Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"]
            let n = norm(lon)
            let idx = Int(n / 30.0) % 12
            let deg = n - Double(idx)*30.0
            return (signs[idx], deg)
        }
        func isRetrograde(_ name: String, day: Double) -> Bool {
            // Crude periodic retrograde simulation for visual cue
            switch name {
            case "Mercury": return cos(2 * .pi * day / 116.0) < -0.6
            case "Mars": return cos(2 * .pi * day / 780.0) < -0.8
            case "Jupiter": return cos(2 * .pi * day / 399.0) < -0.8
            case "Saturn": return cos(2 * .pi * day / 378.0) < -0.8
            default: return false
            }
        }
        
        let defs: [(String,String,String)] = [
            ("Sun","sun","☉"),("Moon","moon","☽"),("Mercury","mercury","☿"),("Venus","venus","♀"),("Mars","mars","♂"),("Jupiter","jupiter","♃"),("Saturn","saturn","♄"),("Uranus","uranus","♅"),("Neptune","neptune","♆")
        ]
        return defs.map { (name,id,symbol) in
            let lon = norm((rate[name] ?? 0.5) * days + (offset[name] ?? 0))
            let sd = signAndDegree(from: lon)
            return DetailedPlanetaryPosition(
                id: id,
                symbol: symbol,
                name: name,
                sign: sd.0,
                degree: sd.1,
                retrograde: isRetrograde(name, day: days),
                house: nil,
                significance: planetImpact(name)
            )
        }
    }

    private func computeLocalAspects(for date: Date) -> [Aspect] {
        // Build simple ecliptic longitudes for planets
        let epoch = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2000, month: 1, day: 1).date ?? Date(timeIntervalSince1970: 946684800)
        let days = date.timeIntervalSince(epoch) / (24*3600)
        let rate: [String: Double] = [
            "Sun": 0.9856, "Moon": 13.1764, "Mercury": 4.0923, "Venus": 1.6021,
            "Mars": 0.5240, "Jupiter": 0.0831, "Saturn": 0.0335, "Uranus": 0.0117, "Neptune": 0.0060
        ]
        let offset: [String: Double] = [
            "Sun": 0, "Moon": 120, "Mercury": 45, "Venus": 90, "Mars": 135,
            "Jupiter": 180, "Saturn": 225, "Uranus": 270, "Neptune": 315
        ]
        func norm(_ x: Double) -> Double { var v = x.truncatingRemainder(dividingBy: 360); if v < 0 { v += 360 }; return v }
        let names = ["Sun","Moon","Mercury","Venus","Mars","Jupiter","Saturn","Uranus","Neptune"]
        var lon: [String: Double] = [:]
        for n in names { lon[n] = norm((rate[n] ?? 0.5) * days + (offset[n] ?? 0)) }
        
        // Compute aspects
        let aspectDefs: [(name: String, angle: Double, orb: Double)] = [
            ("conjunction", 0, 8), ("sextile", 60, 6), ("square", 90, 8), ("trine", 120, 8), ("opposition", 180, 8)
        ]
        var results: [Aspect] = []
        for i in 0..<names.count {
            for j in (i+1)..<names.count {
                let a = lon[names[i]] ?? 0
                let b = lon[names[j]] ?? 0
                let diff = abs(a - b)
                let angle = min(diff, 360 - diff)
                if let asp = aspectDefs.min(by: { abs(angle - $0.angle) < abs(angle - $1.angle) }), abs(angle - asp.angle) <= asp.orb {
                    results.append(Aspect(planet1: names[i].lowercased(), planet2: names[j].lowercased(), type: asp.name, orb: abs(angle - asp.angle)))
                }
            }
        }
        return results
    }

    private func planetImpact(_ name: String) -> String {
        switch name {
        case "Sun": return "Core identity and vitality"
        case "Moon": return "Emotions and intuition"
        case "Mercury": return "Communication and thinking"
        case "Venus": return "Love and values"
        case "Mars": return "Energy and action"
        case "Jupiter": return "Growth and wisdom"
        case "Saturn": return "Structure and discipline"
        case "Uranus": return "Innovation and change"
        case "Neptune": return "Dreams and spirituality"
        default: return "Planetary influence"
        }
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
                    // Reset simulation to Jan 1 of the chosen year and recompute
                    let base = Calendar.current.date(from: DateComponents(year: newYear, month: 1, day: 1)) ?? Date()
                    simulationDate = base
                    simTick = 0
                    planets = computeLocalPositions(for: base)
                    aspects = computeLocalAspects(for: base)
                    planetAnimVersion &+= 1
                }
            }
        )
    }

    private func hapticSelection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
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
    var showDashaOverlay: Bool = false
    
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

            // Optional Dasha label
            if showDashaOverlay {
                VStack(spacing: 4) {
                    if let d = dasha {
                        Text("Mahadasha: \(d.mahadasha.lord) • Antardasha: \(d.antardasha.lord)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.08), in: Capsule())
                    }
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
