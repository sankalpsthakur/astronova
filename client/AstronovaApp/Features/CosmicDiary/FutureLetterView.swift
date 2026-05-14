//
//  FutureLetterView.swift
//  AstronovaApp
//
//  Wave 10 — letters the user writes to their future self, delivered on a
//  chosen date via a scheduled local notification. The "deliver when X
//  happens" picker is a stub; the date picker is the live path.
//

import SwiftUI
import UserNotifications

struct FutureLetterView: View {
    @StateObject private var store = CosmicDiaryStore.shared
    @State private var showCompose = false
    @State private var selectedLetter: FutureLetter?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
                header

                if store.letters.isEmpty {
                    emptyState
                } else {
                    ForEach(store.letters) { letter in
                        Button {
                            if letter.isReadyToDeliver {
                                selectedLetter = letter
                            }
                        } label: {
                            FutureLetterRow(letter: letter)
                        }
                        .buttonStyle(.plain)
                        .disabled(!letter.isReadyToDeliver)
                    }
                }
            }
            .padding(.horizontal, Cosmic.Spacing.m)
            .padding(.top, Cosmic.Spacing.s)
            .padding(.bottom, Cosmic.Spacing.xxl)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle("Future Letters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.cosmicGold)
                }
                .accessibilityLabel("Write a letter")
            }
        }
        .sheet(isPresented: $showCompose) {
            NavigationStack { FutureLetterComposeView() }
        }
        .sheet(item: $selectedLetter) { letter in
            NavigationStack { FutureLetterReadView(letter: letter) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Write to your future self")
                .font(.cosmicTitle)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("The letter waits, sealed, until its day arrives. Your phone will ring quietly when it does.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No letters yet.")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Tap the pencil to write one. Pick a delivery date — your next solar return, the next Mercury station, or just a Tuesday two years from now.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding(Cosmic.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))
    }
}

// MARK: - Row

struct FutureLetterRow: View {
    let letter: FutureLetter

    private var deliveryLabel: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: letter.deliveryDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: letter.isReadyToDeliver ? "envelope.open.fill" : "envelope")
                    .foregroundStyle(letter.isReadyToDeliver ? Color.cosmicGold : Color.cosmicTextSecondary)
                Text(deliveryLabel)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                if letter.isReadyToDeliver {
                    Text("OPEN")
                        .font(.cosmicMicro)
                        .tracking(2)
                        .foregroundStyle(Color.cosmicGold)
                }
            }
            if let note = letter.triggerNote, !note.isEmpty {
                Text(note)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            if !letter.isReadyToDeliver {
                Text("Sealed.")
                    .font(.cosmicCaption)
                    .italic()
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
        }
        .padding(Cosmic.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .opacity(letter.isReadyToDeliver ? 1.0 : 0.85)
    }
}

// MARK: - Compose

struct FutureLetterComposeView: View {
    @StateObject private var store = CosmicDiaryStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var letterBody = ""
    @State private var deliveryDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var triggerHint: TriggerHint = .pickADate
    @State private var saveError: String?

    enum TriggerHint: String, CaseIterable, Identifiable {
        case pickADate = "Pick a date"
        case nextMercuryRetrograde = "Next Mercury retrograde"
        case nextSolarReturn = "Next solar return"
        case oneYearFromNow = "One year from now"

        var id: String { rawValue }

        var note: String? {
            self == .pickADate ? nil : rawValue
        }

        /// Stub: only date-picker is wired live. Astrological triggers fall
        /// back to sensible default offsets pending a real ephemeris.
        var defaultDate: Date? {
            let cal = Calendar.current
            switch self {
            case .pickADate: return nil
            case .nextMercuryRetrograde:
                // Approximate: ~3 retrogrades/year → pick 4 months out as a placeholder.
                return cal.date(byAdding: .month, value: 4, to: Date())
            case .nextSolarReturn:
                return cal.date(byAdding: .year, value: 1, to: Date())
            case .oneYearFromNow:
                return cal.date(byAdding: .year, value: 1, to: Date())
            }
        }
    }

    var body: some View {
        Form {
            Section("Your letter") {
                TextEditor(text: $letterBody)
                    .frame(minHeight: 200)
            }

            Section("Deliver on") {
                Picker("Trigger", selection: $triggerHint) {
                    ForEach(TriggerHint.allCases) { hint in
                        Text(hint.rawValue).tag(hint)
                    }
                }
                .onChange(of: triggerHint) { _, new in
                    if let d = new.defaultDate { deliveryDate = d }
                }

                DatePicker(
                    "Delivery date",
                    selection: $deliveryDate,
                    in: Date().addingTimeInterval(60 * 60)...,
                    displayedComponents: [.date]
                )
            }

            if let saveError {
                Section { Text(saveError).foregroundStyle(.red) }
            }
        }
        .navigationTitle("New Letter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Seal") { save() }
                    .foregroundStyle(Color.cosmicGold)
                    .disabled(letterBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save() {
        let trimmed = letterBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            saveError = "Write something first."
            return
        }
        let letter = FutureLetter(
            deliveryDate: deliveryDate,
            body: trimmed,
            triggerNote: triggerHint.note
        )
        store.addLetter(letter)
        Task { await FutureLetterScheduler.schedule(letter) }
        dismiss()
    }
}

// MARK: - Read

struct FutureLetterReadView: View {
    let letter: FutureLetter
    @StateObject private var store = CosmicDiaryStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
                Text("Letter from \(formattedCreated)")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)

                Text(letter.body)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .padding(Cosmic.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cosmicSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card))

                if let note = letter.triggerNote {
                    Text("Triggered by: \(note)")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Button(role: .destructive) {
                    store.deleteLetter(id: letter.id)
                    dismiss()
                } label: {
                    Label("Discard", systemImage: "trash")
                }
                .padding(.top, Cosmic.Spacing.s)
            }
            .padding(Cosmic.Spacing.m)
        }
        .background(Color.cosmicVoid.ignoresSafeArea())
        .navigationTitle("Sealed Letter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    store.markLetterDelivered(id: letter.id)
                    dismiss()
                }
            }
        }
    }

    private var formattedCreated: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: letter.createdAt)
    }
}

// MARK: - Scheduler

/// Schedules a single local notification for a future letter. The body
/// deliberately contains no astrological content — anti-spoiler, in line
/// with the Wave 10 notification redesign.
enum FutureLetterScheduler {
    static func schedule(_ letter: FutureLetter) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "A letter has arrived."
        content.body = "You wrote this for today. Open Astronova to read it."
        content.sound = .default

        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: letter.deliveryDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(
            identifier: letter.notificationIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancel(_ letter: FutureLetter) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [letter.notificationIdentifier]
        )
    }
}
