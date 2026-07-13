import Foundation

/// Pure day/week bucketing and habit progression math.
/// Kept free of UserDefaults/UI so unit tests can pin calendars and time zones.
enum DailyProgressionMath {
    static let weeklyChapterTargetDays = 7

    struct ChapterProgress: Equatable {
        let completedDays: Int
        let targetDays: Int

        var clampedCompleted: Int {
            min(max(0, completedDays), targetDays)
        }

        var fraction: Double {
            guard targetDays > 0 else { return 0 }
            return min(1.0, Double(clampedCompleted) / Double(targetDays))
        }

        /// Display label such as "3/7".
        var label: String {
            "\(clampedCompleted)/\(targetDays)"
        }

        var isComplete: Bool {
            completedDays >= targetDays && targetDays > 0
        }
    }

    // MARK: - Day / week keys

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func dayDate(_ dayKey: String, calendar: Calendar = .current) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

    static func weekKey(_ date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let y = comps.yearForWeekOfYear ?? calendar.component(.year, from: date)
        let w = comps.weekOfYear ?? calendar.component(.weekOfYear, from: date)
        return "\(y)-W\(w)"
    }

    // MARK: - Streak

    /// True when `lastCheckInDay` is exactly one local calendar day before `todayKey`.
    static func isConsecutiveCheckIn(
        lastCheckInDay: String?,
        todayKey: String,
        calendar: Calendar = .current
    ) -> Bool {
        guard
            let lastCheckInDay,
            let today = dayDate(todayKey, calendar: calendar),
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        else {
            return false
        }
        return dayKey(yesterday, calendar: calendar) == lastCheckInDay
    }

    /// Streak after a new check-in on `todayKey` (caller must ensure the day is new).
    static func nextStreak(
        currentStreak: Int,
        lastCheckInDay: String?,
        todayKey: String,
        calendar: Calendar = .current
    ) -> Int {
        if isConsecutiveCheckIn(lastCheckInDay: lastCheckInDay, todayKey: todayKey, calendar: calendar) {
            return max(1, currentStreak + 1)
        }
        return 1
    }

    static func hasCheckedInToday(
        lastCheckInDay: String?,
        todayKey: String
    ) -> Bool {
        guard let lastCheckInDay else { return false }
        return lastCheckInDay == todayKey
    }

    // MARK: - Weekly chapter

    /// Progress for the *current* local week. Stale chapter keys report 0 until the week is active.
    static func chapterProgress(
        checkIns: Int,
        chapterKey: String?,
        currentWeekKey: String,
        target: Int = weeklyChapterTargetDays
    ) -> ChapterProgress {
        let completed: Int
        if chapterKey == currentWeekKey {
            completed = max(0, checkIns)
        } else {
            completed = 0
        }
        return ChapterProgress(completedDays: completed, targetDays: max(1, target))
    }

    /// Apply a new daily check-in to weekly chapter counters.
    /// Returns updated key/count and whether chapter just completed (hit target exactly).
    static func applyChapterCheckIn(
        storedKey: String?,
        storedCheckIns: Int,
        currentWeekKey: String,
        target: Int = weeklyChapterTargetDays
    ) -> (key: String, checkIns: Int, justCompleted: Bool) {
        var key = storedKey
        var checkIns = storedCheckIns
        if key != currentWeekKey {
            key = currentWeekKey
            checkIns = 0
        }
        checkIns += 1
        let justCompleted = checkIns == target
        return (key ?? currentWeekKey, checkIns, justCompleted)
    }

    /// Allowed non-PII property keys for habit progression analytics.
    static let allowedAnalyticsPropertyKeys: Set<String> = [
        "day",
        "week",
        "streak",
        "feature",
        "chapter",
        "check_ins",
        "is_new"
    ]

    static func scrubAnalyticsProperties(_ properties: [String: String]) -> [String: String] {
        properties.filter { allowedAnalyticsPropertyKeys.contains($0.key) }
    }
}
