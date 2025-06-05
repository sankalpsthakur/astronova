import Foundation
import CloudKitKit
import DataModels

/// Operation to prefetch all signs' horoscopes for a given date.
public final class HoroscopeRefreshOp {
    public init() {}

    /// Fetches and caches all 12 horoscopes for the specified date.
    public func execute(for date: Date) async throws {
        let day = Calendar.current.startOfDay(for: date)
        let lang = Locale.current.identifier

        try await withThrowingTaskGroup(of: Void.self) { group in
            for sign in Self.signs {
                group.addTask {
                    let predicate = NSPredicate(format: "sign == %@ AND language == %@ AND date == %@", sign, lang, day as NSDate)
                    let results = try await CKDatabaseProxy.public.query(type: Horoscope.self, predicate: predicate)
                    if let horoscope = results.first {
                        HoroscopeCache.save(horoscope)
                    }
                }
            }
            try await group.waitForAll()
        }
    }

    private static let signs = [
        "aries", "taurus", "gemini", "cancer", "leo", "virgo",
        "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"
    ]
}
