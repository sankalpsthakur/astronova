import SwiftUI

/// Compact chart view designed for embedding within chat messages.
public struct ChatChartView: View {
    let chart: AstrologicalChart
    let isPremium: Bool
    let showTransits: Bool
    
    @State private var isExpanded = false
    @State private var showingFullChart = false
    
    public init(chart: AstrologicalChart, isPremium: Bool = false, showTransits: Bool = false) {
        self.chart = chart
        self.isPremium = isPremium
        self.showTransits = showTransits
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartHeader
            
            if isExpanded {
                expandedContent
            } else {
                compactChart
            }
            
            chartFooter
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingFullChart) {
            NavigationView {
                ChartView(chart: chart, isPremium: isPremium)
                    .navigationTitle("Full Chart")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFullChart = false
                            }
                        }
                    }
            }
        }
    }
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(chart.chartType.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(chart.birthData.birthDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !isPremium && (showTransits || !chart.aspects.isEmpty) {
                premiumBadge
            }
        }
    }
    
    private var compactChart: some View {
        HStack(spacing: 16) {
            // Mini chart visualization
            miniChartWheel
            
            // Key planetary positions
            VStack(alignment: .leading, spacing: 6) {
                Text("Key Positions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(chart.planets.prefix(isPremium ? chart.planets.count : 7), id: \.name) { planet in
                    HStack(spacing: 8) {
                        Text(planet.symbol)
                            .font(.caption)
                            .foregroundStyle(planet.color)
                        
                        Text("\(planet.name): \(planet.sign.symbol) \(Int(planet.degree))°")
                            .font(.caption)
                        
                        if planet.isRetrograde {
                            Text("Rx")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.red.opacity(0.2))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                if !isPremium && chart.planets.count > 7 {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        
                        Text("Showing 7 of \(chart.planets.count) planets")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            compactChart
            
            if isPremium && !chart.aspects.isEmpty {
                aspectsSection
            }
            
            if isPremium && showTransits {
                transitsSection
            }
            
            housesSection
        }
    }
    
    private var miniChartWheel: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(.primary, lineWidth: 1.5)
                .frame(width: 80, height: 80)
            
            // Zodiac divisions
            ForEach(0..<12, id: \.self) { index in
                Path { path in
                    let angle = Double(index) * 30 * .pi / 180
                    let startPoint = CGPoint(
                        x: 40 + 35 * cos(angle - .pi/2),
                        y: 40 + 35 * sin(angle - .pi/2)
                    )
                    let endPoint = CGPoint(
                        x: 40 + 40 * cos(angle - .pi/2),
                        y: 40 + 40 * sin(angle - .pi/2)
                    )
                    
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(.tertiary, lineWidth: 0.5)
            }
            
            // Planets
            ForEach(chart.planets.prefix(isPremium ? chart.planets.count : 7), id: \.name) { planet in
                let angle = planet.longitude * .pi / 180
                
                Text(planet.symbol)
                    .font(.system(size: 8))
                    .foregroundStyle(planet.color)
                    .position(
                        x: 40 + 32 * cos(angle - .pi/2),
                        y: 40 + 32 * sin(angle - .pi/2)
                    )
            }
        }
        .frame(width: 80, height: 80)
    }
    
    private var aspectsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Major Aspects")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(chart.aspects.prefix(3), id: \.planet1.name) { aspect in
                HStack(spacing: 8) {
                    Circle()
                        .fill(aspect.type.color)
                        .frame(width: 8, height: 8)
                    
                    Text("\(aspect.planet1.symbol) \(aspect.type.rawValue) \(aspect.planet2.symbol)")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(aspect.type.isHarmonious ? "Harmonious" : "Challenging")
                        .font(.caption2)
                        .foregroundStyle(aspect.type.isHarmonious ? .green : .orange)
                }
            }
            
            if chart.aspects.count > 3 {
                Text("+ \(chart.aspects.count - 3) more aspects")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }
    
    private var transitsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Transits")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // This would be populated with actual transit data
            HStack(spacing: 8) {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                
                Text("Transit data requires live calculation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var housesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("House System")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                ForEach(chart.houses.prefix(isPremium ? 12 : 6), id: \.number) { house in
                    HStack(spacing: 4) {
                        Text("\(house.number)")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        Text(house.sign.symbol)
                            .font(.caption2)
                            .foregroundStyle(house.sign.element.color)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
                }
            }
            
            if !isPremium && chart.houses.count > 6 {
                Text("+ \(chart.houses.count - 6) more houses")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }
    
    private var premiumBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.caption2)
            
            Text("Premium")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(.yellow)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.yellow.opacity(0.2), in: Capsule())
    }
    
    private var chartFooter: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Button("Full Chart") {
                showingFullChart = true
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.2), in: Capsule())
            .foregroundStyle(.blue)
        }
    }
}

/// Teaser view for premium chart features shown to free users.
public struct ChartPremiumTeaser: View {
    let feature: String
    let description: String
    let onUpgrade: () -> Void
    
    public init(feature: String, description: String, onUpgrade: @escaping () -> Void) {
        self.feature = feature
        self.description = description
        self.onUpgrade = onUpgrade
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Premium Feature")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.yellow.opacity(0.2), in: Capsule())
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                
                Button("Upgrade to Premium") {
                    onUpgrade()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Sample chart for preview
            let sampleChart = AstrologicalChart(
                birthData: BirthData(
                    date: Date(),
                    time: DateComponents(hour: 12, minute: 0),
                    location: CLLocation(latitude: 40.7128, longitude: -74.0060)
                ),
                planets: [
                    ChartPlanet(name: "Sun", symbol: "☉", longitude: 45, house: 1),
                    ChartPlanet(name: "Moon", symbol: "☽", longitude: 120, house: 4),
                    ChartPlanet(name: "Mercury", symbol: "☿", longitude: 60, house: 2)
                ],
                houses: (1...12).map { ChartHouse(number: $0, cusp: Double($0 - 1) * 30) },
                aspects: [],
                chartType: .siderealBirth
            )
            
            ChatChartView(chart: sampleChart, isPremium: false)
            
            ChatChartView(chart: sampleChart, isPremium: true)
            
            ChartPremiumTeaser(
                feature: "Detailed Aspects",
                description: "See how planets interact with each other through conjunctions, trines, squares, and more."
            ) {
                // Handle upgrade
            }
        }
        .padding()
    }
}
#endif