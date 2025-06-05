import XCTest
@testable import HoroscopeService

final class HoroscopeServiceTests: XCTestCase {

    func testCacheRoundTrip() throws {
        let sign = "testsign"
        let lang = "en"
        let date = Calendar.current.startOfDay(for: Date())
        let horoscope = Horoscope(sign: sign, date: date, language: lang, shortText: "hi")

        HoroscopeCache.save(horoscope)
        let loaded = HoroscopeCache.load(sign: sign, date: date, language: lang)

        XCTAssertEqual(loaded?.shortText, "hi")
    }

    func testFetchTodayFromCache() async throws {
        let repo = HoroscopeRepository()
        let sign = "cachedsign"
        let lang = "en"
        let date = Calendar.current.startOfDay(for: Date())
        let horoscope = Horoscope(sign: sign, date: date, language: lang, shortText: "cached")
        HoroscopeCache.save(horoscope)

        try await repo.fetchToday(sign: sign, language: lang)

        XCTAssertEqual(repo.today?.shortText, "cached")
    }
}
