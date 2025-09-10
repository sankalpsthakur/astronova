import SwiftUI
import CoreLocation

struct AstrologicalChartView: View {
    let positions: [String: DetailedPlanetaryPosition]
    let birthDate: Date
    let birthTime: Date
    let location: String
    
    @State private var animateChart = false
    @State private var selectedPlanet: String? = nil
    
    private let chartSize: CGFloat = 300
    private let zodiacSigns = ["♈", "♉", "♊", "♋", "♌", "♍", "♎", "♏", "♐", "♑", "♒", "♓"]
    private let zodiacNames = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", 
                               "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
    
    var body: some View {
        VStack(spacing: 24) {
            // Chart Title
            Text("Your Birth Chart")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            
            // Main Chart
            ZStack {
                // Background gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: chartSize/2
                        )
                    )
                    .frame(width: chartSize, height: chartSize)
                
                // Outer zodiac wheel
                ZStack {
                    Circle()
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ), lineWidth: 3)
                        .frame(width: chartSize, height: chartSize)
                    
                    // Zodiac divisions
                    ForEach(0..<12, id: \.self) { index in
                        Group {
                            // Division lines
                            Path { path in
                                path.move(to: CGPoint(x: chartSize/2, y: chartSize/2))
                                path.addLine(to: CGPoint(x: chartSize/2, y: 0))
                            }
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                            .rotationEffect(.degrees(Double(index * 30)))
                            
                            // Zodiac symbols
                            Text(zodiacSigns[index])
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                                .position(
                                    x: chartSize/2 + (chartSize/2 - 20) * cos(angleForIndex(index) - .pi/2),
                                    y: chartSize/2 + (chartSize/2 - 20) * sin(angleForIndex(index) - .pi/2)
                                )
                                .rotationEffect(.degrees(Double(index * 30) + 15))
                        }
                    }
                }
                
                // Houses circle
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .frame(width: chartSize * 0.75, height: chartSize * 0.75)
                
                // Inner circle
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    .frame(width: chartSize * 0.5, height: chartSize * 0.5)
                
                // House numbers
                ForEach(1...12, id: \.self) { house in
                    Text("\(house)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.5))
                        .position(
                            x: chartSize/2 + (chartSize * 0.625/2) * cos(angleForIndex(house - 1) - .pi/2),
                            y: chartSize/2 + (chartSize * 0.625/2) * sin(angleForIndex(house - 1) - .pi/2)
                        )
                }
                
                // Planetary positions
                ForEach(Array(positions.keys.enumerated()), id: \.element) { index, planet in
                    if let position = positions[planet] {
                        PlanetView(
                            planet: planet,
                            position: position,
                            isSelected: selectedPlanet == planet,
                            chartSize: chartSize
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPlanet = selectedPlanet == planet ? nil : planet
                            }
                        }
                        .scaleEffect(animateChart ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
                            value: animateChart
                        )
                    }
                }
                
                // Center point
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 16, height: 16)
                            .scaleEffect(animateChart ? 1.5 : 1.0)
                            .opacity(animateChart ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: animateChart
                            )
                    )
            }
            .frame(width: chartSize, height: chartSize)
            
            // Selected planet info
            if let selected = selectedPlanet,
               let position = positions[selected] {
                VStack(spacing: 8) {
                    Text("\(selected)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("\(formatDegrees(position.position)) in \(getZodiacSign(for: position.position))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(getPlanetDescription(selected))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding()
                .background(.white.opacity(0.1))
                .cornerRadius(12)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateChart = true
            }
        }
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        Double(index) * (.pi * 2 / 12)
    }
    
    private func formatDegrees(_ degrees: Double) -> String {
        let zodiacDegrees = Int(degrees) % 30
        let minutes = Int((degrees - Double(Int(degrees))) * 60)
        return "\(zodiacDegrees)°\(String(format: "%02d", minutes))'"
    }
    
    private func getZodiacSign(for degrees: Double) -> String {
        let index = Int(degrees / 30)
        return zodiacNames[index % 12]
    }
    
    private func getPlanetDescription(_ planet: String) -> String {
        switch planet {
        case "Sun": return "Core identity and ego"
        case "Moon": return "Emotions and inner self"
        case "Mercury": return "Communication and thinking"
        case "Venus": return "Love and relationships"
        case "Mars": return "Action and desire"
        case "Jupiter": return "Growth and expansion"
        case "Saturn": return "Discipline and responsibility"
        default: return "Celestial influence"
        }
    }
}

struct PlanetView: View {
    let planet: String
    let position: DetailedPlanetaryPosition
    let isSelected: Bool
    let chartSize: CGFloat
    
    private var radius: CGFloat {
        // Place planets at different distances for visual clarity
        switch planet {
        case "Sun", "Moon": return chartSize * 0.35
        case "Mercury", "Venus": return chartSize * 0.3
        default: return chartSize * 0.25
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(planetColor(for: planet))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1.2 : 1.0)
                    )
                
                Image(systemName: planetIcon(for: planet))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Text(planet.prefix(3))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .position(
            x: chartSize/2 + radius * cos(position.position * .pi / 180 - .pi/2),
            y: chartSize/2 + radius * sin(position.position * .pi / 180 - .pi/2)
        )
        .scaleEffect(isSelected ? 1.1 : 1.0)
    }
}

private func planetIcon(for planet: String) -> String {
    switch planet {
    case "Sun": return "sun.max.fill"
    case "Moon": return "moon.fill"
    case "Mercury": return "sparkle"
    case "Venus": return "heart.fill"
    case "Mars": return "arrow.up.circle.fill"
    case "Jupiter": return "largecircle.fill.circle"
    case "Saturn": return "hexagon.fill"
    default: return "circle.fill"
    }
}

private func planetColor(for planet: String) -> Color {
    switch planet {
    case "Sun": return .orange
    case "Moon": return .gray
    case "Mercury": return .cyan
    case "Venus": return .pink
    case "Mars": return .red
    case "Jupiter": return .purple
    case "Saturn": return .brown
    default: return .blue
    }
}