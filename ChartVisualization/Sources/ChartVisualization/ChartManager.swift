import Foundation
import SwiftUI

/// Manages chart generation, caching, and integration with chat features.
public final class ChartManager: ObservableObject {
    @Published public private(set) var currentChart: AstrologicalChart?
    @Published public private(set) var transitPlanets: [ChartPlanet]?
    @Published public private(set) var isCalculating = false
    @Published public private(set) var error: ChartError?
    
    private let calculator = ChartCalculator()
    private var chartCache: [String: AstrologicalChart] = [:]
    
    public init() {}
    
    // MARK: - Public API
    
    /// Generates a birth chart for the given user profile.
    @MainActor
    public func generateBirthChart(for userProfile: UserProfile, type: ChartType = .siderealBirth) async {
        isCalculating = true
        error = nil
        
        do {
            let birthData = createBirthData(from: userProfile)
            let cacheKey = "\(birthData.date.timeIntervalSince1970)_\(type.rawValue)"
            
            if let cachedChart = chartCache[cacheKey] {
                currentChart = cachedChart
            } else {
                let chart = calculator.calculateChart(for: birthData, type: type)
                chartCache[cacheKey] = chart
                currentChart = chart
            }
            
            // Calculate transits if this is a birth chart
            if !type.isTransitChart {
                transitPlanets = calculator.calculateTransits(for: currentChart!)
            }
            
        } catch {
            self.error = .calculationFailed(error.localizedDescription)
        }
        
        isCalculating = false
    }
    
    /// Generates a transit chart for current planetary positions.
    @MainActor
    public func generateTransitChart(for userProfile: UserProfile, sidereal: Bool = true) async {
        let type: ChartType = sidereal ? .siderealTransit : .tropicalTransit
        await generateBirthChart(for: userProfile, type: type)
    }
    
    /// Updates transit positions to current time.
    @MainActor
    public func refreshTransits() async {
        guard let chart = currentChart, !chart.chartType.isTransitChart else { return }
        
        isCalculating = true
        transitPlanets = calculator.calculateTransits(for: chart)
        isCalculating = false
    }
    
    /// Generates chart interpretation text for chat integration.
    public func generateChartDescription(isPremium: Bool = false) -> String {
        guard let chart = currentChart else {
            return "No chart available for analysis."
        }
        
        var description = "**\(chart.chartType.rawValue)**\n\n"
        
        // Basic planetary positions
        description += "**Planetary Positions:**\n"
        for planet in chart.planets.prefix(isPremium ? chart.planets.count : 3) {
            let retrograde = planet.isRetrograde ? " (Retrograde)" : ""
            description += "• \(planet.symbol) \(planet.name): \(planet.sign.rawValue) \(Int(planet.degree))°\(Int(planet.minute))'\(retrograde)\n"
        }
        
        if !isPremium && chart.planets.count > 3 {
            description += "• *...and \(chart.planets.count - 3) more planets (Premium)*\n"
        }
        
        // Houses (basic for free users)
        description += "\n**House System:**\n"
        let housesToShow = isPremium ? 12 : 4
        for house in chart.houses.prefix(housesToShow) {
            description += "• House \(house.number): \(house.sign.symbol) \(house.sign.rawValue) - \(house.interpretation)\n"
        }
        
        if !isPremium {
            description += "• *...and \(12 - housesToShow) more houses (Premium)*\n"
        }
        
        // Aspects (premium only)
        if isPremium && !chart.aspects.isEmpty {
            description += "\n**Major Aspects:**\n"
            for aspect in chart.aspects.prefix(5) {
                let harmoniousText = aspect.type.isHarmonious ? "harmonious" : "challenging"
                description += "• \(aspect.planet1.symbol) \(aspect.type.rawValue) \(aspect.planet2.symbol) (\(harmoniousText))\n"
            }
            
            if chart.aspects.count > 5 {
                description += "• *...and \(chart.aspects.count - 5) more aspects*\n"
            }
        } else if !isPremium && !chart.aspects.isEmpty {
            description += "\n**Aspects:** *\(chart.aspects.count) aspects available with Premium*\n"
        }
        
        // Transits (premium only)
        if isPremium, let transits = transitPlanets {
            description += "\n**Current Transits:**\n"
            for transit in transits.prefix(3) {
                description += "• Transit \(transit.symbol): \(transit.sign.rawValue) \(Int(transit.degree))°\n"
            }
        } else if !isPremium && transitPlanets != nil {
            description += "\n**Current Transits:** *Available with Premium upgrade*\n"
        }
        
        return description
    }
    
