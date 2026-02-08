import Foundation

enum SeekerLevel: String, Codable, CaseIterable {
    case seeker
    case alchemist
    case oracle

    var title: String {
        switch self {
        case .seeker: return "Seeker"
        case .alchemist: return "Alchemist"
        case .oracle: return "Oracle"
        }
    }

    /// Inclusive lower bound XP required for this level.
    var minXP: Int {
        switch self {
        case .seeker: return 0
        case .alchemist: return 200
        case .oracle: return 500
        }
    }
}

struct ArcanaCard: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let prompt: String

    func shareText(archetype: String?, theme: WeeklyTheme?) -> String {
        var parts: [String] = []
        if let theme {
            parts.append("Weekly theme: \(theme.title)")
        }
        if let archetype, !archetype.isEmpty {
            parts.append("Archetype: \(archetype)")
        }
        parts.append("Today's signal: \(title)")
        parts.append(subtitle)
        parts.append("Reflection: \(prompt)")
        parts.append("Astronova")
        return parts.joined(separator: "\n")
    }
}

enum WeeklyTheme: String, Codable, CaseIterable {
    case love
    case career
    case calm
    case focus

    var title: String {
        switch self {
        case .love: return "Love"
        case .career: return "Career"
        case .calm: return "Calm"
        case .focus: return "Focus"
        }
    }
}

enum JourneyMilestone: String, Codable, CaseIterable {
    case firstDailySignal
    case firstOracleAction
    case firstTimeTravelSnapshot
    case firstTempleBooking
    case firstShare
    case weeklyChapterComplete
    case firstTempleBellRing
    case templeBellStreak7
    case templeBellStreak30
    case firstDIYPooja

    var title: String {
        switch self {
        case .firstDailySignal: return "First Signal"
        case .firstOracleAction: return "First Oracle Action"
        case .firstTimeTravelSnapshot: return "First Time Travel"
        case .firstTempleBooking: return "First Temple Booking"
        case .firstShare: return "First Share"
        case .weeklyChapterComplete: return "Weekly Chapter"
        case .firstTempleBellRing: return "First Bell Ring"
        case .templeBellStreak7: return "7-Day Bell Streak"
        case .templeBellStreak30: return "30-Day Bell Streak"
        case .firstDIYPooja: return "First DIY Pooja"
        }
    }

    var subtitle: String {
        switch self {
        case .firstDailySignal: return "Draw your first daily card."
        case .firstOracleAction: return "Ask the Oracle once."
        case .firstTimeTravelSnapshot: return "Generate a snapshot."
        case .firstTempleBooking: return "Start a booking."
        case .firstShare: return "Share an insight card."
        case .weeklyChapterComplete: return "Complete a week of practice."
        case .firstTempleBellRing: return "Ring the temple bell for the first time."
        case .templeBellStreak7: return "Ring the bell 7 days in a row."
        case .templeBellStreak30: return "Ring the bell 30 days in a row."
        case .firstDIYPooja: return "Complete your first DIY pooja."
        }
    }
}
