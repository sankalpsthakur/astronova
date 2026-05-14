import Foundation
import SwiftUI

/// Depth tier for daily readings.
/// - epiphany: rare, expansive day — full-screen treatment, named transit, reflection prompt (~5%)
/// - depth: richer-than-baseline reading with two themes interwoven (~25%)
/// - general: standard 3-tile reading (~70%)
enum DailyReadingDepth: String, Codable, Equatable {
    case epiphany
    case depth
    case general

    var isExtended: Bool { self != .general }
}

struct DailyGuidance: Codable, Equatable {
    let date: String   // yyyy-MM-dd
    let sign: String
    let focus: String
    let relationships: String
    let energy: String
    let sourceSummary: String?
    let horoscopeText: String?
    let keywords: [String]?
    let luckyNumbers: [Int]?
    let compatibility: [String]?
    // Variable-depth additions (optional for back-compat with cached entries)
    var depth: DailyReadingDepth?
    var headline: String?            // Signature line on epiphany / depth days
    var extendedBody: String?        // Longer poetic body for depth & epiphany
    var transitNote: String?         // Named transit ("Moon in Scorpio at 4:11am")
    var reflectionPrompt: String?    // Question for the reader (epiphany only)

    /// Resolved depth — falls back to .general for older cached entries that lacked the field.
    var resolvedDepth: DailyReadingDepth { depth ?? .general }
}

/// Maps HoroscopeResponse to compact Home tiles and caches last 3 days per sign.
final class HomeGuidanceService: ObservableObject {
    static let shared = HomeGuidanceService()
    private let api = APIServices.shared
    private let userDefaults = UserDefaults.standard
    private let cachePrefix = "guidance"

    func loadGuidance(sign: String, date: Date = Date()) async throws -> DailyGuidance {
        let key = cacheKey(sign: sign, date: date)
        if let cached = read(key: key), cached.horoscopeText != nil, cached.depth != nil {
            await recordToDiary(cached)
            return cached
        }

        let response = try await api.getDailyHoroscope(for: sign, date: date)
        let dg = transform(response, sign: sign, date: date)
        write(dg, for: sign)
        pruneCache(for: sign)
        await recordToDiary(dg)
        return dg
    }

    /// Wave 10 — log every successfully-loaded reading to the Cosmic Diary.
    /// The store dedupes on (date, sign), so this is safe to call every load.
    @MainActor
    private func recordToDiary(_ dg: DailyGuidance) {
        CosmicDiaryStore.shared.record(DiaryEntry(from: dg))
    }

    func recentGuidance(sign: String, days: Int = 3) -> [DailyGuidance] {
        let indexKey = indexKeyForSign(sign)
        guard let keys = userDefaults.array(forKey: indexKey) as? [String] else { return [] }
        return keys.compactMap { read(key: $0) }.suffix(days)
    }

