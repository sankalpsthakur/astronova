import AppIntents
import Foundation

/// App Intents for Siri Shortcuts integration
@available(iOS 16.0, *)
struct GetTodaysHoroscopeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Horoscope"
    static var description: IntentDescription? = IntentDescription("Get your personalized horoscope for today")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get my horoscope for today")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Fetch today's horoscope
        let horoscope = await fetchTodaysHoroscope()
        return .result(value: horoscope)
    }
    
    private func fetchTodaysHoroscope() async -> String {
        // In a real implementation, this would call the app's API
        let horoscopes = [
            "The cosmos aligns in your favor today. Trust your intuition and embrace new opportunities that come your way.",
            "Today brings powerful energies for transformation and growth. The planetary alignments suggest this is an excellent time for introspection.",
            "Cosmic currents flow strongly in your direction. This is a perfect time for manifestation and setting new intentions.",
            "The universe recognizes your unique frequency today. You are being called to step into your power and embrace the magic that flows through you.",
            "Today's celestial dance brings opportunities for deep connection and spiritual awakening. Stay open to the signs around you."
        ]
        
        return horoscopes.randomElement() ?? horoscopes[0]
    }
}

@available(iOS 16.0, *)
struct CheckCompatibilityIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Compatibility"
    static var description: IntentDescription? = IntentDescription("Check astrological compatibility with someone")
    
    @Parameter(title: "Person's Name", description: "Name of the person to check compatibility with")
    var personName: String
    
    @Parameter(title: "Birth Date", description: "Birth date of the person", default: Date())
    var birthDate: Date?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Check compatibility with \(\.$personName)") {
            \.$birthDate
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let compatibility = await checkCompatibility(with: personName, birthDate: birthDate)
        return .result(value: compatibility)
    }
    
    private func checkCompatibility(with name: String, birthDate: Date?) async -> String {
        // In a real implementation, this would calculate actual astrological compatibility
        let compatibilityLevels = [
            "✨ Cosmic Connection: You and \(name) share a powerful celestial bond! The stars align beautifully between you.",
            "🌟 Harmonious Energy: There's natural compatibility between you and \(name). Your cosmic energies complement each other well.",
            "🌙 Gentle Balance: You and \(name) have complementary traits that can create a balanced dynamic when you work together.",
            "⭐ Growing Potential: The compatibility between you and \(name) has room to flourish with understanding and patience.",
            "🌌 Cosmic Learning: You and \(name) offer each other opportunities for growth through your different cosmic perspectives."
        ]
        
        return compatibilityLevels.randomElement() ?? compatibilityLevels[0]
    }
}

@available(iOS 16.0, *)
struct GetCurrentTransitsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Current Planetary Transits"
    static var description: IntentDescription? = IntentDescription("Get information about current planetary movements and their effects")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get current planetary transits")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let transits = await getCurrentTransits()
        return .result(value: transits)
    }
    
    private func getCurrentTransits() async -> String {
        let transitInfo = [
            "🌙 Moon in Sagittarius brings adventurous energy and a desire for expansion. Perfect time for exploring new philosophies.",
            "⚡ Mercury in Gemini enhances communication and quick thinking. Your words carry extra power today.",
            "💖 Venus in Taurus emphasizes love, beauty, and material pleasures. Focus on what brings you joy and comfort.",
            "🔥 Mars in Aries ignites passion and initiative. This is a powerful time for taking action on your goals.",
            "🌟 Jupiter in Pisces expands intuition and spiritual awareness. Trust your inner wisdom more than ever."
        ]
        
        return transitInfo.randomElement() ?? transitInfo[0]
    }
}

@available(iOS 16.0, *)
struct OpenAstronovaIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Astronova"
    static var description: IntentDescription? = IntentDescription("Open the Astronova app")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Open Astronova app")
    }
    
    func perform() async throws -> some IntentResult & OpensIntent {
        return .result()
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct AstronovaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodaysHoroscopeIntent(),
            phrases: [
                "Get my horoscope in \(.applicationName)",
                "Show my daily horoscope",
                "What's my horoscope today in \(.applicationName)",
                "Tell me my horoscope"
            ],
            shortTitle: "Today's Horoscope",
            systemImageName: "sparkles"
        )
        
        AppShortcut(
            intent: CheckCompatibilityIntent(),
            phrases: [
                "Check compatibility in \(.applicationName)",
                "How compatible am I with someone",
                "Check my compatibility in \(.applicationName)"
            ],
            shortTitle: "Check Compatibility",
            systemImageName: "heart.circle"
        )
        
        AppShortcut(
            intent: GetCurrentTransitsIntent(),
            phrases: [
                "Get planetary transits in \(.applicationName)",
                "What are the current transits",
                "Show me planetary movements"
            ],
            shortTitle: "Current Transits",
            systemImageName: "globe"
        )
        
        AppShortcut(
            intent: OpenAstronovaIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Launch \(.applicationName)",
                "Start \(.applicationName)"
            ],
            shortTitle: "Open App",
            systemImageName: "app"
        )
    }
}

// MARK: - Intent Entities

@available(iOS 16.0, *)
struct AstrologySign: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Astrology Sign"
    
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    let name: String
    let symbol: String
    let element: String
    
    static var defaultQuery = AstrologySignQuery()
    
    init(id: String, name: String, symbol: String, element: String) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.element = element
    }
}

@available(iOS 16.0, *)
struct AstrologySignQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AstrologySign] {
        return allSigns.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [AstrologySign] {
        return allSigns
    }
    
    func defaultResult() async -> AstrologySign? {
        return allSigns.first
    }
    
    private var allSigns: [AstrologySign] {
        [
            AstrologySign(id: "aries", name: "Aries", symbol: "♈", element: "Fire"),
            AstrologySign(id: "taurus", name: "Taurus", symbol: "♉", element: "Earth"),
            AstrologySign(id: "gemini", name: "Gemini", symbol: "♊", element: "Air"),
            AstrologySign(id: "cancer", name: "Cancer", symbol: "♋", element: "Water"),
            AstrologySign(id: "leo", name: "Leo", symbol: "♌", element: "Fire"),
            AstrologySign(id: "virgo", name: "Virgo", symbol: "♍", element: "Earth"),
            AstrologySign(id: "libra", name: "Libra", symbol: "♎", element: "Air"),
            AstrologySign(id: "scorpio", name: "Scorpio", symbol: "♏", element: "Water"),
            AstrologySign(id: "sagittarius", name: "Sagittarius", symbol: "♐", element: "Fire"),
            AstrologySign(id: "capricorn", name: "Capricorn", symbol: "♑", element: "Earth"),
            AstrologySign(id: "aquarius", name: "Aquarius", symbol: "♒", element: "Air"),
            AstrologySign(id: "pisces", name: "Pisces", symbol: "♓", element: "Water")
        ]
    }
}