import SwiftUI
import HoroscopeService
import AstroEngine
import DataModels

/// Displays the daily horoscope for the signed-in user's sun sign.
struct TodayView: View {
    @StateObject private var repo = HoroscopeRepository()
    @State private var planetPositions: [PlanetPosition] = []

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Today")
        }
        .onAppear {
            // Load cached data immediately on appear for instant display
            Task {
                try? await repo.fetchToday()
                loadPlanetPositions()
            }
        }
        .task {
            try? await repo.fetchToday()
            loadPlanetPositions()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let today = repo.today {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(today.shortText)
                            .font(.body)
                        if let extended = today.extendedText {
                            Text(extended)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !planetPositions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Planetary Positions")
                                .font(.headline)
                            
                            PlanetaryChart(positions: planetPositions)
                                .frame(height: 250)
                        }
                    }
                }
                .padding()
            }
        } else {
            LoadingView()
        }
    }
    
    private func loadPlanetPositions() {
        let calc = WesternCalc()
        let birth = BirthData(date: Date(), time: nil, location: nil)
        planetPositions = calc.positions(for: birth)
    }
}

struct PlanetaryChart: View {
    let positions: [PlanetPosition]
    
    var body: some View {
        ZStack {
            // Zodiac wheel background
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
            
            // Zodiac signs around the wheel
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) * 30.0 - 90 // Start from top
                let radians = angle * .pi / 180
                let radius = 110.0
                
                Text(zodiacSigns[index])
                    .font(.caption)
                    .position(
                        x: 125 + radius * cos(radians),
                        y: 125 + radius * sin(radians)
                    )
            }
            
            // Planet positions
            ForEach(positions, id: \.name) { planet in
                let angle = planet.longitude - 90 // Adjust for top start
                let radians = angle * .pi / 180
                let radius = 85.0
                
                VStack(spacing: 2) {
                    Text(planetSymbol(for: planet.name))
                        .font(.title2)
                    Text(planet.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .position(
                    x: 125 + radius * cos(radians),
                    y: 125 + radius * sin(radians)
                )
            }
        }
        .frame(width: 250, height: 250)
    }
    
    private let zodiacSigns = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]
    
    private func planetSymbol(for name: String) -> String {
        switch name {
        case "Sun": return "☉"
        case "Moon": return "☽"
        case "Mercury": return "☿"
        case "Venus": return "♀"
        case "Mars": return "♂"
        case "Jupiter": return "♃"
        case "Saturn": return "♄"
        default: return "●"
        }
    }
}
