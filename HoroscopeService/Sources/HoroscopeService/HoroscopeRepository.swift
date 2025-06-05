import Foundation
import Combine
import CloudKitKit
import DataModels
import AstroEngine

/// Repository for fetching and caching daily horoscopes.
public final class HoroscopeRepository: ObservableObject {
    @Published public private(set) var today: Horoscope?

    public init() {}

    /// Fetch today's horoscope for the given sign and language.
    /// - Parameters:
    ///   - sign: Zodiac sign name, e.g. "aries".
    ///   - language: BCP-47 language identifier.
    @MainActor
    public func fetchToday(sign: String = "aries", language: String = Locale.current.identifier) async throws {
        let day = Calendar.current.startOfDay(for: Date())

        if let cached = HoroscopeCache.load(sign: sign, date: day, language: language) {
            self.today = cached
            return
        }

        let predicate = NSPredicate(format: "sign == %@ AND language == %@ AND date == %@", sign, language, day as NSDate)
        let results = try await CKDatabaseProxy.public.query(type: Horoscope.self, predicate: predicate)

        if let horoscope = results.first {
            HoroscopeCache.save(horoscope)
            self.today = horoscope
        }
    }
}