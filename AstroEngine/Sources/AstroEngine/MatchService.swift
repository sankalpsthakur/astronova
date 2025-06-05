import Foundation
import DataModels

/// Compares two birth datasets and produces a KundaliMatch result.
public final class MatchService {
    public init() {}

    /// Compare two sets of birth data and return a match score struct.
    public func compare(myData: BirthData,
                        partnerData: BirthData,
                        partnerName: String) -> KundaliMatch {
        func signIndex(_ degree: Double) -> Int {
            Int((degree / 30.0).rounded(.down)) % 12
        }

        let calc = WesternCalc()
        let myPositions = calc.positions(for: myData)
        let partnerPositions = calc.positions(for: partnerData)

        guard let mySun = myPositions.first(where: { $0.name == "Sun" }),
              let partnerSun = partnerPositions.first(where: { $0.name == "Sun" }),
              let myMoon = myPositions.first(where: { $0.name == "Moon" }),
              let partnerMoon = partnerPositions.first(where: { $0.name == "Moon" }) else {
            return KundaliMatch(partnerName: partnerName,
                               partnerDOB: partnerData.date,
                               scoreTotal: 0,
                               aspectJSON: "{}",
                               createdAt: Date())
        }

        let s1 = signIndex(mySun.longitude)
        let s2 = signIndex(partnerSun.longitude)
        let m1 = signIndex(myMoon.longitude)
        let m2 = signIndex(partnerMoon.longitude)

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

        return KundaliMatch(partnerName: partnerName,
                           partnerDOB: partnerData.date,
                           scoreTotal: total,
                           aspectJSON: json,
                           createdAt: Date())
    }
}