//
//  CosmicDiaryStore.swift
//  AstronovaApp
//
//  Wave 10 — Cosmic Diary endgame (G8). Persistent chronological archive of
//  every reading the user has seen, plus a sibling store for Future Letters
//  the user has written to themselves.
//
//  Persistence: Codable JSON file in Application Support. Single source of
//  truth for both Diary and Future Letter UIs, observable via Combine.
//

import Foundation
import SwiftUI

// MARK: - Models

/// One day's reading entry. Mirrors the fields the user actually sees so the
/// diary can re-render the reading offline, including the variable-depth
/// extras added in Wave 8.
struct DiaryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let date: String              // yyyy-MM-dd (stable key for dedupe)
    let sign: String
    let depth: DailyReadingDepth
    let focus: String
    let relationships: String
    let energy: String
    let horoscopeText: String?
    let headline: String?
    let extendedBody: String?
    let transitNote: String?
    let reflectionPrompt: String?
    var userNote: String?         // mutable: the user can add a personal note
    let createdAt: Date

    init(
        id: UUID = UUID(),
        date: String,
        sign: String,
        depth: DailyReadingDepth,
        focus: String,
        relationships: String,
        energy: String,
        horoscopeText: String? = nil,
        headline: String? = nil,
        extendedBody: String? = nil,
        transitNote: String? = nil,
        reflectionPrompt: String? = nil,
        userNote: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.sign = sign
        self.depth = depth
        self.focus = focus
        self.relationships = relationships
        self.energy = energy
        self.horoscopeText = horoscopeText
        self.headline = headline
        self.extendedBody = extendedBody
        self.transitNote = transitNote
        self.reflectionPrompt = reflectionPrompt
        self.userNote = userNote
        self.createdAt = createdAt
    }
}

extension DiaryEntry {
    /// Returns the entry's date as a real `Date` for sorting and grouping.
    /// Diary keys are stable `yyyy-MM-dd` strings written at load time.
    var dateValue: Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: date) ?? createdAt
    }

    /// Build from a `DailyGuidance` produced by `HomeGuidanceService`.
    init(from g: DailyGuidance) {
        self.init(
            date: g.date,
            sign: g.sign,
            depth: g.resolvedDepth,
            focus: g.focus,
            relationships: g.relationships,
            energy: g.energy,
            horoscopeText: g.horoscopeText,
            headline: g.headline,
            extendedBody: g.extendedBody,
            transitNote: g.transitNote,
            reflectionPrompt: g.reflectionPrompt
        )
    }
}

/// A letter the user has written to their future self, scheduled to surface
/// on a chosen delivery date (with an optional local notification).
struct FutureLetter: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let deliveryDate: Date
    let body: String
    var triggerNote: String?      // human label: "Solar return 2027", etc.
    var delivered: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        deliveryDate: Date,
        body: String,
        triggerNote: String? = nil,
        delivered: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.deliveryDate = deliveryDate
        self.body = body
        self.triggerNote = triggerNote
        self.delivered = delivered
    }
}

extension FutureLetter {
    /// True once the delivery moment has arrived (regardless of whether the
    /// notification has fired — the diary view also reveals undelivered
    /// letters if their date has passed).
    var isReadyToDeliver: Bool { Date() >= deliveryDate }

    var notificationIdentifier: String { "future_letter_\(id.uuidString)" }
}

// MARK: - Store

/// File-backed persistence for the Cosmic Diary endgame. Single JSON file
/// holds both the chronological diary and the future-letter pile so the user
/// has one self-contained archive on disk.
@MainActor
final class CosmicDiaryStore: ObservableObject {
    static let shared = CosmicDiaryStore()

