import SwiftUI

// MARK: - Cosmic Map View
// The unified visualization: planets + dasha ring + aspects in one interactive canvas.
// The map IS the UI, not decoration.

struct CosmicMapView: View {
    let snapshot: TimeTravelSnapshot
    @Binding var selectedElement: CosmicElement?
    let onElementTapped: (CosmicElement) -> Void

    // Constants
    private let zodiacSigns = ["Ari", "Tau", "Gem", "Can", "Leo", "Vir", "Lib", "Sco", "Sag", "Cap", "Aqu", "Pis"]
    private let dashaLords = ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"]
    private let vimshottariYears: [String: Double] = [
        "Ketu": 7,
        "Venus": 20,
        "Sun": 6,
        "Moon": 10,
        "Mars": 7,
        "Rahu": 18,
        "Jupiter": 16,
        "Saturn": 19,
        "Mercury": 17,
    ]

    private let planetColors: [String: Color] = [
        "sun": .planetSun,
        "moon": .planetMoon,
        "mercury": .planetMercury,
        "venus": .planetVenus,
        "mars": .planetMars,
        "jupiter": .planetJupiter,
        "saturn": .planetSaturn,
        "uranus": .planetUranus,
        "neptune": .planetNeptune,
        "pluto": .planetPluto,
        "rahu": .planetRahu,
        "ketu": .planetKetu,
        "ascendant": .cosmicGold,
    ]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Canvas for all drawing
                TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                    Canvas { context, canvasSize in
                        let phase = timeline.date.timeIntervalSinceReferenceDate

                        // Layer 0: Cosmic background gradient
                        drawBackground(&context, size: canvasSize)

                        // Layer 1: Starfield with subtle twinkle
                        drawStarfield(&context, size: canvasSize, phase: phase)

                        // Layer 2: Zodiac ring (outer)
                        drawZodiacRing(&context, center: center, radius: size * 0.45)

                        // Layer 3: Dasha ring (inner)
                        drawDashaRing(&context, center: center, radius: size * 0.22)

                        // Layer 4: Orbit paths
                        drawOrbitPaths(&context, center: center, maxRadius: size * 0.42)

                        // Layer 5: Aspect lines
                        drawAspectLines(&context, center: center, radius: size * 0.38)

                        // Layer 6: Planets
                        drawPlanets(&context, center: center, radius: size * 0.38)

                        // Layer 7: Selection highlight
                        if let selected = selectedElement {
                            drawSelectionHighlight(&context, center: center, radius: size * 0.38, element: selected, phase: phase)
                        }

                    }
                }

                // Tap gesture overlay
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                handleTap(at: value.location, center: center, size: size)
                            }
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cosmic map showing \(snapshot.planets.count) planets")
        .accessibilityHint("Tap a planet or dasha segment for details")
    }

    // MARK: - Tap Handling

    private func handleTap(at point: CGPoint, center: CGPoint, size: CGFloat) {
        let planetRadius = size * 0.38
        let dashaBaseRadius = size * 0.22

        // Planet hit testing
        var nearestPlanet: (element: CosmicElement, distance: CGFloat)?
        for planet in snapshot.planets {
            let pos = planetPosition(for: planet, center: center, radius: planetRadius)
            let dx = point.x - pos.x
            let dy = point.y - pos.y
            let distance = sqrt(dx * dx + dy * dy)

            var planetSize: CGFloat = 12
            if planet.isDashaLord || planet.isAntardashaLord { planetSize = 16 }
            if selectedElement == .planet(planet.id) { planetSize = 20 }
            let hitRadius = max(22, planetSize)

            if distance <= hitRadius {
                if nearestPlanet == nil || distance < (nearestPlanet?.distance ?? .infinity) {
                    nearestPlanet = (.planet(planet.id), distance)
                }
            }
        }

        if let hit = nearestPlanet {
            applySelection(hit.element)
            return
        }

        // Dasha ring hit testing (polar)
        let layout = dashaRingLayout(baseRadius: dashaBaseRadius)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radialDistance = sqrt(dx * dx + dy * dy)

        let minHitRadius = layout.antarRadius - layout.antarWidth / 2 - 12
        let maxHitRadius = layout.labelRadius + 18
        if radialDistance >= minHitRadius && radialDistance <= maxHitRadius {
            var angleDeg = Double(atan2(dy, dx) * 180 / .pi)
            if angleDeg < -90 { angleDeg += 360 }

            let mahaInner = layout.mahaRadius - layout.mahaWidth / 2 - 6
            let mahaOuter = layout.mahaRadius + layout.mahaWidth / 2 + 6
            if radialDistance >= mahaInner && radialDistance <= mahaOuter {
                applySelection(.dashaLord(snapshot.currentDasha.mahadasha.lord))
                return
            }

            let segments = antardashaSegments()
            if let hit = segments.first(where: { angleDeg >= $0.startAngleDeg && angleDeg < $0.endAngleDeg }) {
                applySelection(.dashaLord(hit.lord))
                return
            }
        }

        withAnimation(.cosmicQuick) {
            selectedElement = nil
        }
    }

    private func applySelection(_ element: CosmicElement) {
        CosmicHaptics.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedElement == element {
                // Second tap triggers details
                onElementTapped(element)
            } else {
                selectedElement = element
            }
        }
    }

    // MARK: - Drawing Functions

    private func drawBackground(_ context: inout GraphicsContext, size: CGSize) {
        let gradient = Gradient(colors: [
            Color(red: 0.02, green: 0.02, blue: 0.08),
            Color(red: 0.08, green: 0.04, blue: 0.15),
            Color(red: 0.05, green: 0.02, blue: 0.12)
        ])

        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(roundedRect: rect, cornerRadius: 20),
            with: .radialGradient(gradient, center: CGPoint(x: size.width/2, y: size.height/2),
                                 startRadius: 0, endRadius: size.width * 0.7)
        )
    }

    private func drawStarfield(_ context: inout GraphicsContext, size: CGSize, phase: Double) {
        // Deterministic star positions based on grid
        let starCount = 60
        for i in 0..<starCount {
            let x = Double(i % 10) / 10.0 * size.width + 15
            let y = Double(i / 10) / 6.0 * size.height + 10

            // Subtle twinkle based on phase
            let twinkle = sin(phase * 2 + Double(i) * 0.5) * 0.3 + 0.7
            let starSize: CGFloat = (i % 3 == 0) ? 1.5 : 1.0

            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                with: .color(.white.opacity(twinkle * 0.4))
            )
        }
    }

    private func drawZodiacRing(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Outer ring
        var ringPath = Path()
        ringPath.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                       width: radius * 2, height: radius * 2))
        context.stroke(ringPath, with: .color(.white.opacity(0.2)), lineWidth: 1)

        // Inner ring
        let innerRadius = radius - 25
        var innerPath = Path()
        innerPath.addEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius,
                                        width: innerRadius * 2, height: innerRadius * 2))
        context.stroke(innerPath, with: .color(.white.opacity(0.15)), lineWidth: 0.5)

        // Sign divisions and labels
        for i in 0..<12 {
            let angle = CGFloat(i) * 30.0 - 90 // Start at top
            let radians = angle * .pi / 180

            // Tick mark
            let tickStart = CGPoint(
                x: center.x + (radius - 5) * cos(radians),
                y: center.y + (radius - 5) * sin(radians)
            )
            let tickEnd = CGPoint(
                x: center.x + (radius + 5) * cos(radians),
                y: center.y + (radius + 5) * sin(radians)
            )

            var tickPath = Path()
            tickPath.move(to: tickStart)
            tickPath.addLine(to: tickEnd)
            context.stroke(tickPath, with: .color(.white.opacity(0.3)), lineWidth: i % 3 == 0 ? 2 : 1)

            // Sign label
            let labelAngle = (CGFloat(i) * 30.0 + 15.0 - 90) * .pi / 180
            let labelRadius = radius - 14
            let labelPos = CGPoint(
                x: center.x + labelRadius * cos(labelAngle),
                y: center.y + labelRadius * sin(labelAngle)
            )

            let signText = Text(zodiacSigns[i])
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            context.draw(signText, at: labelPos, anchor: .center)
        }
    }

    private func drawDashaRing(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let mahaLord = snapshot.currentDasha.mahadasha.lord
        let antarLord = snapshot.currentDasha.antardasha.lord
        let mahaColor = planetColors[mahaLord.lowercased()] ?? .white

        let layout = dashaRingLayout(baseRadius: radius)

        // Outer ring: Mahadasha progress (accurate)
        let fullStart = -90.0
        let fullEnd = 270.0
        var mahaTrack = Path()
        mahaTrack.addArc(
            center: center,
            radius: layout.mahaRadius,
            startAngle: .degrees(fullStart),
            endAngle: .degrees(fullEnd),
            clockwise: false
        )
        context.stroke(
            mahaTrack,
            with: .color(mahaColor.opacity(0.18)),
            style: StrokeStyle(lineWidth: layout.mahaWidth, lineCap: .round)
        )

        let mahaProgressEnd = fullStart + 360.0 * snapshot.currentDasha.mahadashaProgress
        if mahaProgressEnd > fullStart {
            var mahaProgress = Path()
            mahaProgress.addArc(
                center: center,
                radius: layout.mahaRadius,
                startAngle: .degrees(fullStart),
                endAngle: .degrees(mahaProgressEnd),
                clockwise: false
            )
            context.stroke(
                mahaProgress,
                with: .color(mahaColor.opacity(0.95)),
                style: StrokeStyle(lineWidth: layout.mahaWidth, lineCap: .round)
            )
            context.stroke(
                mahaProgress,
                with: .color(mahaColor.opacity(0.35)),
                style: StrokeStyle(lineWidth: layout.mahaWidth + 6, lineCap: .round)
            )
        }

        // Inner ring: Antardasha segments (accurate durations when server provides timeline)
        let segments = antardashaSegments()
        for segment in segments {
            let isCurrent = segment.lord == antarLord
            let isSelected = selectedElement == .dashaLord(segment.lord)
            let baseColor = planetColors[segment.lord.lowercased()] ?? .gray

            let opacity: Double = {
                if isSelected { return 1.0 }
                if isCurrent { return 0.9 }
                return 0.35
            }()
            let width: CGFloat = {
                if isSelected { return layout.antarWidth + 4 }
                if isCurrent { return layout.antarWidth + 2 }
                return layout.antarWidth
            }()

            var arc = Path()
            arc.addArc(
                center: center,
                radius: layout.antarRadius,
                startAngle: .degrees(segment.startAngleDeg),
                endAngle: .degrees(segment.endAngleDeg),
                clockwise: false
            )

            context.stroke(
                arc,
                with: .color(baseColor.opacity(opacity)),
                style: StrokeStyle(lineWidth: width, lineCap: .butt)
            )

            if isSelected {
                context.stroke(
                    arc,
                    with: .color(baseColor.opacity(0.3)),
                    style: StrokeStyle(lineWidth: width + 6, lineCap: .butt)
                )
            }

            // Antardasha progress overlay
            if isCurrent {
                let progressEnd = segment.startAngleDeg + segment.spanDeg * snapshot.currentDasha.antardashaProgress
                if progressEnd > segment.startAngleDeg {
                    var progressArc = Path()
                    progressArc.addArc(
                        center: center,
                        radius: layout.antarRadius,
                        startAngle: .degrees(segment.startAngleDeg),
                        endAngle: .degrees(progressEnd),
                        clockwise: false
                    )
                    context.stroke(
                        progressArc,
                        with: .color(baseColor.opacity(0.98)),
                        style: StrokeStyle(lineWidth: width + 2, lineCap: .round)
                    )
                }
            }

            // Labels
            let midRad = segment.midAngleRad
            let labelPos = CGPoint(
                x: center.x + layout.labelRadius * cos(midRad),
                y: center.y + layout.labelRadius * sin(midRad)
            )

            let labelText = Text(String(segment.lord.prefix(3)))
                .font(.system(size: isCurrent ? 10 : 8, weight: isCurrent ? .bold : .medium))
                .foregroundStyle(.white.opacity(isCurrent || isSelected ? 0.95 : 0.8))

            drawTextPill(
                &context,
                text: labelText,
                at: labelPos,
                paddingX: 5,
                paddingY: 3,
                background: Color.black.opacity(0.35),
                border: baseColor.opacity(isCurrent || isSelected ? 0.65 : 0.28)
            )
        }
    }

    private func drawOrbitPaths(_ context: inout GraphicsContext, center: CGPoint, maxRadius: CGFloat) {
        // Draw concentric orbit guides
        let orbitRadii: [CGFloat] = [0.3, 0.5, 0.65, 0.8, 0.95]

        for ratio in orbitRadii {
            let r = maxRadius * ratio
            var path = Path()
            path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))

            let style = StrokeStyle(lineWidth: 0.5, dash: [4, 4])
            context.stroke(path, with: .color(.white.opacity(0.1)), style: style)
        }
    }

    private func drawAspectLines(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let selectedAspect: (String, String)? = {
            guard case let .aspect(p1, p2) = selectedElement else { return nil }
            return (p1, p2)
        }()

        for aspect in snapshot.aspects {
            guard let planet1 = snapshot.planets.first(where: { $0.id == aspect.planet1 }),
                  let planet2 = snapshot.planets.first(where: { $0.id == aspect.planet2 }) else {
                continue
            }

            let pos1 = planetPosition(for: planet1, center: center, radius: radius)
            let pos2 = planetPosition(for: planet2, center: center, radius: radius)

            var linePath = Path()
            linePath.move(to: pos1)
            linePath.addLine(to: pos2)

            let isSelected: Bool = {
                guard let selectedAspect else { return false }
                let (a, b) = selectedAspect
                return (a == aspect.planet1 && b == aspect.planet2) || (a == aspect.planet2 && b == aspect.planet1)
            }()

            let baseColor: Color = aspect.type.isHarmonious ? .cosmicSuccess : .cosmicError
            let opacity: Double = isSelected ? 0.85 : 0.35
            let width: CGFloat = isSelected ? 3 : (aspect.isApplying ? 2 : 1)
            let dash: [CGFloat] = isSelected ? [] : (aspect.isApplying ? [] : [4, 4])
            let style = StrokeStyle(lineWidth: width, dash: dash)

            context.stroke(linePath, with: .color(baseColor.opacity(opacity)), style: style)
        }
    }

    private func drawPlanets(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        for planet in snapshot.planets {
            let pos = planetPosition(for: planet, center: center, radius: radius)
            let color = planetColors[planet.id] ?? .white
            let isSelected = selectedElement == .planet(planet.id)
            let isDashaLord = planet.isDashaLord || planet.isAntardashaLord

            // Planet size based on importance
            var planetSize: CGFloat = 12
            if isDashaLord { planetSize = 16 }
            if isSelected { planetSize = 20 }

            // Glow effect
            if isDashaLord || isSelected {
                let glowGradient = Gradient(colors: [color.opacity(0.6), color.opacity(0)])
                context.fill(
                    Path(ellipseIn: CGRect(x: pos.x - planetSize * 1.5, y: pos.y - planetSize * 1.5,
                                          width: planetSize * 3, height: planetSize * 3)),
                    with: .radialGradient(glowGradient, center: pos, startRadius: 0, endRadius: planetSize * 1.5)
                )
            }

            // Planet body
            let planetGradient = Gradient(colors: [color, color.opacity(0.6)])
            let bodyRect = CGRect(
                x: pos.x - planetSize / 2,
                y: pos.y - planetSize / 2,
                width: planetSize,
                height: planetSize
            )
            let bodyPath = Path(ellipseIn: bodyRect)
            context.fill(
                bodyPath,
                with: .radialGradient(planetGradient, center: CGPoint(x: pos.x - 2, y: pos.y - 2),
                                     startRadius: 0, endRadius: planetSize)
            )

            // Edge definition (improves contrast across light/dark planet colors)
            context.stroke(bodyPath, with: .color(.black.opacity(0.55)), lineWidth: 1.5)
            context.stroke(bodyPath, with: .color(.white.opacity(0.18)), lineWidth: 0.75)

            // Planet symbol label
            let labelPoint = CGPoint(x: pos.x, y: pos.y - planetSize - 10)
            let symbolText = Text(planet.symbol)
                .font(.system(size: isSelected ? 13 : 10, weight: .bold))
                .foregroundStyle(.white)

            drawTextPill(
                &context,
                text: symbolText,
                at: labelPoint,
                paddingX: 5,
                paddingY: 3,
                background: Color.black.opacity(0.45),
                border: color.opacity(isSelected || isDashaLord ? 0.8 : 0.35)
            )

            // Retrograde indicator
            if planet.isRetrograde {
                let rxText = Text("Rx")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.cosmicWarning)
                context.draw(rxText, at: CGPoint(x: pos.x + planetSize/2 + 4, y: pos.y), anchor: .leading)
            }

        }
    }

    private func drawSelectionHighlight(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat, element: CosmicElement, phase: Double) {
        let pulse = sin(phase * 3) * 0.2 + 0.8

        switch element {
        case .planet(let id):
            if let planet = snapshot.planets.first(where: { $0.id == id }) {
                let pos = planetPosition(for: planet, center: center, radius: radius)
                let color = planetColors[id] ?? .white

                // Pulsing ring
                var ringPath = Path()
                ringPath.addEllipse(in: CGRect(x: pos.x - 25, y: pos.y - 25, width: 50, height: 50))
                context.stroke(ringPath, with: .color(color.opacity(pulse * 0.6)),
                              style: StrokeStyle(lineWidth: 2))
            }

        case .dashaLord(let lord):
            // Highlight the corresponding planet on the map
            if let planet = snapshot.planets.first(where: { $0.name == lord }) {
                let pos = planetPosition(for: planet, center: center, radius: radius)
                let color = planetColors[planet.id] ?? .white

                var ringPath = Path()
                ringPath.addEllipse(in: CGRect(x: pos.x - 30, y: pos.y - 30, width: 60, height: 60))
                context.stroke(ringPath, with: .color(color.opacity(pulse * 0.5)),
                              style: StrokeStyle(lineWidth: 3, dash: [6, 3]))
            }

        case .aspect(_, _):
            break // Aspect highlighting handled in drawAspectLines
        }
    }

    // MARK: - Helpers

    private func planetPosition(for planet: PlanetState, center: CGPoint, radius: CGFloat) -> CGPoint {
        // Convert longitude to screen position
        // 0° Aries at top, going clockwise
        let angle = (planet.longitude - 90) * .pi / 180

        // Vary radius slightly by planet to avoid overlap
        let orbitRatio = orbitRatio(for: planet.id)
        let r = radius * orbitRatio

        return CGPoint(
            x: center.x + r * cos(CGFloat(angle)),
            y: center.y + r * sin(CGFloat(angle))
        )
    }

    private func orbitRatio(for planetId: String) -> CGFloat {
        // Inner planets closer, outer planets further
        switch planetId {
        case "moon": return 0.35
        case "mercury": return 0.45
        case "venus": return 0.55
        case "sun": return 0.65
        case "mars": return 0.75
        case "jupiter": return 0.85
        case "saturn": return 0.92
        case "rahu", "ketu": return 0.98
        default: return 0.7
        }
    }

    private struct DashaRingLayout {
        let mahaRadius: CGFloat
        let mahaWidth: CGFloat
        let antarRadius: CGFloat
        let antarWidth: CGFloat
        let labelRadius: CGFloat
    }

    private struct DashaSegment {
        let lord: String
        let startAngleDeg: Double
        let endAngleDeg: Double

        var spanDeg: Double { endAngleDeg - startAngleDeg }
        var midAngleDeg: Double { (startAngleDeg + endAngleDeg) / 2 }
        var midAngleRad: CGFloat { CGFloat(midAngleDeg) * .pi / 180 }
    }

    private func dashaRingLayout(baseRadius: CGFloat) -> DashaRingLayout {
        let mahaWidth: CGFloat = 12
        let antarWidth: CGFloat = 10
        let separation: CGFloat = 10
        let mahaRadius = baseRadius + separation
        let antarRadius = baseRadius - separation
        let labelRadius = mahaRadius + 22
        return DashaRingLayout(
            mahaRadius: mahaRadius,
            mahaWidth: mahaWidth,
            antarRadius: antarRadius,
            antarWidth: antarWidth,
            labelRadius: labelRadius
        )
    }

    private func antardashaSegments() -> [DashaSegment] {
        let periods = snapshot.currentDasha.antardashaTimeline
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        let durations: [TimeInterval] = sorted.map { max(0.0, $0.endDate.timeIntervalSince($0.startDate)) }
        let total = durations.reduce(0.0, +)

        let startDeg = -90.0
        let endDeg = 270.0

        if total > 0, sorted.count == durations.count {
            var cursor = startDeg
            var segments: [DashaSegment] = []
            for (index, period) in sorted.enumerated() {
                let duration = durations[index]
                let span = 360.0 * duration / total
                let start = cursor
                let end = (index == sorted.count - 1) ? endDeg : (cursor + span)
                segments.append(DashaSegment(lord: period.lord, startAngleDeg: start, endAngleDeg: end))
                cursor = end
            }
            return segments
        }

        // Fallback: Vimshottari proportions (year-based), starting at current mahadasha lord.
        let mahaLord = snapshot.currentDasha.mahadasha.lord
        let startIndex = dashaLords.firstIndex(of: mahaLord) ?? 0
        let ordered = (0..<dashaLords.count).map { dashaLords[(startIndex + $0) % dashaLords.count] }

        let totalYears = ordered.reduce(0.0) { $0 + (vimshottariYears[$1] ?? 0.0) }
        guard totalYears > 0 else { return [] }

        var cursor = startDeg
        var segments: [DashaSegment] = []
        for (index, lord) in ordered.enumerated() {
            let years = vimshottariYears[lord] ?? 0.0
            let span = 360.0 * years / totalYears
            let start = cursor
            let end = (index == ordered.count - 1) ? endDeg : (cursor + span)
            segments.append(DashaSegment(lord: lord, startAngleDeg: start, endAngleDeg: end))
            cursor = end
        }
        return segments
    }

    private func drawTextPill(
        _ context: inout GraphicsContext,
        text: Text,
        at point: CGPoint,
        paddingX: CGFloat,
        paddingY: CGFloat,
        background: Color,
        border: Color
    ) {
        let resolved = context.resolve(text)
        let measured = resolved.measure(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        let rect = CGRect(
            x: point.x - measured.width / 2 - paddingX,
            y: point.y - measured.height / 2 - paddingY,
            width: measured.width + paddingX * 2,
            height: measured.height + paddingY * 2
        )

        let shape = Path(roundedRect: rect, cornerRadius: rect.height / 2)
        context.fill(shape, with: .color(background))
        context.stroke(shape, with: .color(border), lineWidth: 0.75)
        context.draw(resolved, at: point, anchor: .center)
    }
}
