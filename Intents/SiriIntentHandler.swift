import Foundation
import Intents
import IntentsUI

/// Legacy Siri Intent Handler for broader iOS compatibility
class SiriIntentHandler: NSObject, INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        return self
    }
}

// MARK: - Get Horoscope Intent Handler

extension SiriIntentHandler: GetHoroscopeIntentHandling {
    
    func handle(intent: GetHoroscopeIntent, completion: @escaping (GetHoroscopeIntentResponse) -> Void) {
        // Fetch horoscope data
        Task {
            let horoscope = await fetchHoroscopeData()
            let response = GetHoroscopeIntentResponse(code: .success, userActivity: nil)
            response.horoscopeText = horoscope
            completion(response)
        }
    }
    
    func resolveDate(for intent: GetHoroscopeIntent, with completion: @escaping (INDateComponentsResolution) -> Void) {
        let date = intent.date ?? DateComponents(calendar: Calendar.current, year: 2024, month: 1, day: 1)
        completion(INDateComponentsResolution.success(with: date))
    }
    
    private func fetchHoroscopeData() async -> String {
        // In a real implementation, this would call the backend API
        let horoscopes = [
            "The cosmos aligns in your favor today. Trust your intuition and embrace new opportunities.",
            "Today brings powerful energies for transformation and growth. Focus on your inner wisdom.",
            "Cosmic currents flow strongly in your direction. This is a perfect time for manifestation.",
            "The universe recognizes your unique frequency today. Step into your power with confidence.",
            "Today's celestial dance brings opportunities for deep connection and spiritual awakening."
        ]
        
        return horoscopes.randomElement() ?? horoscopes[0]
    }
}

// MARK: - Check Compatibility Intent Handler

extension SiriIntentHandler: CheckCompatibilityIntentHandling {
    
    func handle(intent: CheckCompatibilityIntent, completion: @escaping (CheckCompatibilityIntentResponse) -> Void) {
        Task {
            let compatibility = await checkCompatibilityData(
                firstPerson: intent.firstPersonName ?? "You",
                secondPerson: intent.secondPersonName ?? "Someone"
            )
            
            let response = CheckCompatibilityIntentResponse(code: .success, userActivity: nil)
            response.compatibilityResult = compatibility
            completion(response)
        }
    }
    
    func resolveFirstPersonName(for intent: CheckCompatibilityIntent, with completion: @escaping (INStringResolution) -> Void) {
        if let name = intent.firstPersonName, !name.isEmpty {
            completion(INStringResolution.success(with: name))
        } else {
            completion(INStringResolution.needsValue())
        }
    }
    
    func resolveSecondPersonName(for intent: CheckCompatibilityIntent, with completion: @escaping (INStringResolution) -> Void) {
        if let name = intent.secondPersonName, !name.isEmpty {
            completion(INStringResolution.success(with: name))
        } else {
            completion(INStringResolution.needsValue())
        }
    }
    
    private func checkCompatibilityData(firstPerson: String, secondPerson: String) async -> String {
        let compatibilityResults = [
            "✨ Cosmic Connection: \(firstPerson) and \(secondPerson) share a powerful celestial bond!",
            "🌟 Harmonious Energy: Natural compatibility flows between \(firstPerson) and \(secondPerson).",
            "🌙 Gentle Balance: \(firstPerson) and \(secondPerson) have complementary cosmic traits.",
            "⭐ Growing Potential: The compatibility between \(firstPerson) and \(secondPerson) has room to flourish.",
            "🌌 Cosmic Learning: \(firstPerson) and \(secondPerson) offer each other opportunities for growth."
        ]
        
        return compatibilityResults.randomElement() ?? compatibilityResults[0]
    }
}

// MARK: - Open App Intent Handler

extension SiriIntentHandler: OpenAstronovaAppIntentHandling {
    
    func handle(intent: OpenAstronovaAppIntent, completion: @escaping (OpenAstronovaAppIntentResponse) -> Void) {
        // Create user activity to open the app
        let userActivity = NSUserActivity(activityType: "com.sankalp.AstronovaApp.openApp")
        userActivity.title = "Open Astronova"
        userActivity.userInfo = ["action": "openApp"]
        
        let response = OpenAstronovaAppIntentResponse(code: .continueInApp, userActivity: userActivity)
        completion(response)
    }
}

// MARK: - Donations for Better Siri Learning

class SiriShortcutDonationManager {
    static let shared = SiriShortcutDonationManager()
    
    private init() {}
    
    func donateGetHoroscopeShortcut() {
        let intent = GetHoroscopeIntent()
        intent.date = DateComponents(calendar: Calendar.current, year: 2024, month: 1, day: 1)
        intent.suggestedInvocationPhrase = "Get my horoscope"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "getHoroscope"
        interaction.donate { error in
            if let error = error {
                print("Failed to donate horoscope shortcut: \(error)")
            } else {
                print("Successfully donated horoscope shortcut")
            }
        }
    }
    
    func donateCompatibilityShortcut(firstPerson: String, secondPerson: String) {
        let intent = CheckCompatibilityIntent()
        intent.firstPersonName = firstPerson
        intent.secondPersonName = secondPerson
        intent.suggestedInvocationPhrase = "Check compatibility with \(secondPerson)"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "checkCompatibility_\(firstPerson)_\(secondPerson)"
        interaction.donate { error in
            if let error = error {
                print("Failed to donate compatibility shortcut: \(error)")
            } else {
                print("Successfully donated compatibility shortcut")
            }
        }
    }
    
    func donateOpenAppShortcut() {
        let intent = OpenAstronovaAppIntent()
        intent.suggestedInvocationPhrase = "Open Astronova"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "openAstronova"
        interaction.donate { error in
            if let error = error {
                print("Failed to donate open app shortcut: \(error)")
            } else {
                print("Successfully donated open app shortcut")
            }
        }
    }
}

// MARK: - Extension for App Delegate Integration

extension SiriShortcutDonationManager {
    func setupShortcutsOnAppLaunch() {
        // Donate commonly used shortcuts when app launches
        donateGetHoroscopeShortcut()
        donateOpenAppShortcut()
    }
    
    func donateContextualShortcuts(for action: String, with parameters: [String: Any] = [:]) {
        switch action {
        case "viewedHoroscope":
            donateGetHoroscopeShortcut()
        case "checkedCompatibility":
            if let firstPerson = parameters["firstPerson"] as? String,
               let secondPerson = parameters["secondPerson"] as? String {
                donateCompatibilityShortcut(firstPerson: firstPerson, secondPerson: secondPerson)
            }
        default:
            break
        }
    }
}