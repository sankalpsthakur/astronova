import XCTest
@testable import AstronovaApp

final class DailyProgressionMathTests: XCTestCase {

    private var calendar: Calendar!

    override func setUpWithError() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.locale = Locale(identifier: "en_US_POSIX")
        // ISO-style weeks so Monday–Sunday share one week key.
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        calendar = cal
        PortfolioAnalytics.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
    }

    // MARK: - Day / week bucketing

    func testDayKeyUsesLocalCalendarDate() {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 7
        comps.day = 9
        comps.hour = 15
        let date = calendar.date(from: comps)!

        XCTAssertEqual(DailyProgressionMath.dayKey(date, calendar: calendar), "2026-07-09")
    }

    func testWeekKeyStableForSameWeek() {
        var monday = DateComponents()
        monday.year = 2026
        monday.month = 7
        monday.day = 6 // Monday
        let mon = calendar.date(from: monday)!

        var sunday = DateComponents()
        sunday.year = 2026
        sunday.month = 7
        sunday.day = 12
        let sun = calendar.date(from: sunday)!

        XCTAssertEqual(
            DailyProgressionMath.weekKey(mon, calendar: calendar),
            DailyProgressionMath.weekKey(sun, calendar: calendar)
        )
    }

    // MARK: - Today complete

    func testHasCheckedInToday() {
        XCTAssertTrue(
            DailyProgressionMath.hasCheckedInToday(lastCheckInDay: "2026-07-09", todayKey: "2026-07-09")
        )
        XCTAssertFalse(
            DailyProgressionMath.hasCheckedInToday(lastCheckInDay: "2026-07-08", todayKey: "2026-07-09")
        )
        XCTAssertFalse(
            DailyProgressionMath.hasCheckedInToday(lastCheckInDay: nil, todayKey: "2026-07-09")
        )
    }

    // MARK: - Streak

    func testConsecutiveCheckInUsesCalendarDayNot24Hours() {
        // 23-hour gap across a day boundary still counts as consecutive.
        XCTAssertTrue(
            DailyProgressionMath.isConsecutiveCheckIn(
                lastCheckInDay: "2026-07-08",
                todayKey: "2026-07-09",
                calendar: calendar
            )
        )
        XCTAssertFalse(
            DailyProgressionMath.isConsecutiveCheckIn(
                lastCheckInDay: "2026-07-07",
                todayKey: "2026-07-09",
                calendar: calendar
            )
        )
    }

    func testNextStreakContinuesOrResets() {
        XCTAssertEqual(
            DailyProgressionMath.nextStreak(
                currentStreak: 3,
                lastCheckInDay: "2026-07-08",
                todayKey: "2026-07-09",
                calendar: calendar
            ),
            4
        )
        XCTAssertEqual(
            DailyProgressionMath.nextStreak(
                currentStreak: 3,
                lastCheckInDay: "2026-07-06",
                todayKey: "2026-07-09",
                calendar: calendar
            ),
            1
        )
        XCTAssertEqual(
            DailyProgressionMath.nextStreak(
                currentStreak: 10,
                lastCheckInDay: nil,
                todayKey: "2026-07-09",
                calendar: calendar
            ),
            1
        )
    }

    // MARK: - Weekly chapter X/7

    func testChapterProgressZeroWhenWeekMismatch() {
        let progress = DailyProgressionMath.chapterProgress(
            checkIns: 4,
            chapterKey: "2026-W27",
            currentWeekKey: "2026-W28",
            target: 7
        )
        XCTAssertEqual(progress.label, "0/7")
        XCTAssertFalse(progress.isComplete)
        XCTAssertEqual(progress.fraction, 0, accuracy: 0.001)
    }

    func testChapterProgressMidWeekAndComplete() {
        let mid = DailyProgressionMath.chapterProgress(
            checkIns: 3,
            chapterKey: "2026-W28",
            currentWeekKey: "2026-W28",
            target: 7
        )
        XCTAssertEqual(mid.label, "3/7")
        XCTAssertFalse(mid.isComplete)
        XCTAssertEqual(mid.fraction, 3.0 / 7.0, accuracy: 0.001)

        let done = DailyProgressionMath.chapterProgress(
            checkIns: 7,
            chapterKey: "2026-W28",
            currentWeekKey: "2026-W28",
            target: 7
        )
        XCTAssertEqual(done.label, "7/7")
        XCTAssertTrue(done.isComplete)
        XCTAssertEqual(done.fraction, 1.0, accuracy: 0.001)
    }

    func testApplyChapterCheckInIncrementsAndCompletesAtSeven() {
        var key: String? = nil
        var checkIns = 0
        let week = "2026-W28"

        for day in 1...6 {
            let result = DailyProgressionMath.applyChapterCheckIn(
                storedKey: key,
                storedCheckIns: checkIns,
                currentWeekKey: week,
                target: 7
            )
            key = result.key
            checkIns = result.checkIns
            XCTAssertEqual(checkIns, day)
            XCTAssertFalse(result.justCompleted, "Should not complete before day 7")
        }

        let complete = DailyProgressionMath.applyChapterCheckIn(
            storedKey: key,
            storedCheckIns: checkIns,
            currentWeekKey: week,
            target: 7
        )
        XCTAssertEqual(complete.checkIns, 7)
        XCTAssertTrue(complete.justCompleted)
    }

    func testApplyChapterCheckInResetsOnNewWeek() {
        let result = DailyProgressionMath.applyChapterCheckIn(
            storedKey: "2026-W27",
            storedCheckIns: 5,
            currentWeekKey: "2026-W28",
            target: 7
        )
        XCTAssertEqual(result.key, "2026-W28")
        XCTAssertEqual(result.checkIns, 1)
        XCTAssertFalse(result.justCompleted)
    }

    // MARK: - Privacy-safe analytics props

    func testScrubAnalyticsPropertiesDropsPIIKeys() {
        let scrubbed = DailyProgressionMath.scrubAnalyticsProperties([
            "day": "2026-07-09",
            "streak": "3",
            "feature": "daily_signal_check_in",
            "name": "Ada",
            "birth_date": "1990-01-01",
            "email": "a@b.c"
        ])
        XCTAssertEqual(Set(scrubbed.keys), Set(["day", "streak", "feature"]))
        XCTAssertNil(scrubbed["name"])
        XCTAssertNil(scrubbed["birth_date"])
        XCTAssertNil(scrubbed["email"])
    }

    /// Composed multi-day sequence: seven consecutive local days join
    /// day-complete, streak continuation, and weekly chapter X/7 completion.
    func testSevenDayChapterIntegrationSequence() {
        let week = "2026-W28"
        var lastDay: String? = nil
        var streak = 0
        var chapterKey: String? = nil
        var checkIns = 0

        let days = (6...12).map { day -> String in
            String(format: "2026-07-%02d", day)
        }

        for (index, today) in days.enumerated() {
            // Same-day re-open is a no-op for progression.
            XCTAssertFalse(
                DailyProgressionMath.hasCheckedInToday(lastCheckInDay: lastDay, todayKey: today)
            )

            streak = DailyProgressionMath.nextStreak(
                currentStreak: streak,
                lastCheckInDay: lastDay,
                todayKey: today,
                calendar: calendar
            )
            lastDay = today
            XCTAssertEqual(streak, index + 1)
            XCTAssertTrue(
                DailyProgressionMath.hasCheckedInToday(lastCheckInDay: lastDay, todayKey: today)
            )

            let chapter = DailyProgressionMath.applyChapterCheckIn(
                storedKey: chapterKey,
                storedCheckIns: checkIns,
                currentWeekKey: week,
                target: 7
            )
            chapterKey = chapter.key
            checkIns = chapter.checkIns
            let progress = DailyProgressionMath.chapterProgress(
                checkIns: checkIns,
                chapterKey: chapterKey,
                currentWeekKey: week,
                target: 7
            )
            XCTAssertEqual(progress.label, "\(index + 1)/7")
            if index < 6 {
                XCTAssertFalse(chapter.justCompleted)
                XCTAssertFalse(progress.isComplete)
            } else {
                XCTAssertTrue(chapter.justCompleted)
                XCTAssertTrue(progress.isComplete)
            }
        }

        // Same-day second engagement must not look incomplete.
        XCTAssertTrue(
            DailyProgressionMath.hasCheckedInToday(lastCheckInDay: lastDay, todayKey: "2026-07-12")
        )
        XCTAssertEqual(streak, 7)
        XCTAssertEqual(checkIns, 7)
    }

    func testFeatureUsedEmissionHasNoPIIKeys() throws {
        var captured: [String: String]?
        PortfolioAnalytics.shared.testEventSink = { event, props in
            if event == .featureUsed {
                captured = props
            }
        }

        let props = DailyProgressionMath.scrubAnalyticsProperties([
            "day": "2026-07-09",
            "streak": "2",
            "feature": "daily_signal_check_in",
            "name": "should_not_pass"
        ])
        PortfolioAnalytics.shared.track(.featureUsed, properties: props)

        let propsOut = try XCTUnwrap(captured)
        XCTAssertEqual(propsOut["feature"], "daily_signal_check_in")
        XCTAssertEqual(propsOut["day"], "2026-07-09")
        XCTAssertNil(propsOut["name"])
        for key in propsOut.keys {
            XCTAssertTrue(
                DailyProgressionMath.allowedAnalyticsPropertyKeys.contains(key)
                    || key == "app_id"
                    || key.hasPrefix("experiment"),
                "Unexpected analytics key \(key)"
            )
        }
    }
}
