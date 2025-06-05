import Foundation
import Combine
import CloudKitKit
import DataModels
import AstroEngine
import CoreLocation

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
            var personalized = horoscope
            do {
                let id = try await CKContainer.cosmic.fetchUserRecordID()
                let profile: UserProfile = try await CKDatabaseProxy.private.fetch(type: UserProfile.self, id: id)
                let planet = Self.majorTransit(for: profile, on: day)
                let line = "Personal Transit: \(planet) is spotlighted for you today."
                let ext = [horoscope.extendedText, line].compactMap { $0 }.joined(separator: "\n")
                personalized = Horoscope(sign: horoscope.sign,
                                         date: horoscope.date,
                                         language: horoscope.language,
                                         shortText: horoscope.shortText,
                                         extendedText: ext)
            } catch {
                print("[HoroscopeRepository] transit computation failed: \(error)")
            }

            HoroscopeCache.save(personalized)
            self.today = personalized
        }
    }

    private static func majorTransit(for profile: UserProfile, on date: Date) -> String {
        let birth = BirthData(date: profile.birthDate,
                              time: profile.birthTime,
                              location: profile.birthPlace)
        let calc = WesternCalc()
        let natal = calc.positions(for: birth)
        let transit = calc.positions(for: BirthData(date: date,
                                                    time: nil,
                                                    location: profile.birthPlace))

        var major = transit.first?.name ?? "Sun"
        var minDiff = Double.greatestFiniteMagnitude

        for t in transit {
            if let n = natal.first(where: { $0.name == t.name }) {
                var diff = abs(t.longitude - n.longitude).truncatingRemainder(dividingBy: 360)
                if diff > 180 { diff = 360 - diff }
                if diff < minDiff {
                    minDiff = diff
                    major = t.name
                }
            }
        }
        return major
    }
}

