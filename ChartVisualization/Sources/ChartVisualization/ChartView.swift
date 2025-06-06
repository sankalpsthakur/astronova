import SwiftUI

/// Main view for displaying astrological charts with interactive features.
public struct ChartView: View {
    let chart: AstrologicalChart
    let transitPlanets: [ChartPlanet]?
    let isPremium: Bool
    
    @State private var selectedPlanet: ChartPlanet?
    @State private var showingAspects = false
    @State private var showingTransits = false
    @State private var chartScale: CGFloat = 1.0
    
    public init(chart: AstrologicalChart, transitPlanets: [ChartPlanet]? = nil, isPremium: Bool = false) {
        self.chart = chart
        self.transitPlanets = transitPlanets
        self.isPremium = isPremium
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            chartHeader
            
            GeometryReader { geometry in
                ZStack {
                    // Background circles and zodiac signs
                    chartBackground
                    
                    // House divisions
                    houseLines
                    
                    // Zodiac sign divisions
                    zodiacDivisions
                    
                    // Planetary aspects
                    if showingAspects && isPremium {
                        aspectLines
                    }
                    
                    // Birth chart planets
                    chartPlanets
                    
                    // Transit planets (if premium and enabled)
                    if showingTransits && isPremium, let transits = transitPlanets {
                        transitChartPlanets(transits)
                    }
                    
                    // Center point
                    centerPoint
                    
                    // Premium overlay for non-premium users
                    if !isPremium && (showingAspects || showingTransits) {
                        premiumOverlay
                    }
                }
                .scaleEffect(chartScale)
                .clipped()
            }
            .aspectRatio(1, contentMode: .fit)
            
            chartControls
            
            if let selected = selectedPlanet {
                planetDetails(selected)
            }
        }
        .background(.regularMaterial)
    }
    
    private var chartHeader: some View {
        VStack(spacing: 4) {
            Text(chart.chartType.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Born: \(chart.birthData.birthDate, style: .date)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if chart.chartType.isTransitChart {
                Text("Current: \(chart.calculationDate, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var chartBackground: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(.primary, lineWidth: 2)
            
            // Inner circles for house divisions
            Circle()
                .stroke(.secondary, lineWidth: 1)
                .scaleEffect(0.8)
            
            Circle()
                .stroke(.tertiary, lineWidth: 1)
                .scaleEffect(0.6)
        }
    }
    
    private var houseLines: some View {
        ZStack {
            ForEach(chart.houses, id: \.number) { house in
                HouseLineView(house: house)
            }
        }
    }
    
    private var zodiacDivisions: some View {
        ZStack {
            ForEach(ZodiacSign.allCases, id: \.self) { sign in
                ZodiacSectionView(sign: sign, index: ZodiacSign.allCases.firstIndex(of: sign) ?? 0)
            }
        }
    }
    
    private var aspectLines: some View {
        ZStack {
            ForEach(chart.aspects.indices, id: \.self) { index in
                AspectLineView(aspect: chart.aspects[index])
            }
        }
    }
    
    private var chartPlanets: some View {
        ZStack {
            ForEach(chart.planets, id: \.name) { planet in
                PlanetView(
                    planet: planet,
                    isSelected: selectedPlanet?.name == planet.name,
                    isTransit: false
                )
                .onTapGesture {
                    selectedPlanet = selectedPlanet?.name == planet.name ? nil : planet
                }
            }
        }
    }
    
    private func transitChartPlanets(_ transits: [ChartPlanet]) -> some View {
        ZStack {
            ForEach(transits, id: \.name) { planet in
                PlanetView(
                    planet: planet,
                    isSelected: selectedPlanet?.name == planet.name,
                    isTransit: true
                )
                .onTapGesture {
                    selectedPlanet = selectedPlanet?.name == planet.name ? nil : planet
                }
            }
        }
    }
    
    private var centerPoint: some View {
        Circle()
            .fill(.primary)
            .frame(width: 6, height: 6)
    }
    
    private var premiumOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
            
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                
                Text("Premium Feature")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Upgrade to view detailed aspects and transit overlays")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button("Upgrade Now") {
                    // Handle premium upgrade
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .clipShape(Circle())
    }
    
    private var chartControls: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingAspects.toggle()
                }
            } label: {
                Label("Aspects", systemImage: "line.3.crossed.swirl.circle")
                    .foregroundStyle(showingAspects ? .blue : .secondary)
            }
            
            if transitPlanets != nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingTransits.toggle()
                    }
                } label: {
                    Label("Transits", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(showingTransits ? .green : .secondary)
                }
            }
            
            Spacer()
            
            HStack {
                Button {
                    withAnimation {
                        chartScale = max(0.5, chartScale - 0.1)
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                
                Button {
                    withAnimation {
                        chartScale = min(2.0, chartScale + 0.1)
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
        }
        .padding()
    }
    
    private func planetDetails(_ planet: ChartPlanet) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(planet.symbol)
                    .font(.title2)
                    .foregroundStyle(planet.color)
                
                VStack(alignment: .leading) {
                    Text(planet.name)
                        .font(.headline)
                    
                    Text("\(planet.sign.rawValue) \(Int(planet.degree))°\(Int(planet.minute))'")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if planet.isRetrograde {
                    Text("Rx")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
            
            Text("House \(planet.house): \(chart.houses[planet.house - 1].interpretation)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct HouseLineView: View {
    let house: ChartHouse
    
    var body: some View {
        Path { path in
            let angle = house.cusp * .pi / 180
            let startPoint = CGPoint(
                x: 0.5 + 0.3 * cos(angle - .pi/2),
                y: 0.5 + 0.3 * sin(angle - .pi/2)
            )
            let endPoint = CGPoint(
                x: 0.5 + 0.5 * cos(angle - .pi/2),
                y: 0.5 + 0.5 * sin(angle - .pi/2)
            )
            
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(.secondary, lineWidth: 1)
        .overlay {
            // House number
            Text("\(house.number)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .position(
                    x: 0.5 + 0.4 * cos(house.cusp * .pi / 180 - .pi/2),
                    y: 0.5 + 0.4 * sin(house.cusp * .pi / 180 - .pi/2)
                )
        }
    }
}

struct ZodiacSectionView: View {
    let sign: ZodiacSign
    let index: Int
    
    var body: some View {
        ZStack {
            // Sign division line
            Path { path in
                let angle = Double(index) * 30 * .pi / 180
                let startPoint = CGPoint(
                    x: 0.5 + 0.45 * cos(angle - .pi/2),
                    y: 0.5 + 0.45 * sin(angle - .pi/2)
                )
                let endPoint = CGPoint(
                    x: 0.5 + 0.5 * cos(angle - .pi/2),
                    y: 0.5 + 0.5 * sin(angle - .pi/2)
                )
                
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(.tertiary, lineWidth: 0.5)
            
            // Sign symbol
            Text(sign.symbol)
                .font(.caption)
                .foregroundStyle(sign.element.color)
                .position(
                    x: 0.5 + 0.47 * cos((Double(index) * 30 + 15) * .pi / 180 - .pi/2),
                    y: 0.5 + 0.47 * sin((Double(index) * 30 + 15) * .pi / 180 - .pi/2)
                )
        }
    }
}

struct PlanetView: View {
    let planet: ChartPlanet
    let isSelected: Bool
    let isTransit: Bool
    
    var body: some View {
        let angle = planet.longitude * .pi / 180
        let radius: Double = isTransit ? 0.37 : 0.42
        
        Text(planet.symbol)
            .font(.system(size: isSelected ? 20 : 16, weight: .medium))
            .foregroundStyle(planet.color)
            .background {
                Circle()
                    .fill(isSelected ? .yellow.opacity(0.3) : .clear)
                    .frame(width: 24, height: 24)
            }
            .overlay {
                if isTransit {
                    Circle()
                        .stroke(.blue, lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            .position(
                x: 0.5 + radius * cos(angle - .pi/2),
                y: 0.5 + radius * sin(angle - .pi/2)
            )
    }
}

struct AspectLineView: View {
    let aspect: ChartAspect
    
    var body: some View {
        Path { path in
            let angle1 = aspect.planet1.longitude * .pi / 180
            let angle2 = aspect.planet2.longitude * .pi / 180
            let radius = 0.35
            
            let point1 = CGPoint(
                x: 0.5 + radius * cos(angle1 - .pi/2),
                y: 0.5 + radius * sin(angle1 - .pi/2)
            )
            let point2 = CGPoint(
                x: 0.5 + radius * cos(angle2 - .pi/2),
                y: 0.5 + radius * sin(angle2 - .pi/2)
            )
            
            path.move(to: point1)
            path.addLine(to: point2)
        }
        .stroke(
            aspect.type.color.opacity(0.6),
            style: StrokeStyle(
                lineWidth: aspect.type.isHarmonious ? 1.5 : 1,
                dash: aspect.type.isHarmonious ? [] : [5, 3]
            )
        )
    }
}

#if DEBUG
#Preview {
    // Create sample chart data for preview
    let sampleBirthData = BirthData(
        date: Date(),
        time: DateComponents(hour: 12, minute: 0),
        location: CLLocation(latitude: 40.7128, longitude: -74.0060)
    )
    
    let samplePlanets = [
        ChartPlanet(name: "Sun", symbol: "☉", longitude: 45, house: 1),
        ChartPlanet(name: "Moon", symbol: "☽", longitude: 120, house: 4),
        ChartPlanet(name: "Mercury", symbol: "☿", longitude: 60, house: 2)
    ]
    
    let sampleHouses = (1...12).map { ChartHouse(number: $0, cusp: Double($0 - 1) * 30) }
    
    let sampleChart = AstrologicalChart(
        birthData: sampleBirthData,
        planets: samplePlanets,
        houses: sampleHouses,
        aspects: [],
        chartType: .siderealBirth
    )
    
    ChartView(chart: sampleChart, isPremium: true)
}
#endif