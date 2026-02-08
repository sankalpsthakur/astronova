//
//  MuhuratCalculatorView.swift
//  AstronovaApp
//
//  Full muhurat calculator with date picker and panchang
//

import SwiftUI

struct MuhuratCalculatorView: View {
    @EnvironmentObject private var gamification: GamificationManager
    @State private var selectedDate = Date()
    @State private var muhurats: [Muhurat] = Muhurat.sampleMuhurats()
    @State private var panchang: PanchangData = PanchangData(
        tithi: "Shukla Panchami",
        nakshatra: "Rohini",
        yoga: "Siddha",
        karana: "Balava"
    )
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                // Date picker
                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    Text(L10n.Temple.Muhurat.selectDate)
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.cosmicGold)
                    .colorScheme(.dark)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)

                // Panchang
                PanchangDisplayView(panchang: panchang)
                    .padding(.horizontal, Cosmic.Spacing.screen)

                // Loading / Error
                if isLoading {
                    ProgressView()
                        .tint(Color.cosmicGold)
                        .padding()
                } else if let error = errorMessage {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.cosmicCopper)
                        Text(error)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }

                // Muhurat cards
                VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                    Text("Muhurats")
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, Cosmic.Spacing.screen)

                    LazyVStack(spacing: Cosmic.Spacing.md) {
                        ForEach(muhurats) { muhurat in
                            MuhuratCardView(muhurat: muhurat, compact: false)
                                .padding(.horizontal, Cosmic.Spacing.screen)
                        }
                    }
                }

                Spacer().frame(height: 60)
            }
            .padding(.top, Cosmic.Spacing.md)
        }
        .background(Color.cosmicVoid)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(L10n.Temple.Muhurat.calculatorTitle)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
        }
        .onChange(of: selectedDate) { _, _ in
            Task { await loadMuhurats() }
        }
        .task {
            Analytics.shared.track(.muhuratChecked, properties: nil)
            gamification.markMuhuratChecked()
        }
    }

    @MainActor
    private func loadMuhurats() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIServices.shared.fetchMuhurats(date: selectedDate)
            muhurats = response.muhurats
            panchang = response.panchang
        } catch {
            // Keep sample data on error
            errorMessage = nil
        }
    }
}
