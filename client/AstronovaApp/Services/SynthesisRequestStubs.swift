import Foundation

// MARK: - Request Type Stubs (until APIModels.swift is restored)

/// Birth data submitted to synthesis / prediction endpoints.
struct BirthDataRequest: Codable {
    let date: String
    let time: String
    let timezone: String
    let latitude: Double
    let longitude: Double
}

/// Dasha state for synthesis / prediction context.
struct DashaStateRequest: Codable {
    let mahadashaLord: String
    let antardashaLord: String
    let mahadashaStart: String
    let mahadashaEnd: String

    enum CodingKeys: String, CodingKey {
        case mahadashaLord = "mahadasha_lord"
        case antardashaLord = "antardasha_lord"
        case mahadashaStart = "mahadasha_start"
        case mahadashaEnd = "mahadasha_end"
    }
}

/// User prior signals for personalization.
struct UserPriorsRequest: Codable {
    let userId: String
    let projects: [String]
    let careerTarget: String?
    let location: String?
    let currentFocus: String?
    let contextTags: [String]
    let freeTextContext: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case projects
        case careerTarget = "career_target"
        case location
        case currentFocus = "current_focus"
        case contextTags = "context_tags"
        case freeTextContext = "free_text_context"
    }

    init(
        userId: String,
        projects: [String] = [],
        careerTarget: String? = nil,
        location: String? = nil,
        currentFocus: String? = nil,
        contextTags: [String] = [],
        freeTextContext: String? = nil
    ) {
        self.userId = userId
        self.projects = projects
        self.careerTarget = careerTarget
        self.location = location
        self.currentFocus = currentFocus
        self.contextTags = contextTags
        self.freeTextContext = freeTextContext
    }

    static func fromStoredOnboarding(
        userId: String = ClientUserId.value(),
        defaults: UserDefaults = .standard
    ) -> UserPriorsRequest? {
        let tags = storedContextTags(defaults: defaults)
        let freeText = defaults.string(forKey: "profile_context_text")?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !tags.isEmpty || !(freeText?.isEmpty ?? true) else {
            return nil
        }

        return UserPriorsRequest(
            userId: userId,
            projects: projects(from: tags, freeText: freeText),
            careerTarget: careerTarget(from: tags),
            location: location(from: tags, freeText: freeText),
            currentFocus: currentFocus(from: tags, freeText: freeText),
            contextTags: tags,
            freeTextContext: freeText?.isEmpty == false ? freeText : nil
        )
    }

    static func storedPhoneDigitSum(defaults: UserDefaults = .standard) -> Int? {
        let digits = defaults.string(forKey: "profile_phone_digits") ?? ""
        let values = digits.compactMap { Int(String($0)) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }

    private static func storedContextTags(defaults: UserDefaults) -> [String] {
        (defaults.string(forKey: "profile_context_tags") ?? "")
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static func projects(from tags: [String], freeText: String?) -> [String] {
        var projects: [String] = []
        if tags.contains("forge") { projects.append("Building a company") }
        if tags.contains("cap") { projects.append("Raising capital") }
        if tags.contains("voice") { projects.append("Writing / public output") }

        if let freeText, !freeText.isEmpty {
            projects.append(freeText)
        }

        return projects
    }

    private static func careerTarget(from tags: [String]) -> String? {
        if tags.contains("job") { return "Career transition" }
        if tags.contains("forge") || tags.contains("cap") { return "Company building" }
        return nil
    }

    private static func location(from tags: [String], freeText: String?) -> String? {
        if tags.contains("reloc") { return "Considering relocation" }

        let lower = (freeText ?? "").lowercased()
        let knownLocations = ["dubai", "singapore", "london", "new york", "mumbai", "delhi", "bangalore"]
        if let match = knownLocations.first(where: { lower.contains($0) }) {
            return match.capitalized
        }

        return nil
    }

    private static func currentFocus(from tags: [String], freeText: String?) -> String? {
        let labels: [String: String] = [
            "rel": "New relationship",
            "body": "Health rebuild",
            "home": "Buying property",
            "law": "Legal / litigation",
            "voice": "Writing / public output",
            "cap": "Raising capital",
            "forge": "Building a company"
        ]

        let focus = tags.compactMap { labels[$0] }.joined(separator: ", ")
        if !focus.isEmpty { return focus }
        return freeText?.isEmpty == false ? freeText : nil
    }
}

/// Planet position used to seed the synthesis backend.
struct PlanetPositionData: Codable {
    let sign: String
    let degree: Double
    let house: Int
    let retrograde: Bool
}
