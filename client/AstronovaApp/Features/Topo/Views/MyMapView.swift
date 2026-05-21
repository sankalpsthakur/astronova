import SwiftUI

// MARK: - Color Helper

private func domainTint(_ hint: String) -> Color {
    switch hint.lowercased() {
    case "gold": return .cosmicGold
    case "pink": return .planetVenus
    case "green": return .cosmicSuccess
    case "bronze": return .cosmicCopper
    case "indigo": return .cosmicAmethyst
    case "coral": return .planetMars.opacity(0.85)
    default: return .cosmicAccent
    }
}

// MARK: - MyMapView

struct MyMapView: View {
    @State private var snapshot: DomainSnapshot?
    private let domains: [DomainMapping] = TopoContentLoader.shared.domains

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    radarBlock
                    legendStrip
                    domainGrid
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.cosmicVoid.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear { load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Map")
                .font(.cosmicDisplay)
                .foregroundColor(.cosmicTextPrimary)
            Text("Your inner terrain — tap a zone to explore.")
                .font(.cosmicCallout)
                .foregroundColor(.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var radarBlock: some View {
        HStack {
            Spacer()
            RadarChart(snapshot: snapshot, domains: domains)
                .frame(width: 300, height: 300)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var legendStrip: some View {
        HStack(spacing: 14) {
            legendChip(label: "Intensity", color: .cosmicAccent)
            legendChip(label: "Friction", color: .cosmicError)
            legendChip(label: "Opportunity", color: .cosmicSuccess)
            Spacer()
        }
    }

    private func legendChip(label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.cosmicMicro)
                .foregroundColor(.cosmicTextTertiary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
    }

    private var domainGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(domains) { domain in
                if let score = score(for: domain.id) {
                    NavigationLink {
                        TopoDomainDetailView(mapping: domain, score: score)
                    } label: {
                        DomainCard(domain: domain, score: score)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticFeedbackService.shared.lightImpact()
                    })
                }
            }
        }
    }

    private func score(for id: String) -> TopoDomainScore? {
        snapshot?.domains.first { $0.domainId == id }
    }

    private func load() {
        snapshot = TopoDomainScorer.shared.snapshot()
    }
}

// MARK: - RadarChart

private struct RadarChart: View {
    let snapshot: DomainSnapshot?
    let domains: [DomainMapping]

    private let rings: Int = 6

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 36

            // Concentric grid polygons
            for ring in 1...rings {
                let r = radius * CGFloat(ring) / CGFloat(rings)
                let path = polygonPath(center: center, radius: r, sides: 6)
                ctx.stroke(
                    path,
                    with: .color(.cosmicTextTertiary.opacity(0.18)),
                    lineWidth: 0.5
                )
            }

            // Axes
            for i in 0..<6 {
                let angle = axisAngle(for: i)
                let endX = center.x + cos(angle) * radius
                let endY = center.y + sin(angle) * radius
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(x: endX, y: endY))
                ctx.stroke(
                    path,
                    with: .color(.cosmicTextTertiary.opacity(0.22)),
                    lineWidth: 0.5
                )
            }

            // User polygon
            let userPoints: [CGPoint] = domains.enumerated().map { (i, d) in
                let comp = scoreFor(d.id)
                let angle = axisAngle(for: i)
                let r = radius * CGFloat(comp)
                return CGPoint(x: center.x + cos(angle) * r,
                               y: center.y + sin(angle) * r)
            }

            if !userPoints.isEmpty {
                var userPath = Path()
                userPath.move(to: userPoints[0])
                for p in userPoints.dropFirst() { userPath.addLine(to: p) }
                userPath.closeSubpath()

                ctx.fill(userPath, with: .color(.cosmicAmethyst.opacity(0.25)))
                ctx.stroke(userPath, with: .color(.cosmicAmethyst), lineWidth: 1.4)
            }

