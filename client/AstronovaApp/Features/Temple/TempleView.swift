//
//  TempleView.swift
//  AstronovaApp
//
//  The Temple tab - Daily bell, DIY Pooja guides, Muhurat calculator, Vedic library
//

import SwiftUI

// MARK: - Temple View

struct TempleView: View {
    @EnvironmentObject private var gamification: GamificationManager
    @State private var muhurats: [Muhurat] = Muhurat.sampleMuhurats()
    @State private var diyPoojas: [DIYPooja] = DIYPooja.samples
    @State private var panchang: PanchangData = PanchangData(
        tithi: "Shukla Panchami",
        nakshatra: "Rohini",
        yoga: "Siddha",
        karana: "Balava"
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicVoid
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Cosmic.Spacing.xl) {
                        // 1. Temple Bell Hero
                        TempleBellView()

                        // 2. DIY Pooja Section
                        DIYPoojaListView(poojas: diyPoojas)

                        // 3. Today's Muhurats
                        muhuratSection

                        // 4. Vedic Wisdom Section
                        vedicWisdomSection

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 120)
                    }
                    .padding(.top, Cosmic.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TempleNavTitle()
                }
            }
            .navigationDestination(for: DIYPooja.self) { pooja in
                DIYPoojaDetailView(pooja: pooja)
                    .environmentObject(gamification)
            }
            .navigationDestination(for: VedicEntry.self) { entry in
                VedicEntryDetailView(entry: entry)
                    .environmentObject(gamification)
            }
        }
        .task {
            await loadTempleData()
        }
    }

    // MARK: - Muhurat Section

    private var muhuratSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(L10n.Temple.Muhurat.title)
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.Temple.Muhurat.subtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Spacer()
                NavigationLink {
                    MuhuratCalculatorView()
                        .environmentObject(gamification)
                } label: {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Text(L10n.Temple.Muhurat.calculatorTitle)
                            .font(.cosmicCaptionEmphasis)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.cosmicGold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            // Panchang badges
            PanchangDisplayView(panchang: panchang)
                .padding(.horizontal, Cosmic.Spacing.screen)

            // Horizontal muhurat cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.md) {
                    ForEach(muhurats) { muhurat in
                        MuhuratCardView(muhurat: muhurat, compact: true)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
        }
    }

    // MARK: - Vedic Wisdom Section

    private var vedicWisdomSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(L10n.Temple.Library.sectionTitle)
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.Temple.Library.sectionSubtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Spacer()
                NavigationLink {
                    VedicLibraryView()
                        .environmentObject(gamification)
                } label: {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Text(L10n.Temple.Library.browseAll)
                            .font(.cosmicCaptionEmphasis)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.cosmicGold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            // Category grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Cosmic.Spacing.md),
                GridItem(.flexible(), spacing: Cosmic.Spacing.md),
                GridItem(.flexible(), spacing: Cosmic.Spacing.md)
            ], spacing: Cosmic.Spacing.md) {
                ForEach(VedicCategory.samples) { category in
                    NavigationLink {
                        VedicLibraryView()
                            .environmentObject(gamification)
                    } label: {
                        VStack(spacing: Cosmic.Spacing.xs) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 22))
                                .foregroundStyle(Color.cosmicGold)

                            Text(category.name)
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Cosmic.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                                .fill(Color.cosmicSurface)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadTempleData() async {
        // Load muhurats
        do {
            let response = try await APIServices.shared.fetchMuhurats()
            muhurats = response.muhurats
            panchang = response.panchang
        } catch {
            // Keep sample data
        }

        // Load DIY poojas
        do {
            let poojas = try await APIServices.shared.fetchDIYPoojas()
            if !poojas.isEmpty {
                diyPoojas = poojas
            }
        } catch {
            // Keep sample data
        }
    }
}

// MARK: - Navigation Title

struct TempleNavTitle: View {
    var body: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Image(systemName: "building.columns.fill")
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicGold)
            Text(L10n.Temple.title)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    TempleView()
        .environmentObject(GamificationManager())
}