    /// Creates a chart summary for AI context.
    public func generateAIContext() -> String {
        guard let chart = currentChart else { return "No chart data available." }
        
        var context = "Birth Chart Data:\n"
        context += "Chart Type: \(chart.chartType.rawValue)\n"
        context += "Birth Date: \(chart.birthData.birthDate)\n"
        
        // Planetary positions for AI understanding
        context += "Planets:\n"
        for planet in chart.planets {
            context += "\(planet.name): \(planet.sign.rawValue) \(Int(planet.degree))° (House \(planet.house))\n"
        }
        
        // Key aspects for AI context
        if !chart.aspects.isEmpty {
            context += "Major Aspects:\n"
            for aspect in chart.aspects.prefix(5) {
                context += "\(aspect.planet1.name) \(aspect.type.rawValue) \(aspect.planet2.name)\n"
            }
        }
        
        return context
    }
    
    // MARK: - Chart Analysis Methods
    
    /// Analyzes specific planetary placement for chat responses.
    public func analyzePlanet(_ planetName: String) -> String? {
        guard let chart = currentChart,
              let planet = chart.planets.first(where: { $0.name.lowercased() == planetName.lowercased() }) else {
            return nil
        }
        
        var analysis = "\(planet.symbol) **\(planet.name)** in \(planet.sign.rawValue):\n"
        analysis += "• Position: \(Int(planet.degree))°\(Int(planet.minute))' \(planet.sign.rawValue)\n"
        analysis += "• House: \(planet.house) (\(chart.houses[planet.house - 1].interpretation))\n"
        
        if planet.isRetrograde {
            analysis += "• Status: Retrograde motion\n"
        }
        
        // Find aspects to this planet
        let planetAspects = chart.aspects.filter { 
            $0.planet1.name == planet.name || $0.planet2.name == planet.name 
        }
        
        if !planetAspects.isEmpty {
            analysis += "• Key Aspects:\n"
            for aspect in planetAspects.prefix(3) {
                let otherPlanet = aspect.planet1.name == planet.name ? aspect.planet2 : aspect.planet1
                analysis += "  - \(aspect.type.rawValue) with \(otherPlanet.name)\n"
            }
        }
        
        return analysis
    }
    
    /// Gets current transit for a specific planet.
    public func getCurrentTransit(for planetName: String) -> String? {
        guard let transits = transitPlanets,
              let transit = transits.first(where: { $0.name.lowercased() == planetName.lowercased() }) else {
            return nil
        }
        
        return "Current \(transit.name) Transit: \(transit.sign.rawValue) \(Int(transit.degree))°\(Int(transit.minute))'"
    }
    
    // MARK: - Private Methods
    
    private func createBirthData(from userProfile: UserProfile) -> BirthData {
        return BirthData(
            date: userProfile.birthDate,
            time: userProfile.birthTime,
            location: userProfile.birthPlace
        )
    }
}

// MARK: - Error Types

public enum ChartError: Error, LocalizedError {
    case calculationFailed(String)
    case invalidBirthData
    case ephemerisError
    
    public var errorDescription: String? {
        switch self {
        case .calculationFailed(let message):
            return "Chart calculation failed: \(message)"
        case .invalidBirthData:
            return "Invalid birth data provided"
        case .ephemerisError:
            return "Ephemeris calculation error"
        }
    }
}

// MARK: - Chart Integration Helpers

extension ChartManager {
    /// Determines if a chart feature requires premium access.
    public func requiresPremium(for feature: ChartFeature) -> Bool {
        switch feature {
        case .birthChart, .basicPlanets, .houses:
            return false
        case .aspects, .transits, .progressions, .returns:
            return true
        }
    }
    
    /// Creates a teaser message for premium features.
    public func createPremiumTeaser(for feature: ChartFeature) -> String {
        switch feature {
        case .aspects:
            return "🔒 **Premium Feature**: View detailed planetary aspects and their interpretations"
        case .transits:
            return "🔒 **Premium Feature**: See current planetary transits and their effects"
        case .progressions:
            return "🔒 **Premium Feature**: Explore progressed chart positions"
        case .returns:
            return "🔒 **Premium Feature**: Calculate solar and lunar returns"
        default:
            return "🔒 **Premium Feature**: Unlock advanced astrological analysis"
        }
    }
}

public enum ChartFeature {
    case birthChart
    case basicPlanets
    case houses
    case aspects
    case transits
    case progressions
    case returns
}