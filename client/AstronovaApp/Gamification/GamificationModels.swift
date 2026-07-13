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

    var weeklyChallenge: String {
        switch self {
        case .love:
            return "Share your daily insight card with someone."
        case .career:
            return "Take one meaningful guidance action in Oracle."
        case .calm:
            return "Complete one calm reset."
        case .focus:
            return "Open Timeline and review one snapshot."
        }
    }

    var weeklyChallengeRewardText: String {
        switch self {
        case .love: return "Love +12 XP"
        case .career: return "Career +12 XP"
        case .calm: return "Calm +12 XP"
        case .focus: return "Focus +12 XP"
        }
    }
}

enum JourneyMilestone: String, Codable, CaseIterable {
    case firstDailySignal
    case firstOracleAction
    case firstTimeTravelSnapshot
    case firstShare
    case weeklyChapterComplete
    case weeklyChallengeComplete

    var title: String {
        switch self {
        case .firstDailySignal: return "First Signal"
        case .firstOracleAction: return "First Oracle Action"
        case .firstTimeTravelSnapshot: return "First Timeline Snapshot"
        case .firstShare: return "First Share"
        case .weeklyChapterComplete: return "Weekly Chapter"
        case .weeklyChallengeComplete: return "Weekly Challenge"
        }
    }

    var subtitle: String {
        switch self {
        case .firstDailySignal: return "Draw your first daily card."
        case .firstOracleAction: return "Ask the Oracle once."
        case .firstTimeTravelSnapshot: return "Generate a snapshot."
        case .firstShare: return "Share an insight card."
        case .weeklyChallengeComplete: return "Complete this week's challenge."
        case .weeklyChapterComplete: return "Complete 7 daily signals this week."
        }
    }
}