            // Vertex dots
            for (i, p) in userPoints.enumerated() {
                let hint = domains[i].colorHint
                let dot = Path(ellipseIn: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7))
                ctx.fill(dot, with: .color(domainTint(hint)))
                ctx.stroke(
                    dot,
                    with: .color(.cosmicVoid),
                    lineWidth: 1.2
                )
            }

            // Perimeter labels
            for (i, d) in domains.enumerated() {
                let angle = axisAngle(for: i)
                let labelR = radius + 22
                let lx = center.x + cos(angle) * labelR
                let ly = center.y + sin(angle) * labelR
                let comp = scoreFor(d.id)
                let scoreText = String(format: "%.1f", comp * 10)
                let block = Text("\(d.name)\n\(scoreText)")
                    .font(.cosmicMicro)
                    .foregroundColor(.cosmicTextSecondary)
                let resolved = ctx.resolve(block)
                ctx.draw(resolved, at: CGPoint(x: lx, y: ly), anchor: .center)
            }
        }
    }

    private func scoreFor(_ id: String) -> Double {
        snapshot?.domains.first { $0.domainId == id }?.composite ?? 0
    }

    private func axisAngle(for index: Int) -> CGFloat {
        // Start from top (-pi/2), 60deg apart, clockwise.
        let step = CGFloat.pi / 3
        return -CGFloat.pi / 2 + step * CGFloat(index)
    }

    private func polygonPath(center: CGPoint, radius: CGFloat, sides: Int) -> Path {
        var path = Path()
        for i in 0..<sides {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * (2 * .pi / CGFloat(sides))
            let pt = CGPoint(x: center.x + cos(angle) * radius,
                             y: center.y + sin(angle) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - DomainCard

private struct DomainCard: View {
    let domain: DomainMapping
    let score: TopoDomainScore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: domain.iconSfSymbol)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(domainTint(domain.colorHint))
            Text(domain.name)
                .font(.cosmicBodyEmphasis)
                .foregroundColor(.cosmicTextPrimary)
            Text(String(format: "%.1f / 10", score.composite * 10))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(domainTint(domain.colorHint).opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - TopoDomainDetailView

struct TopoDomainDetailView: View {
    let mapping: DomainMapping
    let score: TopoDomainScore

    enum FactorTab: String, CaseIterable, Identifiable {
        case western = "Western"
        case vedic = "Vedic"
        var id: String { rawValue }
    }

    @State private var factorTab: FactorTab = .western

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                tagline
                terrainCard
                signatures
                factorsSection
                patternsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle(mapping.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var tagline: some View {
        Text(mapping.tagline)
            .font(.cosmicBody)
            .foregroundColor(.cosmicTextSecondary)
            .padding(.top, 4)
    }

    private var terrainCard: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: mapping.iconSfSymbol)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(domainTint(mapping.colorHint))
                .frame(width: 64)
            Text(mapping.terrainMetaphor)
                .font(.cosmicCallout)
                .foregroundColor(.cosmicTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(domainTint(mapping.colorHint).opacity(0.15))
        )
    }

    private var signatures: some View {
        VStack(alignment: .leading, spacing: 16) {
            signatureRow(
                caption: "HIGH INTENSITY",
                tint: .cosmicAccent,
                body: mapping.intensityHighSignature
            )
            signatureRow(
                caption: "FRICTION",
                tint: .cosmicError,
                body: mapping.frictionSignature
            )
            signatureRow(
                caption: "OPPORTUNITY",
                tint: .cosmicSuccess,
                body: mapping.opportunitySignature
            )
        }
    }

    private func signatureRow(caption: String, tint: Color, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 6, height: 6)
                Text(caption)
                    .font(.cosmicMicro)
                    .foregroundColor(.cosmicTextTertiary)
                    .tracking(0.8)
            }
            Text(body)
                .font(.cosmicCallout)
                .foregroundColor(.cosmicTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Factors")
                    .font(.cosmicFootnoteEmphasis)
                    .foregroundColor(.cosmicTextTertiary)
                    .tracking(0.8)
                    .textCase(.uppercase)
                Spacer()
                Picker("Factor tradition", selection: $factorTab) {
                    ForEach(FactorTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .onChange(of: factorTab) { _, _ in
                    HapticFeedbackService.shared.selection()
                }
            }

            let factors = factorTab == .western ? mapping.westernFactors : mapping.vedicFactors

            VStack(spacing: 10) {
                ForEach(Array(factors.enumerated()), id: \.offset) { _, f in
                    factorRow(name: f.factor, weight: f.weight)
                }
            }
        }
    }

    private func factorRow(name: String, weight: Double) -> some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.cosmicCallout)
                .foregroundColor(.cosmicTextPrimary)
            Spacer()
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.cosmicSurfaceSecondary)
                    .frame(width: 100, height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(domainTint(mapping.colorHint))
                    .frame(width: 100 * CGFloat(max(0, min(1, weight))), height: 4)
            }
        }
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Associated patterns")
                .font(.cosmicFootnoteEmphasis)
                .foregroundColor(.cosmicTextTertiary)
                .tracking(0.8)
                .textCase(.uppercase)

            VStack(spacing: 10) {
                ForEach(mapping.associatedPatterns, id: \.self) { pid in
                    if let pattern = TopoContentLoader.shared.pattern(id: pid) {
                        NavigationLink {
                            PatternDetailView(pattern: pattern)
                        } label: {
                            patternCard(pattern: pattern)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticFeedbackService.shared.lightImpact()
                        })
                    }
                }
            }
        }
    }

    private func patternCard(pattern: Pattern) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pattern.name)
                .font(.cosmicCalloutEmphasis)
                .foregroundColor(.cosmicTextPrimary)
            Text(truncate(pattern.loop.optimalAction, to: 60))
                .font(.cosmicFootnote)
                .foregroundColor(.cosmicTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.cosmicTextTertiary.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func truncate(_ s: String, to n: Int) -> String {
        guard s.count > n else { return s }
        let idx = s.index(s.startIndex, offsetBy: n)
        return String(s[..<idx]).trimmingCharacters(in: .whitespaces) + "..."
    }
}