    @Published private(set) var entries: [DiaryEntry] = []
    @Published private(set) var letters: [FutureLetter] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "cosmic-diary.store", qos: .utility)

    private struct Persisted: Codable {
        var entries: [DiaryEntry]
        var letters: [FutureLetter]
    }

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let fm = FileManager.default
            let base = (try? fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? fm.temporaryDirectory
            self.fileURL = base.appendingPathComponent("cosmic-diary.json")
        }

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        load()
    }

    // MARK: - Diary API

    /// Idempotent: writing the same `date` twice keeps the original entry
    /// but updates any newly-present fields. This makes the hook from
    /// `HomeGuidanceService.loadGuidance` safe to call on every app open.
    func record(_ entry: DiaryEntry) {
        if let idx = entries.firstIndex(where: { $0.date == entry.date && $0.sign == entry.sign }) {
            // Preserve user note and original id; otherwise refresh content.
            let existing = entries[idx]
            entries[idx] = DiaryEntry(
                id: existing.id,
                date: entry.date,
                sign: entry.sign,
                depth: entry.depth,
                focus: entry.focus,
                relationships: entry.relationships,
                energy: entry.energy,
                horoscopeText: entry.horoscopeText,
                headline: entry.headline,
                extendedBody: entry.extendedBody,
                transitNote: entry.transitNote,
                reflectionPrompt: entry.reflectionPrompt,
                userNote: existing.userNote ?? entry.userNote,
                createdAt: existing.createdAt
            )
        } else {
            entries.append(entry)
        }
        entries.sort { $0.dateValue > $1.dateValue }
        persist()
    }

    func updateNote(for entryID: UUID, note: String?) {
        guard let idx = entries.firstIndex(where: { $0.id == entryID }) else { return }
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[idx].userNote = (trimmed?.isEmpty ?? true) ? nil : trimmed
        persist()
    }

    /// Today's entry if one has been recorded already, else nil.
    func todaysEntry() -> DiaryEntry? {
        let key = Self.dateKey(for: Date())
        return entries.first(where: { $0.date == key })
    }

    /// Entries grouped by month label ("May 2026"), most recent first within
    /// each group, groups themselves most-recent-first.
    func entriesGroupedByMonth() -> [(label: String, entries: [DiaryEntry])] {
        let cal = Calendar(identifier: .gregorian)
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")

        var buckets: [(key: Date, label: String, entries: [DiaryEntry])] = []
        for entry in entries {
            let components = cal.dateComponents([.year, .month], from: entry.dateValue)
            guard let monthStart = cal.date(from: components) else { continue }
            let label = f.string(from: monthStart)
            if let idx = buckets.firstIndex(where: { $0.key == monthStart }) {
                buckets[idx].entries.append(entry)
            } else {
                buckets.append((monthStart, label, [entry]))
            }
        }
        buckets.sort { $0.key > $1.key }
        return buckets.map { (label: $0.label, entries: $0.entries.sorted { $0.dateValue > $1.dateValue }) }
    }

    // MARK: - Future Letter API

    func addLetter(_ letter: FutureLetter) {
        letters.append(letter)
        letters.sort { $0.deliveryDate < $1.deliveryDate }
        persist()
    }

    func deleteLetter(id: UUID) {
        letters.removeAll(where: { $0.id == id })
        persist()
    }

    func markLetterDelivered(id: UUID) {
        guard let idx = letters.firstIndex(where: { $0.id == id }) else { return }
        letters[idx].delivered = true
        persist()
    }

    // MARK: - Migration from legacy UserDefaults cache

    /// Imports cached `DailyGuidance` blobs written by `HomeGuidanceService`
    /// (keyed `guidance:<sign>:<yyyy-MM-dd>`) into the diary. Safe to call
    /// repeatedly; existing entries are not duplicated.
    func migrateFromLegacyCacheIfNeeded() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let guidanceKeys = allKeys.filter { $0.hasPrefix("guidance:") && !$0.hasPrefix("guidance:index:") }
        guard !guidanceKeys.isEmpty else { return }
        let decoder = JSONDecoder()
        for key in guidanceKeys {
            guard let data = defaults.data(forKey: key),
                  let dg = try? decoder.decode(DailyGuidance.self, from: data) else { continue }
            // Don't overwrite an entry the user may have annotated.
            if entries.contains(where: { $0.date == dg.date && $0.sign == dg.sign }) { continue }
            record(DiaryEntry(from: dg))
        }
    }

    // MARK: - Internals

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let payload = try decoder.decode(Persisted.self, from: data)
            self.entries = payload.entries.sorted { $0.dateValue > $1.dateValue }
            self.letters = payload.letters.sorted { $0.deliveryDate < $1.deliveryDate }
        } catch {
            // Corrupt or partial — start fresh rather than crash.
            self.entries = []
            self.letters = []
        }
    }

    private func persist() {
        let payload = Persisted(entries: entries, letters: letters)
        let url = fileURL
        let enc = encoder
        queue.async {
            do {
                let data = try enc.encode(payload)
                try data.write(to: url, options: [.atomic])
            } catch {
                // Persistence failure is non-fatal; the in-memory state is
                // still correct for this session and will retry next write.
            }
        }
    }

    static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }
}
