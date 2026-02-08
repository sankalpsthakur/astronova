import Foundation
import SwiftUI

@MainActor
final class GamificationManager: ObservableObject {
    static let shared = GamificationManager()

    @Published private(set) var xp: Int
    @Published private(set) var streak: Int
    @Published private(set) var lastCheckInDay: String?
    @Published private(set) var unlockedCardIds: Set<String>
    @Published private(set) var milestones: Set<JourneyMilestone>
    @Published private(set) var archetype: String?
    @Published private(set) var lastTimeTravelXPDay: String?
    @Published private(set) var weeklyChapterKey: String?
    @Published private(set) var weeklyChapterCheckIns: Int

    @Published var currentDailyCard: ArcanaCard?

    private let storageKey = "gamification_state_v1"
    private let calendar = Calendar.current

    private struct PersistedState: Codable {
        var xp: Int
        var streak: Int
        var lastCheckInDay: String?
        var lastTimeTravelXPDay: String?
        var weeklyChapterKey: String?
        var weeklyChapterCheckIns: Int
        var unlockedCardIds: [String]
        var milestones: [JourneyMilestone]
        var archetype: String?
    }

    init() {
        if let loaded = Self.load(storageKey: storageKey) {
            xp = loaded.xp
            streak = loaded.streak
            lastCheckInDay = loaded.lastCheckInDay
            lastTimeTravelXPDay = loaded.lastTimeTravelXPDay
            weeklyChapterKey = loaded.weeklyChapterKey
            weeklyChapterCheckIns = loaded.weeklyChapterCheckIns
            unlockedCardIds = Set(loaded.unlockedCardIds)
            milestones = Set(loaded.milestones)
            archetype = loaded.archetype
        } else {
            xp = 0
            streak = 0
            lastCheckInDay = nil
            lastTimeTravelXPDay = nil
            weeklyChapterKey = nil
            weeklyChapterCheckIns = 0
            unlockedCardIds = []
            milestones = []
            archetype = nil
        }
    }

    var level: SeekerLevel {
        // Highest matching level by minXP.
        SeekerLevel.allCases
            .sorted { $0.minXP < $1.minXP }
            .last(where: { xp >= $0.minXP }) ?? .seeker
    }

    var nextLevel: SeekerLevel? {
        let ordered = SeekerLevel.allCases.sorted { $0.minXP < $1.minXP }
        guard let idx = ordered.firstIndex(of: level) else { return nil }
        let nextIdx = idx + 1
        return nextIdx < ordered.count ? ordered[nextIdx] : nil
    }

    var xpProgressToNextLevel: Double {
        guard let next = nextLevel else { return 1.0 }
        let start = level.minXP
        let end = next.minXP
        if end <= start { return 1.0 }
        return min(1.0, max(0.0, Double(xp - start) / Double(end - start)))
    }

    func weeklyTheme(for date: Date = Date()) -> WeeklyTheme {
        let week = calendar.component(.weekOfYear, from: date)
        let themes = WeeklyTheme.allCases
        return themes[abs(week) % themes.count]
    }

    // MARK: - Onboarding

    func setArchetype(_ archetype: String) {
        self.archetype = archetype
        persist()
    }

    // MARK: - Daily Return

    /// Returns the daily card and whether this draw was a new check-in (streak/xp awarded).
    @discardableResult
    func drawTodaysSignal(now: Date = Date()) -> (card: ArcanaCard, isNewCheckIn: Bool) {
        let dayKey = Self.dayKey(now)
        let card = Self.dailyCard(for: dayKey, archetype: archetype)
        currentDailyCard = card

        let isNew = (lastCheckInDay != dayKey)
        if isNew {
            let didContinue = Self.isYesterdayKey(Self.dayKey(now.addingTimeInterval(-24 * 60 * 60)), comparedTo: lastCheckInDay)
            streak = didContinue ? (streak + 1) : 1
            lastCheckInDay = dayKey

            awardXP(15, event: .streakCheckIn, properties: ["day": dayKey])
            unlockCardIfNeeded(card)
            unlockMilestone(.firstDailySignal)

            // Retention: weekly chapter completion as narrative progression.
            let chapterKey = Self.weekKey(now)
            if weeklyChapterKey != chapterKey {
                weeklyChapterKey = chapterKey
                weeklyChapterCheckIns = 0
            }
            weeklyChapterCheckIns += 1
            if weeklyChapterCheckIns == 5 {
                awardXP(30, event: .weeklyChapterCompleted, properties: ["chapter": chapterKey])
                unlockMilestone(.weeklyChapterComplete)
            }
        }

        persist()
        return (card, isNew)
    }

    func markShared() {
        awardXP(5, event: .insightShared, properties: nil)
        unlockMilestone(.firstShare)
        persist()
    }

    // MARK: - Core Flow Hooks

    func markOracleAction() {
        awardXP(20, event: .oracleActionCompleted, properties: nil)
        unlockMilestone(.firstOracleAction)
        persist()
    }

