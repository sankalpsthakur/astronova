import Foundation
import DataModels

/// Compares two birth datasets and produces a KundaliMatch result.
public final class MatchService {
    public init() {}

    /// Compare two birth-date/location combos and return a match score struct.
    public func compare(_ me: Any, with them: Any) -> KundaliMatch {
        guard let m = me as? UserProfile, let t = them as? UserProfile else {
            return KundaliMatch(partnerName: "Unknown",
                               partnerDOB: Date(),
                               scoreTotal: 0,
                               aspectJSON: "{}",
                               createdAt: Date())
        }

        func idx(_ sign: String) -> Int {
            let signs = ["aries","taurus","gemini","cancer","leo","virgo","libra","scorpio","sagittarius","capricorn","aquarius","pisces"]
            return signs.firstIndex(of: sign.lowercased()) ?? 0
        }

        let s1 = idx(m.sunSign)
        let s2 = idx(t.sunSign)
        let m1 = idx(m.moonSign)
        let m2 = idx(t.moonSign)

        var aspects: [String: Int] = [:]
        aspects["varna"] = (s1 % 4 == s2 % 4) ? 1 : 0
        aspects["vashya"] = (m1 % 3 == m2 % 3) ? 1 : 0
        aspects["tara"] = (s1 % 9 == s2 % 9) ? 1 : 0
        aspects["yoni"] = (m1 % 2 == m2 % 2) ? 1 : 0
        aspects["maitri"] = abs(s1 - s2) <= 1 ? 1 : 0
        aspects["gana"] = (s1 % 3 == s2 % 3) ? 1 : 0
        aspects["bhakoot"] = (s1 == s2) ? 1 : 0
        aspects["nadi"] = (s1 % 3 != s2 % 3) ? 1 : 0

        let total = aspects.values.reduce(0, +)
        let jsonData = try? JSONEncoder().encode(aspects)
        let json = String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"

        return KundaliMatch(partnerName: t.fullName,
                           partnerDOB: t.birthDate,
                           scoreTotal: total,
                           aspectJSON: json,
                           createdAt: Date())
    }
}