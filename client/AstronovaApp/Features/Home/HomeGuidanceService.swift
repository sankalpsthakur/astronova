import Foundation
import SwiftUI

struct DailyGuidance: Codable, Equatable {
    let date: String   // yyyy-MM-dd
    let sign: String
    let focus: String
    let relationships: String
    let energy: String
    let sourceSummary: String?
}

/// Maps HoroscopeResponse to compact Home tiles and caches last 3 days per sign.
final class HomeGuidanceService: ObservableObject {
    static let shared = HomeGuidanceService()
    private let api = APIServices.shared
    private let userDefaults = UserDefaults.standard
    private let cachePrefix = "guidance"

    func loadGuidance(sign: String, date: Date = Date()) async throws -> DailyGuidance {
        let key = cacheKey(sign: sign, date: date)
        if let cached = read(key: key) { return cached }

        let response = try await api.getDailyHoroscope(for: sign, date: date)
        let dg = transform(response)
        write(dg, for: sign)
        pruneCache(for: sign)
        return dg
    }

    func recentGuidance(sign: String, days: Int = 3) -> [DailyGuidance] {
        let indexKey = indexKeyForSign(sign)
        guard let keys = userDefaults.array(forKey: indexKey) as? [String] else { return [] }
        return keys.compactMap { read(key: $0) }.suffix(days)
    }

    // MARK: - Transform
    private func transform(_ hr: HoroscopeResponse) -> DailyGuidance {
        let text = hr.horoscope
        let sentences = text.split(whereSeparator: { ".!?".contains($0) }).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        func pick(_ keywords: [String], fallback: String) -> String {
            if let s = sentences.first(where: { st in
                let low = st.lowercased()
                return keywords.contains(where: { low.contains($0) })
            }) { return s }
            return fallback
        }

        let focus = pick(["work","focus","career","plan","project","study","task","goal"], fallback: "Prioritize one important task; avoid context switching.")
        let relationships = pick(["love","relationship","partner","friend","family","communicat","listen"], fallback: "Lead with empathy; ask one more question.")
        let energy = pick(["energy","rest","health","exercise","sleep","recharge","pace"], fallback: "Energy peaks mid‑day; schedule deep work 10–1.")

        return DailyGuidance(date: hr.date, sign: hr.sign.capitalized, focus: focus, relationships: relationships, energy: energy, sourceSummary: sentences.first)
    }

    // MARK: - Cache
    private func cacheKey(sign: String, date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return "\(cachePrefix):\(sign.lowercased()):\(f.string(from: date))"
    }

    private func indexKeyForSign(_ sign: String) -> String { "\(cachePrefix):index:\(sign.lowercased())" }

    private func read(key: String) -> DailyGuidance? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DailyGuidance.self, from: data)
    }

    private func write(_ value: DailyGuidance, for sign: String) {
        let key = "\(cachePrefix):\(sign.lowercased()):\(value.date)"
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        }
        var index = (userDefaults.array(forKey: indexKeyForSign(sign)) as? [String]) ?? []
        if !index.contains(key) { index.append(key) }
        userDefaults.set(index, forKey: indexKeyForSign(sign))
    }

    private func pruneCache(for sign: String, keep: Int = 3) {
        let idxKey = indexKeyForSign(sign)
        var index = (userDefaults.array(forKey: idxKey) as? [String]) ?? []
        if index.count <= keep { return }
        let toRemove = index.prefix(index.count - keep)
        toRemove.forEach { userDefaults.removeObject(forKey: $0) }
        index.removeFirst(max(0, index.count - keep))
        userDefaults.set(index, forKey: idxKey)
    }
}

