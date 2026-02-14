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
    @State private var planetPositions: [DetailedPlanetaryPosition] = []
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

                        // 4. Navagraha — Live Planetary Positions
                        navagrahaSection

                        // 5. Vedic Wisdom Section
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

    // MARK: - Navagraha Section

    private var navagrahaSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Navagraha")
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Live planetary positions")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Spacer()
                NavigationLink {
                    VedicLibraryView(initialCategory: "Planets")
                        .environmentObject(gamification)
                } label: {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Text("Mantras")
                            .font(.cosmicCaptionEmphasis)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.cosmicGold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            // Planet orbs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.sm) {
                    ForEach(navagrahaOrbs, id: \.name) { planet in
                        VStack(spacing: Cosmic.Spacing.xxs) {
                            ZStack {
                                Circle()
                                    .fill(planet.color.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Circle()
                                    .stroke(planet.color.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 48, height: 48)
                                Text(planet.symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(planet.color)
                            }

                            Text(planet.name)
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .lineLimit(1)

                            Text(planet.sign)
                                .font(.cosmicMicro)
                                .foregroundStyle(Color.cosmicTextSecondary)
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
        }
    }

    private struct NavagrahaOrb {
        let name: String
        let apiName: String
        let symbol: String
        let color: Color
        var sign: String
    }

    private var navagrahaOrbs: [NavagrahaOrb] {
        let defaults: [(String, String, String, Color)] = [
            ("Surya", "Sun", "☉", .planetSun),
            ("Chandra", "Moon", "☽", .planetMoon),
            ("Mangala", "Mars", "♂", .planetMars),
            ("Budha", "Mercury", "☿", .planetMercury),
            ("Guru", "Jupiter", "♃", .planetJupiter),
            ("Shukra", "Venus", "♀", .planetVenus),
            ("Shani", "Saturn", "♄", .planetSaturn),
            ("Rahu", "Rahu", "☊", .planetRahu),
            ("Ketu", "Ketu", "☋", .planetKetu),
        ]

        return defaults.map { name, apiName, symbol, color in
            let position = planetPositions.first { $0.name == apiName }
            let sign = position.map { abbreviateSign($0.sign) } ?? "—"
            return NavagrahaOrb(name: name, apiName: apiName, symbol: symbol, color: color, sign: sign)
        }
    }

    private func abbreviateSign(_ sign: String) -> String {
        let map = [
            "Aries": "Ari", "Taurus": "Tau", "Gemini": "Gem",
            "Cancer": "Can", "Leo": "Leo", "Virgo": "Vir",
            "Libra": "Lib", "Scorpio": "Sco", "Sagittarius": "Sag",
            "Capricorn": "Cap", "Aquarius": "Aqu", "Pisces": "Pis"
        ]
        return map[sign] ?? String(sign.prefix(3))
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
                ForEach(VedicCategory.samples.filter { $0.name != "Planets" }) { category in
                    NavigationLink {
                        VedicLibraryView(initialCategory: category.name)
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

        // Load planetary positions
        do {
            planetPositions = try await APIServices.shared.getDetailedPlanetaryPositions()
        } catch {
            // Show dashes for signs
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
