import SwiftUI

// MARK: - Synastry Compass View
// Interactive aspect web visualization - the map IS the UI, not decoration.
// Two planet sets with aspect lines between them. Every tap reveals meaning.

struct SynastryCompassView: View {
    let natalA: NatalPlacements
    let natalB: NatalPlacements
    let synastry: SynastryData
    @Binding var selectedAspect: SynastryAspect?
    @Binding var selectedPlanet: (person: Person, planet: String)?
    @Binding var focusDomain: Domain?
    let onAspectTapped: (SynastryAspect) -> Void

    enum Person { case a, b }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hitAreas: [CompassHitArea] = []
    @State private var tooltipPosition: CGPoint = .zero
    @State private var showTooltip = false
    @State private var starPhase: Double = 0

    private let personAColor = Color.cosmicGold
    private let personBColor = Color.planetVenus

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1/30)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 24

                // Update star phase
                let phase = timeline.date.timeIntervalSinceReferenceDate

                // Layer 0: Starfield
                drawStarfield(&context, size: size, phase: phase)

                // Layer 1: Zodiac ring (outer)
                drawZodiacRing(&context, center: center, radius: radius)

                // Layer 2: Aspect lines (connecting planets between charts)
                let aspectHits = drawAspectLines(
                    &context,
                    center: center,
                    radius: radius * 0.75,
                    synastry: synastry,
                    natalA: natalA,
                    natalB: natalB
                )

                // Layer 3: Person A planets (gold, inner orbit)
                let hitsA = drawPlanets(
                    &context,
                    center: center,
                    radius: radius * 0.55,
                    placements: natalA,
                    color: personAColor,
                    person: .a,
                    labelSide: .inner
                )

                // Layer 4: Person B planets (rose, outer orbit)
                let hitsB = drawPlanets(
                    &context,
                    center: center,
                    radius: radius * 0.8,
                    placements: natalB,
                    color: personBColor,
                    person: .b,
                    labelSide: .outer
                )

                // Layer 5: Selection glow
                if let selected = selectedAspect {
                    drawAspectHighlight(&context, center: center, radius: radius * 0.75, aspect: selected, natalA: natalA, natalB: natalB)
                }

                // Store hit areas
                hitAreas = aspectHits + hitsA + hitsB
            }
            .drawingGroup() // GPU acceleration for smooth animation
            .gesture(tapGesture)
            .overlay(tooltipOverlay)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Synastry compass showing planetary connections between two people")
    }

    // MARK: - Gestures

    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                handleTap(at: value.location)
            }
    }

    private func handleTap(at location: CGPoint) {
        // Find nearest hit area
        var closestHit: CompassHitArea?
        var closestDistance: CGFloat = .infinity

        for hit in hitAreas {
            let distance = hypot(location.x - hit.center.x, location.y - hit.center.y)
            if distance < hit.radius && distance < closestDistance {
                closestDistance = distance
                closestHit = hit
            }
        }

        if let hit = closestHit {
            CosmicHaptics.light()
            tooltipPosition = hit.center
            showTooltip = true

            switch hit.element {
            case .aspect(let aspect):
                selectedAspect = aspect
                selectedPlanet = nil
                onAspectTapped(aspect)
            case .planet(let person, let name):
                selectedPlanet = (person, name)
                selectedAspect = nil
            }

            // Auto-hide tooltip after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showTooltip = false
                }
            }
        } else {
            // Tapped empty space - deselect
            withAnimation(.spring(response: 0.3)) {
                selectedAspect = nil
                selectedPlanet = nil
                showTooltip = false
            }
        }
    }

    // MARK: - Tooltip Overlay

    @ViewBuilder
    private var tooltipOverlay: some View {
        if showTooltip {
            GeometryReader { geo in
                if let aspect = selectedAspect {
                    AspectTooltip(aspect: aspect)
                        .position(adjustedTooltipPosition(in: geo.size))
                        .transition(.scale.combined(with: .opacity))
                } else if let (person, planetName) = selectedPlanet {
                    PlanetTooltip(
                        planetName: planetName,
                        person: person,
                        placements: person == .a ? natalA : natalB
                    )
                    .position(adjustedTooltipPosition(in: geo.size))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showTooltip)
        }
    }

    private func adjustedTooltipPosition(in size: CGSize) -> CGPoint {
        // Keep tooltip within bounds
        let tooltipWidth: CGFloat = 180
        let tooltipHeight: CGFloat = 80
        let padding: CGFloat = 16

        var x = tooltipPosition.x
        var y = tooltipPosition.y - 60 // Above the tap point

        // Clamp to bounds
        x = max(tooltipWidth/2 + padding, min(size.width - tooltipWidth/2 - padding, x))
        y = max(tooltipHeight/2 + padding, min(size.height - tooltipHeight/2 - padding, y))

        return CGPoint(x: x, y: y)
    }

    // MARK: - Drawing Functions

    private func drawStarfield(_ context: inout GraphicsContext, size: CGSize, phase: Double) {
        let starCount = 60
        for i in 0..<starCount {
            let seed = Double(i * 127 + 31)
            let x = (sin(seed * 0.1) * 0.5 + 0.5) * size.width
            let y = (cos(seed * 0.13) * 0.5 + 0.5) * size.height

            // Twinkle effect
            let twinkle = sin(phase * 2 + seed) * 0.3 + 0.7
            let starSize = CGFloat((sin(seed * 0.7) * 0.5 + 0.5) * 1.5 + 0.5)

            context.fill(
                Circle().path(in: CGRect(x: x - starSize/2, y: y - starSize/2, width: starSize, height: starSize)),
                with: .color(.white.opacity(0.3 * twinkle))
            )
        }
    }

    private func drawZodiacRing(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Outer ring
        let ringWidth: CGFloat = 28
        let outerRadius = radius
        let innerRadius = radius - ringWidth

        // Draw ring background
        var ringPath = Path()
        ringPath.addArc(center: center, radius: outerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
        ringPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(360), endAngle: .zero, clockwise: true)
        ringPath.closeSubpath()

        context.fill(ringPath, with: .color(.white.opacity(0.03)))
        context.stroke(Path(ellipseIn: CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)), with: .color(.white.opacity(0.15)), lineWidth: 0.5)

        // Draw zodiac glyphs
        let midRadius = (outerRadius + innerRadius) / 2
        for (index, sign) in ZodiacSign.allCases.enumerated() {
            let angle = Angle.degrees(Double(index) * 30 - 90 + 15) // Start at top, center in segment
            let x = center.x + midRadius * CGFloat(cos(angle.radians))
            let y = center.y + midRadius * CGFloat(sin(angle.radians))

            // Use explicit purple color for visibility on light backgrounds
            context.draw(
                Text(sign.glyph)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.65)),
                at: CGPoint(x: x, y: y)
            )

            // Draw segment dividers
            let dividerAngle = Angle.degrees(Double(index) * 30 - 90)
            let dividerStart = CGPoint(
                x: center.x + innerRadius * CGFloat(cos(dividerAngle.radians)),
                y: center.y + innerRadius * CGFloat(sin(dividerAngle.radians))
            )
            let dividerEnd = CGPoint(
                x: center.x + outerRadius * CGFloat(cos(dividerAngle.radians)),
                y: center.y + outerRadius * CGFloat(sin(dividerAngle.radians))
            )

            var dividerPath = Path()
            dividerPath.move(to: dividerStart)
            dividerPath.addLine(to: dividerEnd)
            context.stroke(dividerPath, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
        }
    }

    enum LabelSide { case inner, outer }

    private func drawPlanets(
        _ context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        placements: NatalPlacements,
        color: Color,
        person: Person,
        labelSide: LabelSide
    ) -> [CompassHitArea] {
        var hits: [CompassHitArea] = []

        // Draw orbit circle
        context.stroke(
            Circle().path(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(color.opacity(0.15)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )

        for (name, placement) in placements.allPlacements {
            let angle = Angle.degrees(placement.longitude - 90) // -90 to start at top
            let x = center.x + radius * CGFloat(cos(angle.radians))
            let y = center.y + radius * CGFloat(sin(angle.radians))

            let isSelected = selectedPlanet?.person == person && selectedPlanet?.planet == name

            // Planet glyph background
            let planetSize: CGFloat = isSelected ? 32 : 26
            let bgRect = CGRect(x: x - planetSize/2, y: y - planetSize/2, width: planetSize, height: planetSize)

            // Glow for selected
            if isSelected {
                context.fill(
                    Circle().path(in: bgRect.insetBy(dx: -6, dy: -6)),
                    with: .color(color.opacity(0.3))
                )
            }

            // Planet circle
            context.fill(
                Circle().path(in: bgRect),
                with: .linearGradient(
                    Gradient(colors: [color, color.opacity(0.7)]),
                    startPoint: CGPoint(x: bgRect.minX, y: bgRect.minY),
                    endPoint: CGPoint(x: bgRect.maxX, y: bgRect.maxY)
                )
            )

            // Planet glyph
            let glyph = Planet(rawValue: name)?.glyph ?? name.prefix(2).description
            context.draw(
                Text(glyph)
                    .font(.system(size: isSelected ? 14 : 12, weight: .bold))
                    .foregroundColor(.black),
                at: CGPoint(x: x, y: y)
            )

            // Planet name label
            let labelOffset: CGFloat = labelSide == .inner ? -20 : 20
            let labelRadius = radius + labelOffset
            let labelX = center.x + labelRadius * CGFloat(cos(angle.radians))
            let labelY = center.y + labelRadius * CGFloat(sin(angle.radians))

            context.draw(
                Text(name)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(color.opacity(0.7)),
                at: CGPoint(x: labelX, y: labelY)
            )

            // Hit area
            hits.append(CompassHitArea(
                element: .planet(person, name),
                center: CGPoint(x: x, y: y),
                radius: 28
            ))
        }

        return hits
    }

    private func drawAspectLines(
        _ context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        synastry: SynastryData,
        natalA: NatalPlacements,
        natalB: NatalPlacements
    ) -> [CompassHitArea] {
        var hits: [CompassHitArea] = []

        // Filter by domain if set
        let aspects = focusDomain != nil
            ? synastry.topAspects.filter { aspect in
                let planet = aspect.planetA
                return focusDomain?.planet.rawValue == planet || focusDomain?.planet.rawValue == aspect.planetB
            }
            : synastry.topAspects

        for aspect in aspects {
            guard let posA = getPlacementLongitude(aspect.planetA, from: natalA),
                  let posB = getPlacementLongitude(aspect.planetB, from: natalB) else {
                continue
            }

            let angleA = Angle.degrees(posA - 90)
            let angleB = Angle.degrees(posB - 90)

            let radiusA = radius * 0.7  // Person A inner
            let radiusB = radius * 1.05 // Person B outer

            let pointA = CGPoint(
                x: center.x + radiusA * CGFloat(cos(angleA.radians)),
                y: center.y + radiusA * CGFloat(sin(angleA.radians))
            )
            let pointB = CGPoint(
                x: center.x + radiusB * CGFloat(cos(angleB.radians)),
                y: center.y + radiusB * CGFloat(sin(angleB.radians))
            )

            let isSelected = selectedAspect?.id == aspect.id
            let lineColor = aspectLineColor(for: aspect)
            let lineWidth: CGFloat = isSelected ? 3 : (aspect.isActivatedNow ? 2.5 : CGFloat(aspect.strength * 2 + 0.5))

            var path = Path()
            path.move(to: pointA)

            // Curved line through center area
            let midPoint = CGPoint(
                x: (pointA.x + pointB.x) / 2 + (center.x - (pointA.x + pointB.x) / 2) * 0.3,
                y: (pointA.y + pointB.y) / 2 + (center.y - (pointA.y + pointB.y) / 2) * 0.3
            )
            path.addQuadCurve(to: pointB, control: midPoint)

            // Shimmer for activated aspects
            if aspect.isActivatedNow && !isSelected {
                context.stroke(
                    path,
                    with: .color(lineColor.opacity(0.4)),
                    style: StrokeStyle(lineWidth: lineWidth + 4)
                )
            }

            context.stroke(
                path,
                with: .color(lineColor.opacity(isSelected ? 1.0 : 0.7)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

            // Hit area at midpoint
            hits.append(CompassHitArea(
                element: .aspect(aspect),
                center: midPoint,
                radius: 24
            ))
        }

        return hits
    }

    private func drawAspectHighlight(
        _ context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        aspect: SynastryAspect,
        natalA: NatalPlacements,
        natalB: NatalPlacements
    ) {
        guard let posA = getPlacementLongitude(aspect.planetA, from: natalA),
              let posB = getPlacementLongitude(aspect.planetB, from: natalB) else {
            return
        }

        let angleA = Angle.degrees(posA - 90)
        let angleB = Angle.degrees(posB - 90)

        let radiusA = radius * 0.7
        let radiusB = radius * 1.05

        let pointA = CGPoint(
            x: center.x + radiusA * CGFloat(cos(angleA.radians)),
            y: center.y + radiusA * CGFloat(sin(angleA.radians))
        )
        let pointB = CGPoint(
            x: center.x + radiusB * CGFloat(cos(angleB.radians)),
            y: center.y + radiusB * CGFloat(sin(angleB.radians))
        )

        // Glow at endpoints
        let glowSize: CGFloat = 20
        context.fill(
            Circle().path(in: CGRect(x: pointA.x - glowSize, y: pointA.y - glowSize, width: glowSize * 2, height: glowSize * 2)),
            with: .color(personAColor.opacity(0.4))
        )
        context.fill(
            Circle().path(in: CGRect(x: pointB.x - glowSize, y: pointB.y - glowSize, width: glowSize * 2, height: glowSize * 2)),
            with: .color(personBColor.opacity(0.4))
        )
    }

    private func aspectLineColor(for aspect: SynastryAspect) -> Color {
        switch aspect.aspectType {
        case .conjunction:
            return Color.cosmicTextPrimary
        case .trine, .sextile:
            return Color.cosmicGold
        case .square, .opposition:
            return Color.cosmicCopper
        }
    }

    private func getPlacementLongitude(_ planetName: String, from placements: NatalPlacements) -> Double? {
        for (name, placement) in placements.allPlacements {
            if name == planetName {
                return placement.longitude
            }
        }
        return nil
    }
}

// MARK: - Hit Area

struct CompassHitArea {
    enum Element {
        case aspect(SynastryAspect)
        case planet(SynastryCompassView.Person, String)
    }

    let element: Element
    let center: CGPoint
    let radius: CGFloat
}

// MARK: - Aspect Tooltip

struct AspectTooltip: View {
    let aspect: SynastryAspect

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            HStack(spacing: Cosmic.Spacing.xxs) {
                Text(aspect.planetAGlyph)
                    .foregroundStyle(Color.cosmicGold)
                Text(aspect.aspectGlyph)
                    .foregroundStyle(Color.cosmicTextSecondary)
                Text(aspect.planetBGlyph)
                    .foregroundStyle(Color.planetVenus)
            }
            .font(.cosmicBodyEmphasis)

            Text(aspect.interpretation.title)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(aspect.interpretation.oneLiner)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(2)

            if aspect.isActivatedNow {
                HStack(spacing: Cosmic.Spacing.xxs) {
                    Image(systemName: "sparkles")
                    Text("Active now")
                }
                .font(.cosmicMicro)
                .fontWeight(.medium)
                .foregroundStyle(Color.cosmicGold)
            }
        }
        .padding(Cosmic.Spacing.sm)
        .frame(maxWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                        .stroke(aspect.isHarmonious ? Color.cosmicGold.opacity(0.3) : Color.cosmicCopper.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Planet Tooltip

struct PlanetTooltip: View {
    let planetName: String
    let person: SynastryCompassView.Person
    let placements: NatalPlacements

    private var placement: Placement? {
        placements.allPlacements.first { $0.name == planetName }?.placement
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            HStack {
                Text(Planet(rawValue: planetName)?.glyph ?? "?")
                    .font(.cosmicHeadline)
                    .foregroundStyle(person == .a ? Color.cosmicGold : Color.planetVenus)

                Text(planetName)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }

            if let p = placement {
                Text("\(p.signGlyph) \(p.sign) \(p.formattedDegree)")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)

                if let house = p.house {
                    Text("House \(house)")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                        .stroke(Color.cosmicNebula, lineWidth: 1)
                )
        )
    }
}

// MARK: - Domain Filter Chips

struct DomainFilterChips: View {
    @Binding var selectedDomain: Domain?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedDomain == nil,
                    action: { selectedDomain = nil }
                )

                ForEach(Domain.allCases, id: \.self) { domain in
                    FilterChip(
                        title: domain.rawValue,
                        icon: domain.icon,
                        isSelected: selectedDomain == domain,
                        action: { selectedDomain = domain }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            CosmicHaptics.light()
            action()
        }) {
            HStack(spacing: Cosmic.Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.cosmicMicro)
                }
                Text(title)
                    .font(.cosmicCaptionEmphasis)
            }
            .padding(.horizontal, Cosmic.Spacing.sm)
            .padding(.vertical, Cosmic.Spacing.xxs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.cosmicGold : Color.cosmicBrass.opacity(0.15))
            )
            .foregroundStyle(isSelected ? Color.cosmicVoid : Color.cosmicBrass)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        VStack {
            SynastryCompassView(
                natalA: .mockA,
                natalB: .mockB,
                synastry: .mock,
                selectedAspect: .constant(nil),
                selectedPlanet: .constant(nil),
                focusDomain: .constant(nil),
                onAspectTapped: { _ in }
            )
            .padding()
        }
    }
}