    func markTimeTravelSnapshot() {
        let dayKey = Self.dayKey(Date())
        if lastTimeTravelXPDay != dayKey {
            lastTimeTravelXPDay = dayKey
            awardXP(10, event: .timeTravelSnapshotViewed, properties: ["day": dayKey])
        }
        unlockMilestone(.firstTimeTravelSnapshot)
        persist()
    }

    func markTempleBookingStarted() {
        awardXP(25, event: .templeEngagementCompleted, properties: ["stage": "started"])
        unlockMilestone(.firstTempleBooking)
        persist()
    }

    func markTempleBookingCompleted() {
        awardXP(40, event: .templeEngagementCompleted, properties: ["stage": "completed"])
        persist()
    }

    func markTempleBellRung(streak: Int) {
        awardXP(10, event: .templeBellRung, properties: ["streak": "\(streak)"])
        unlockMilestone(.firstTempleBellRing)
        if streak == 7 {
            awardXP(50, event: .templeBellStreakBonus, properties: ["streak": "7"])
            unlockMilestone(.templeBellStreak7)
        }
        if streak == 30 {
            awardXP(200, event: .templeBellStreakBonus, properties: ["streak": "30"])
            unlockMilestone(.templeBellStreak30)
        }
        persist()
    }

    func markDIYPoojaCompleted(poojaName: String) {
        awardXP(25, event: .diyPoojaCompleted, properties: ["pooja_name": poojaName])
        unlockMilestone(.firstDIYPooja)
        persist()
    }

    func markMuhuratChecked() {
        awardXP(5, event: .muhuratChecked, properties: nil)
        persist()
    }

    func markVedicEntryRead(entryId: String) {
        awardXP(5, event: .vedicEntryRead, properties: ["entry_id": entryId])
        persist()
    }

    // MARK: - Internals

    private func unlockCardIfNeeded(_ card: ArcanaCard) {
        let inserted = unlockedCardIds.insert(card.id).inserted
        if inserted {
            Analytics.shared.track(.cardUnlocked, properties: ["card_id": card.id])
        }
    }

    private func unlockMilestone(_ milestone: JourneyMilestone) {
        let inserted = milestones.insert(milestone).inserted
        if inserted {
            Analytics.shared.track(.journeyMilestoneUnlocked, properties: ["milestone": milestone.rawValue])
            if milestone == .firstOracleAction {
                Analytics.shared.track(.activationOracleAction, properties: nil)
            }
        }
    }

    private func awardXP(_ amount: Int, event: AnalyticsEvent, properties: [String: String]?) {
        xp = max(0, xp + amount)
        Analytics.shared.track(event, properties: properties)
    }

    private func persist() {
        let state = PersistedState(
            xp: xp,
            streak: streak,
            lastCheckInDay: lastCheckInDay,
            lastTimeTravelXPDay: lastTimeTravelXPDay,
            weeklyChapterKey: weeklyChapterKey,
            weeklyChapterCheckIns: weeklyChapterCheckIns,
            unlockedCardIds: Array(unlockedCardIds),
            milestones: Array(milestones),
            archetype: archetype
        )
        Self.save(state, storageKey: storageKey)
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func weekKey(_ date: Date) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let y = comps.yearForWeekOfYear ?? calendar.component(.year, from: date)
        let w = comps.weekOfYear ?? calendar.component(.weekOfYear, from: date)
        return "\(y)-W\(w)"
    }

    private static func isYesterdayKey(_ yesterdayKey: String, comparedTo lastKey: String?) -> Bool {
        guard let lastKey else { return false }
        return yesterdayKey == lastKey
    }

    private static func dailyCard(for dayKey: String, archetype: String?) -> ArcanaCard {
        // Deterministic: hash(dayKey + archetype) -> pick.
        let seed = (dayKey + "|" + (archetype ?? ""))
        let idx = abs(seed.hashValue) % Self.arcanaDeck.count
        return Self.arcanaDeck[idx]
    }

    private static let arcanaDeck: [ArcanaCard] = [
        ArcanaCard(id: "sigil_ember", title: "Ember Sigil", subtitle: "Small action, fast momentum.", prompt: "What is the smallest step that proves you are serious?"),
        ArcanaCard(id: "sigil_tide", title: "Tide Sigil", subtitle: "Slow growth, steady return.", prompt: "Where can you be patient without going passive?"),
        ArcanaCard(id: "arcana_mirror", title: "Mirror Arcana", subtitle: "Patterns show themselves today.", prompt: "What are you repeating, and what do you want instead?"),
        ArcanaCard(id: "arcana_key", title: "Key Arcana", subtitle: "One decision unlocks the next room.", prompt: "What decision have you delayed that would simplify everything?"),
        ArcanaCard(id: "sigil_stillness", title: "Stillness Sigil", subtitle: "Calm is a strategy.", prompt: "What would you stop doing if you trusted the timeline?"),
        ArcanaCard(id: "arcana_compass", title: "Compass Arcana", subtitle: "Direction beats speed.", prompt: "What does ‘better’ look like in one sentence?"),
    ]

    private static func load(storageKey: String) -> PersistedState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(PersistedState.self, from: data)
    }

    private static func save(_ state: PersistedState, storageKey: String) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