    // MARK: - Transform
    /// Compose a DailyGuidance from a HoroscopeResponse with a depth tier that varies
    /// deterministically per (user-sign, date). Selection: epiphany 5%, depth 25%, general 70%.
    func transform(_ hr: HoroscopeResponse, sign: String, date: Date = Date()) -> DailyGuidance {
        let text = hr.horoscope
        let sentences = text
            .split(whereSeparator: { ".!?".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Deterministic seed: stable per (sign, date) so each day "rolls the dice" once.
        let seed = Self.seed(forSign: sign, date: date)
        let depth = Self.selectDepth(seed: seed)
        var rng = SeededGenerator(seed: seed)

        func pick(_ keywords: [String], fallbacks: [String]) -> String {
            if let s = sentences.first(where: { st in
                let low = st.lowercased()
                return keywords.contains(where: { low.contains($0) })
            }) { return s }
            // Fresh composition: rotate fallback variants instead of one hard-coded line.
            let idx = Int.random(in: 0..<fallbacks.count, using: &rng)
            return fallbacks[idx]
        }

        let focus = pick(
            ["work","focus","career","plan","project","study","task","goal"],
            fallbacks: [
                "Prioritize one task that matters; let the rest wait.",
                "The sky favors one clean line of attention today.",
                "Choose depth over breadth; one thing, well.",
                "A small commitment now compounds quietly."
            ]
        )
        let relationships = pick(
            ["love","relationship","partner","friend","family","communicat","listen"],
            fallbacks: [
                "Lead with one more question than you would normally ask.",
                "Today rewards the listener more than the speaker.",
                "A kindness you offer returns in a different shape.",
                "Speak the half-thought aloud; the right ear is near."
            ]
        )
        let energy = pick(
            ["energy","rest","health","exercise","sleep","recharge","pace"],
            fallbacks: [
                "Energy gathers mid-morning; spend it on what is real.",
                "Pace yourself like the Moon waxes — slow, then sure.",
                "Brief rests today are not retreat; they are tuning.",
                "Move the body once before noon; the rest opens."
            ]
        )

        // Depth-tier extras
        let transitNote: String?
        let headline: String?
        let extendedBody: String?
        let reflectionPrompt: String?

        switch depth {
        case .general:
            transitNote = nil
            headline = nil
            extendedBody = nil
            reflectionPrompt = nil

        case .depth:
            transitNote = Self.composeTransitNote(seed: seed, sign: sign)
            headline = Self.composeHeadline(rng: &rng, sign: sign, depth: depth)
            extendedBody = Self.composeExtendedBody(
                rng: &rng,
                sourceSentences: sentences,
                focus: focus,
                relationships: relationships,
                depth: depth
            )
            reflectionPrompt = nil

        case .epiphany:
            transitNote = Self.composeTransitNote(seed: seed, sign: sign)
            headline = Self.composeHeadline(rng: &rng, sign: sign, depth: depth)
            extendedBody = Self.composeExtendedBody(
                rng: &rng,
                sourceSentences: sentences,
                focus: focus,
                relationships: relationships,
                depth: depth
            )
            reflectionPrompt = Self.composeReflection(rng: &rng)
        }

        return DailyGuidance(
            date: hr.date,
            sign: hr.sign.capitalized,
            focus: focus,
            relationships: relationships,
            energy: energy,
            sourceSummary: sentences.first,
            horoscopeText: hr.horoscope,
            keywords: hr.keywords,
            luckyNumbers: hr.luckyNumbers,
            compatibility: hr.compatibility,
            depth: depth,
            headline: headline,
            extendedBody: extendedBody,
            transitNote: transitNote,
            reflectionPrompt: reflectionPrompt
        )
    }

    // MARK: - Depth Selection

    /// Stable seed derived from sign + date. SDBM-style hash → UInt64.
    private static func seed(forSign sign: String, date: Date) -> UInt64 {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        let key = "\(sign.lowercased()):\(f.string(from: date))"
        var hash: UInt64 = 0
        for byte in key.utf8 {
            hash = UInt64(byte) &+ (hash &<< 6) &+ (hash &<< 16) &- hash
        }
        // Avoid degenerate zero seeds.
        return hash == 0 ? 0xDEADBEEFCAFE : hash
    }

    private static func selectDepth(seed: UInt64) -> DailyReadingDepth {
        // Roll a single uniform in [0,1) — 5% epiphany, 25% depth, 70% general.
        let roll = Double(seed % 10_000) / 10_000.0
        if roll < 0.05 { return .epiphany }
        if roll < 0.30 { return .depth }
        return .general
    }

    private static func composeTransitNote(seed: UInt64, sign: String) -> String {
        let moonSigns = [
            "Aries","Taurus","Gemini","Cancer","Leo","Virgo",
            "Libra","Scorpio","Sagittarius","Capricorn","Aquarius","Pisces"
        ]
        let house = Int((seed >> 8) % 12) + 1
        let moonIdx = Int((seed >> 16) % UInt64(moonSigns.count))
        let degrees = Double((seed >> 24) % 30_00) / 100.0
        return "Moon in \(moonSigns[moonIdx]) at \(String(format: "%.1f", degrees))°, crossing your \(ordinal(house)) house."
    }

    private static func composeHeadline(
        rng: inout SeededGenerator,
        sign: String,
        depth: DailyReadingDepth
    ) -> String {
        let epiphanyLines = [
            "Something opens today that has been waiting since the last new moon.",
            "The sky is unusually loud — listen for the quiet part.",
            "A door you walked past three times this season is unlocked tonight.",
            "An old question gets a younger answer."
        ]
        let depthLines = [
            "Two currents meet today; you stand where they cross.",
            "The chart is not still — it leans toward one direction. So should you.",
            "A theme returns. It is not the same theme.",
            "Today's sky favors the patient gesture."
        ]
        let pool = depth == .epiphany ? epiphanyLines : depthLines
        let idx = Int.random(in: 0..<pool.count, using: &rng)
        return pool[idx]
    }

    private static func composeExtendedBody(
        rng: inout SeededGenerator,
        sourceSentences: [String],
        focus: String,
        relationships: String,
        depth: DailyReadingDepth
    ) -> String {
        // Weave focus + relationships with a connective; for epiphany, add a third beat.
        let connectives = [
            "and beneath this,",
            "but the deeper note is —",
            "what holds it together:",
            "running underneath,"
        ]
        let idx = Int.random(in: 0..<connectives.count, using: &rng)
        let connector = connectives[idx]
        let woven = "\(focus.trimmedSentence()) \(connector) \(relationships.trimmedSentence().lowercasedFirst())."
        if depth == .epiphany, let third = sourceSentences.dropFirst().randomElement(using: &rng) {
            return "\(woven) \(third.trimmedSentence())."
        }
        return woven
    }

    private static func composeReflection(rng: inout SeededGenerator) -> String {
        let prompts = [
            "What would change if you treated this day as a turning?",
            "Where in your life is the question larger than the answer?",
            "Which version of yourself is asking — and which is answering?",
            "What have you been carrying that is not yours to carry?"
        ]
        let idx = Int.random(in: 0..<prompts.count, using: &rng)
        return prompts[idx]
    }

    private static func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
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

// MARK: - SeededGenerator

/// SplitMix64-based deterministic RNG.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEADBEEFCAFE : seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}

// MARK: - String helpers

private extension String {
    func trimmedSentence() -> String {
        let s = trimmingCharacters(in: .whitespacesAndNewlines)
        // Drop trailing punctuation so we can re-punctuate cleanly.
        if let last = s.last, ".!?".contains(last) {
            return String(s.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s
    }
    func lowercasedFirst() -> String {
        guard let first = first else { return self }
        return first.lowercased() + dropFirst()
    }
}
