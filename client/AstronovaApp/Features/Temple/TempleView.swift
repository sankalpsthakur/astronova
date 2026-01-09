//
//  TempleView.swift
//  AstronovaApp
//
//  The Temple tab - A sacred space for Astrologers, Oracle, and Pooja
//

import SwiftUI

// MARK: - Temple View

struct TempleView: View {
    @State private var selectedSection: TempleSection = .astrologers
    @State private var showingOracleSheet = false
    @State private var selectedPooja: PoojaItem?
    @State private var selectedAstrologer: Astrologer?

    enum TempleSection: String, CaseIterable {
        case astrologers = "Astrologers"
        case pooja = "Pooja"

        var icon: String {
            switch self {
            case .astrologers: return "person.crop.circle.badge.checkmark"
            case .pooja: return "flame.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.cosmicVoid
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Cosmic.Spacing.xl) {
                        // Oracle Quick Access Card
                        OracleQuickAccessCard(onTap: { showingOracleSheet = true })
                            .padding(.horizontal, Cosmic.Spacing.screen)

                        // Section Picker
                        TempleSectionPicker(selection: $selectedSection)
                            .padding(.horizontal, Cosmic.Spacing.screen)

                        // Content based on selection
                        switch selectedSection {
                        case .astrologers:
                            AstrologersSection(
                                astrologers: Astrologer.samples,
                                onSelect: { selectedAstrologer = $0 }
                            )
                        case .pooja:
                            PoojaSection(
                                muhurats: Muhurat.sampleMuhurats(),
                                poojas: PoojaItem.samples,
                                onSelectPooja: { selectedPooja = $0 }
                            )
                        }

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
        }
        .fullScreenCover(isPresented: $showingOracleSheet) {
            OracleSheetWrapper(isPresented: $showingOracleSheet)
        }
        .sheet(item: $selectedPooja) { pooja in
            PoojaDetailSheet(pooja: pooja)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedAstrologer) { astrologer in
            AstrologerDetailSheet(astrologer: astrologer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Oracle Sheet Wrapper

struct OracleSheetWrapper: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            OracleView()

            // Close button overlay
            Button {
                CosmicHaptics.light()
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .background(Circle().fill(Color.cosmicVoid).padding(4))
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
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
            Text("Temple")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }
}

// MARK: - Section Picker

struct TempleSectionPicker: View {
    @Binding var selection: TempleView.TempleSection

    var body: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            ForEach(TempleView.TempleSection.allCases, id: \.self) { section in
                Button {
                    CosmicHaptics.light()
                    withAnimation(.cosmicSpring) {
                        selection = section
                    }
                } label: {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: section.icon)
                            .font(.cosmicCaption)
                        Text(section.rawValue)
                            .font(.cosmicCalloutEmphasis)
                    }
                    .foregroundStyle(selection == section ? Color.cosmicVoid : Color.cosmicTextSecondary)
                    .padding(.horizontal, Cosmic.Spacing.md)
                    .padding(.vertical, Cosmic.Spacing.s)
                    .background {
                        if selection == section {
                            Capsule()
                                .fill(LinearGradient.cosmicAntiqueGold)
                        } else {
                            Capsule()
                                .stroke(Color.cosmicTextTertiary.opacity(0.3), lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

// MARK: - Oracle Quick Access Card

struct OracleQuickAccessCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Cosmic.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cosmicAmethyst.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.cosmicGold)
                }

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Ask the Oracle")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Get personalized cosmic guidance")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicGold)
            }
            .padding(Cosmic.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                    .fill(Color.cosmicSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.cosmicGold.opacity(0.3), Color.cosmicAmethyst.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Astrologers Section

struct AstrologersSection: View {
    let astrologers: [Astrologer]
    let onSelect: (Astrologer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Expert Astrologers")
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text("Connect with verified Vedic experts")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            // Online Astrologers
            let onlineAstrologers = astrologers.filter { $0.isOnline }
            if !onlineAstrologers.isEmpty {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Circle()
                            .fill(Color.cosmicSuccess)
                            .frame(width: 8, height: 8)
                        Text("Available Now")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicSuccess)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Cosmic.Spacing.md) {
                            ForEach(onlineAstrologers) { astrologer in
                                AstrologerCard(astrologer: astrologer, onTap: { onSelect(astrologer) })
                            }
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)
                    }
                }
            }

            // Offline Astrologers
            let offlineAstrologers = astrologers.filter { !$0.isOnline }
            if !offlineAstrologers.isEmpty {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Circle()
                            .fill(Color.cosmicTextTertiary)
                            .frame(width: 8, height: 8)
                        Text("Currently Offline")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                    .padding(.top, Cosmic.Spacing.s)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Cosmic.Spacing.md) {
                            ForEach(offlineAstrologers) { astrologer in
                                AstrologerCard(astrologer: astrologer, onTap: { onSelect(astrologer) })
                                    .opacity(0.7)
                            }
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)
                    }
                }
            }
        }
    }
}

// MARK: - Astrologer Card

struct AstrologerCard: View {
    let astrologer: Astrologer
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Cosmic.Spacing.s) {
                // Avatar with status
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cosmicAmethyst.opacity(0.3), Color.cosmicCosmos],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay {
                            Text(String(astrologer.name.prefix(1)))
                                .font(.cosmicTitle2)
                                .foregroundStyle(Color.cosmicGold)
                        }

                    if astrologer.isOnline {
                        Circle()
                            .fill(Color.cosmicSuccess)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Circle()
                                    .stroke(Color.cosmicVoid, lineWidth: 2)
                            }
                    }
                }

                // Name
                Text(astrologer.name)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)

                // Specialization
                Text(astrologer.specialization)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(1)

                // Rating
                HStack(spacing: Cosmic.Spacing.xxs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.cosmicGold)
                    Text(String(format: "%.1f", astrologer.rating))
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                // Price
                Text("\(astrologer.pricePerMinute)/min")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)
            }
            .frame(width: 120)
            .padding(.vertical, Cosmic.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                    .fill(Color.cosmicSurface)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Astrologer Detail Sheet

struct AstrologerDetailSheet: View {
    let astrologer: Astrologer
    @Environment(\.dismiss) private var dismiss
    @State private var showConsultationSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Cosmic.Spacing.xl) {
                    // Header
                    VStack(spacing: Cosmic.Spacing.md) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cosmicAmethyst.opacity(0.4), Color.cosmicCosmos],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Text(String(astrologer.name.prefix(1)))
                                        .font(.cosmicDisplay)
                                        .foregroundStyle(Color.cosmicGold)
                                }

                            if astrologer.isOnline {
                                Circle()
                                    .fill(Color.cosmicSuccess)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        Circle()
                                            .stroke(Color.cosmicVoid, lineWidth: 3)
                                    }
                            }
                        }

                        Text(astrologer.name)
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(astrologer.specialization)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)

                        HStack(spacing: Cosmic.Spacing.lg) {
                            StatBadge(icon: "star.fill", value: String(format: "%.1f", astrologer.rating), label: "\(astrologer.reviewCount) reviews")
                            StatBadge(icon: "clock.fill", value: astrologer.experience, label: "Experience")
                            StatBadge(icon: "indianrupeesign", value: "\(astrologer.pricePerMinute)", label: "per min")
                        }
                    }
                    .padding(.top, Cosmic.Spacing.xl)

                    // Languages
                    DetailSection(title: "Languages") {
                        HStack(spacing: Cosmic.Spacing.s) {
                            ForEach(astrologer.languages, id: \.self) { lang in
                                Text(lang)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .padding(.horizontal, Cosmic.Spacing.s)
                                    .padding(.vertical, Cosmic.Spacing.xxs)
                                    .background(Capsule().fill(Color.cosmicSurface))
                            }
                        }
                    }

                    // Expertise
                    DetailSection(title: "Expertise") {
                        FlowLayout(spacing: Cosmic.Spacing.s) {
                            ForEach(astrologer.expertise, id: \.self) { skill in
                                Text(skill)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicGold)
                                    .padding(.horizontal, Cosmic.Spacing.s)
                                    .padding(.vertical, Cosmic.Spacing.xxs)
                                    .background {
                                        Capsule()
                                            .stroke(Color.cosmicGold.opacity(0.4), lineWidth: 1)
                                    }
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 40)

                    // CTA
                    Button {
                        CosmicHaptics.medium()
                        showConsultationSheet = true
                    } label: {
                        HStack {
                            Image(systemName: astrologer.isOnline ? "phone.fill" : "bell.fill")
                            Text(astrologer.isOnline ? "Start Consultation" : "Notify When Available")
                        }
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(maxWidth: .infinity)
                        .frame(height: Cosmic.ButtonHeight.large)
                        .background(LinearGradient.cosmicAntiqueGold)
                        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showConsultationSheet) {
                ConsultationBookingSheet(astrologer: astrologer)
            }
        }
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Cosmic.Spacing.xxs) {
            HStack(spacing: Cosmic.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.cosmicGold)
                Text(value)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            Text(label)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            Text(title)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Cosmic.Spacing.screen)
    }
}

// MARK: - Pooja Section

struct PoojaSection: View {
    let muhurats: [Muhurat]
    let poojas: [PoojaItem]
    let onSelectPooja: (PoojaItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xl) {
            // Muhurat Section
            VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text("Today's Muhurat")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextPrimary)
                        Text("Auspicious timings for the day")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, Cosmic.Spacing.screen)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Cosmic.Spacing.md) {
                        ForEach(muhurats) { muhurat in
                            MuhuratCard(muhurat: muhurat)
                        }
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                }
            }

            // Pooja Items Section
            VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text("Sacred Rituals")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextPrimary)
                        Text("Perform poojas with complete ingredients")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, Cosmic.Spacing.screen)

                LazyVStack(spacing: Cosmic.Spacing.md) {
                    ForEach(poojas) { pooja in
                        PoojaCard(pooja: pooja, onTap: { onSelectPooja(pooja) })
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
        }
    }
}

// MARK: - Muhurat Card

struct MuhuratCard: View {
    let muhurat: Muhurat

    private var qualityColor: Color {
        switch muhurat.quality {
        case .excellent: return Color.cosmicGold
        case .good: return Color.cosmicSuccess
        case .neutral: return Color.cosmicTextSecondary
        case .avoid: return Color.cosmicError
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            // Quality badge
            HStack(spacing: Cosmic.Spacing.xxs) {
                Image(systemName: muhurat.quality.icon)
                    .font(.system(size: 10))
                Text(muhurat.quality.displayName)
                    .font(.cosmicMicro)
            }
            .foregroundStyle(qualityColor)

            Text(muhurat.name)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)

            Text(muhurat.timeRange)
                .font(.cosmicHeadline)
                .foregroundStyle(qualityColor)

            Text(muhurat.description)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 160)
        .padding(Cosmic.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                .fill(Color.cosmicSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                        .stroke(qualityColor.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - Pooja Card

struct PoojaCard: View {
    let pooja: PoojaItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Cosmic.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cosmicGold.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: pooja.iconName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.cosmicGold)
                }

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(pooja.name)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(pooja.description)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(1)

                    HStack(spacing: Cosmic.Spacing.s) {
                        Label(pooja.duration, systemImage: "clock")
                        Label("\(pooja.ingredients.count) items", systemImage: "list.bullet")
                    }
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(Cosmic.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                    .fill(Color.cosmicSurface)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pooja Detail Sheet

struct PoojaDetailSheet: View {
    let pooja: PoojaItem
    @Environment(\.dismiss) private var dismiss
    @State private var checkedIngredients: Set<UUID> = []
    @State private var showBookingSheet = false

    private var groupedIngredients: [IngredientCategory: [PoojaIngredient]] {
        Dictionary(grouping: pooja.ingredients, by: { $0.category })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Cosmic.Spacing.xl) {
                    // Header
                    VStack(spacing: Cosmic.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.cosmicGold.opacity(0.3), Color.cosmicVoid],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: pooja.iconName)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(Color.cosmicGold)
                        }

                        Text(pooja.name)
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(pooja.description)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: Cosmic.Spacing.lg) {
                            Label(pooja.duration, systemImage: "clock.fill")
                            Label(pooja.deity, systemImage: "sparkles")
                        }
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicGold)
                    }
                    .padding(.top, Cosmic.Spacing.xl)
                    .padding(.horizontal, Cosmic.Spacing.screen)

                    // Benefits
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                        Text("Benefits")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)

                        FlowLayout(spacing: Cosmic.Spacing.s) {
                            ForEach(pooja.benefits, id: \.self) { benefit in
                                HStack(spacing: Cosmic.Spacing.xxs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.cosmicSuccess)
                                    Text(benefit)
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextPrimary)
                                }
                                .padding(.horizontal, Cosmic.Spacing.s)
                                .padding(.vertical, Cosmic.Spacing.xxs)
                                .background {
                                    Capsule()
                                        .fill(Color.cosmicSurface)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Cosmic.Spacing.screen)

                    // Ingredients Checklist
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                        HStack {
                            Text("Ingredients Checklist")
                                .font(.cosmicTitle3)
                                .foregroundStyle(Color.cosmicTextPrimary)
                            Spacer()
                            Text("\(checkedIngredients.count)/\(pooja.ingredients.count)")
                                .font(.cosmicCaptionEmphasis)
                                .foregroundStyle(Color.cosmicGold)
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)

                        ForEach([IngredientCategory.essential, .flowers, .offering, .special], id: \.self) { category in
                            if let ingredients = groupedIngredients[category], !ingredients.isEmpty {
                                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                    HStack(spacing: Cosmic.Spacing.xs) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.cosmicGold)
                                        Text(category.displayName)
                                            .font(.cosmicCaptionEmphasis)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                    }

                                    ForEach(ingredients) { ingredient in
                                        IngredientRow(
                                            ingredient: ingredient,
                                            isChecked: checkedIngredients.contains(ingredient.id),
                                            onToggle: {
                                                CosmicHaptics.light()
                                                if checkedIngredients.contains(ingredient.id) {
                                                    checkedIngredients.remove(ingredient.id)
                                                } else {
                                                    checkedIngredients.insert(ingredient.id)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, Cosmic.Spacing.screen)
                            }
                        }
                    }

                    // Book Pooja CTA
                    Button {
                        CosmicHaptics.medium()
                        showBookingSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Book This Pooja")
                        }
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(maxWidth: .infinity)
                        .frame(height: Cosmic.ButtonHeight.large)
                        .background(LinearGradient.cosmicAntiqueGold)
                        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)

                    Spacer()
                        .frame(height: 40)
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pooja Details")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showBookingSheet) {
            PoojaBookingSheet(poojaItem: pooja)
        }
    }
}

// MARK: - Pooja Booking Sheet

struct PoojaBookingSheet: View {
    let poojaItem: PoojaItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState

    @State private var selectedDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var selectedTimeSlot: String = "10:00"
    @State private var sankalpName: String = ""
    @State private var sankalpGotra: String = ""
    @State private var sankalpNakshatra: String = ""
    @State private var specialRequests: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var bookingResponse: PoojaBookingResponse?
    @State private var errorMessage: String?

    private let timeSlots = ["06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
                             "16:00", "17:00", "18:00", "19:00"]

    var body: some View {
        NavigationStack {
            Group {
                if authState.isAuthenticated {
                    ScrollView {
                        VStack(spacing: Cosmic.Spacing.xl) {
                            // Pooja Summary
                            HStack(spacing: Cosmic.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color.cosmicGold.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: poojaItem.iconName)
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color.cosmicGold)
                                }

                                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                                    Text(poojaItem.name)
                                        .font(.cosmicHeadline)
                                        .foregroundStyle(Color.cosmicTextPrimary)
                                    Text(poojaItem.deity)
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                    Text(poojaItem.duration)
                                        .font(.cosmicMicro)
                                        .foregroundStyle(Color.cosmicGold)
                                }
                                Spacer()
                            }
                            .padding(Cosmic.Spacing.md)
                            .background(Color.cosmicSurface)
                            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Date Selection
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Select Date")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                DatePicker(
                                    "Date",
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color.cosmicGold)
                                .colorScheme(.dark)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Time Selection
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Select Time")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Cosmic.Spacing.s) {
                                    ForEach(timeSlots, id: \.self) { slot in
                                        Button {
                                            CosmicHaptics.light()
                                            selectedTimeSlot = slot
                                        } label: {
                                            Text(slot)
                                                .font(.cosmicCaption)
                                                .foregroundStyle(selectedTimeSlot == slot ? Color.cosmicVoid : Color.cosmicTextPrimary)
                                                .padding(.vertical, Cosmic.Spacing.xs)
                                                .padding(.horizontal, Cosmic.Spacing.s)
                                                .background {
                                                    if selectedTimeSlot == slot {
                                                        Capsule().fill(LinearGradient.cosmicAntiqueGold)
                                                    } else {
                                                        Capsule().stroke(Color.cosmicTextTertiary.opacity(0.3), lineWidth: 1)
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Sankalp Details
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                                Text("Sankalp Details")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                VStack(spacing: Cosmic.Spacing.s) {
                                    BookingTextField(title: "Name (Sankalp)", text: $sankalpName, placeholder: "Your full name")
                                    BookingTextField(title: "Gotra (optional)", text: $sankalpGotra, placeholder: "Family lineage")
                                    BookingTextField(title: "Nakshatra (optional)", text: $sankalpNakshatra, placeholder: "Birth star")
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Special Requests
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Special Requests (optional)")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                TextEditor(text: $specialRequests)
                                    .font(.cosmicBody)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(Cosmic.Spacing.s)
                                    .background(Color.cosmicSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Error Message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicError)
                                    .padding(.horizontal, Cosmic.Spacing.screen)
                            }

                            // Book Button
                            Button {
                                Task { await bookPooja() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(Color.cosmicVoid)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Confirm Booking")
                                    }
                                }
                                .font(.cosmicHeadline)
                                .foregroundStyle(Color.cosmicVoid)
                                .frame(maxWidth: .infinity)
                                .frame(height: Cosmic.ButtonHeight.large)
                                .background(LinearGradient.cosmicAntiqueGold)
                                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                            }
                            .disabled(sankalpName.isEmpty || isLoading)
                            .opacity(sankalpName.isEmpty ? 0.5 : 1)
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            Spacer().frame(height: 40)
                        }
                        .padding(.top, Cosmic.Spacing.md)
                    }
                } else {
                    VStack {
                        Spacer()
                        AuthRequiredView(
                            title: "Sign in to book a pooja",
                            message: "Confirm your details and reserve a pandit time slot."
                        )
                        Spacer()
                    }
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Book Pooja")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
        }
        .alert("Booking Confirmed!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            if let response = bookingResponse {
                Text("Your pooja is scheduled for \(response.scheduledDate) at \(response.scheduledTime). You will receive a session link before the scheduled time.")
            }
        }
    }

    private func bookPooja() async {
        guard !sankalpName.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Map local poojaItem.id to API pooja type ID
            let poojaTypeId = mapPoojaItemToAPIId(poojaItem.id)

            Analytics.shared.track(.templeBookingStarted, properties: [
                "pooja_type": poojaTypeId,
                "pandit_id": "auto_assigned"
            ])

            let response = try await APIServices.shared.createPoojaBooking(
                poojaTypeId: poojaTypeId,
                panditId: nil,
                scheduledDate: selectedDate,
                scheduledTime: selectedTimeSlot,
                timezone: TimeZone.current.identifier,
                sankalpName: sankalpName,
                sankalpGotra: sankalpGotra.isEmpty ? nil : sankalpGotra,
                sankalpNakshatra: sankalpNakshatra.isEmpty ? nil : sankalpNakshatra,
                specialRequests: specialRequests.isEmpty ? nil : specialRequests
            )

            Analytics.shared.track(.templeBookingCompleted, properties: [
                "booking_id": response.bookingId,
                "pooja_type": poojaTypeId
            ])

            bookingResponse = response
            showSuccess = true
            CosmicHaptics.success()
        } catch {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .authenticationFailed, .tokenExpired:
                    errorMessage = "Sign in to book a pooja."
                case .offline:
                    errorMessage = "No internet connection. Please try again."
                case .timeout:
                    errorMessage = "Request timed out. Please try again."
                case .serverError(let code, _):
                    errorMessage = "Server error (\(code)). Please try again."
                default:
                    errorMessage = "Failed to create booking. Please try again."
                }
            } else {
                errorMessage = "Failed to create booking. Please try again."
            }
            CosmicHaptics.error()
        }

        isLoading = false
    }

    private func mapPoojaItemToAPIId(_ localId: String) -> String {
        // Map sample PoojaItem IDs to API pooja type IDs
        switch localId {
        case "pooja_001": return "pooja_ganesh"
        case "pooja_002": return "pooja_lakshmi"
        case "pooja_003": return "pooja_navagraha"
        case "pooja_004": return "pooja_satyanarayan"
        default: return "pooja_ganesh"
        }
    }
}

// MARK: - Consultation Booking Sheet

struct ConsultationBookingSheet: View {
    let astrologer: Astrologer
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState

    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var selectedTimeSlot: String = "10:00"
    @State private var durationMinutes: Int = 30
    @State private var topic: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let timeSlots = ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00", "18:00", "19:00"]
    private let durations = [15, 30, 60]

    private var totalPrice: Int {
        durationMinutes * astrologer.pricePerMinute
    }

    var body: some View {
        NavigationStack {
            Group {
                if authState.isAuthenticated {
                    ScrollView {
                        VStack(spacing: Cosmic.Spacing.xl) {
                            HStack(spacing: Cosmic.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color.cosmicGold.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "person.crop.circle.badge.checkmark")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color.cosmicGold)
                                }

                                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                                    Text(astrologer.name)
                                        .font(.cosmicHeadline)
                                        .foregroundStyle(Color.cosmicTextPrimary)
                                    Text(astrologer.specialization)
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                    Text("₹\(astrologer.pricePerMinute)/min")
                                        .font(.cosmicMicro)
                                        .foregroundStyle(Color.cosmicGold)
                                }
                                Spacer()
                            }
                            .padding(Cosmic.Spacing.md)
                            .background(Color.cosmicSurface)
                            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Select Date")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                DatePicker(
                                    "Date",
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color.cosmicGold)
                                .colorScheme(.dark)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Select Time")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Cosmic.Spacing.s) {
                                    ForEach(timeSlots, id: \.self) { slot in
                                        Button {
                                            CosmicHaptics.light()
                                            selectedTimeSlot = slot
                                        } label: {
                                            Text(slot)
                                                .font(.cosmicCaption)
                                                .foregroundStyle(selectedTimeSlot == slot ? Color.cosmicVoid : Color.cosmicTextPrimary)
                                                .padding(.vertical, Cosmic.Spacing.xs)
                                                .padding(.horizontal, Cosmic.Spacing.s)
                                                .background {
                                                    if selectedTimeSlot == slot {
                                                        Capsule().fill(LinearGradient.cosmicAntiqueGold)
                                                    } else {
                                                        Capsule().stroke(Color.cosmicTextTertiary.opacity(0.3), lineWidth: 1)
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Duration")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                Picker("Duration", selection: $durationMinutes) {
                                    ForEach(durations, id: \.self) { minutes in
                                        Text("\(minutes) min").tag(minutes)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text("Topic (optional)")
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextTertiary)

                                TextEditor(text: $topic)
                                    .font(.cosmicBody)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(Cosmic.Spacing.s)
                                    .background(Color.cosmicSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            HStack {
                                Text("Total")
                                    .font(.cosmicCalloutEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                Spacer()
                                Text("₹\(totalPrice)")
                                    .font(.cosmicHeadline)
                                    .foregroundStyle(Color.cosmicGold)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicError)
                                    .padding(.horizontal, Cosmic.Spacing.screen)
                            }

                            Button {
                                Task { await bookConsultation() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(Color.cosmicVoid)
                                    } else {
                                        Image(systemName: "phone.fill")
                                        Text("Book Consultation")
                                    }
                                }
                                .font(.cosmicHeadline)
                                .foregroundStyle(Color.cosmicVoid)
                                .frame(maxWidth: .infinity)
                                .frame(height: Cosmic.ButtonHeight.large)
                                .background(LinearGradient.cosmicAntiqueGold)
                                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                            }
                            .disabled(isLoading)
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            Spacer().frame(height: 40)
                        }
                        .padding(.top, Cosmic.Spacing.md)
                    }
                } else {
                    VStack {
                        Spacer()
                        AuthRequiredView(
                            title: "Sign in to book a consultation",
                            message: "Reserve a time and get personalized guidance."
                        )
                        Spacer()
                    }
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Book Consultation")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
        }
        .alert("Consultation Booked!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your consultation is scheduled for \(formattedDate(selectedDate)) at \(selectedTimeSlot).")
        }
    }

    private func bookConsultation() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIServices.shared.createPoojaBooking(
                poojaTypeId: "pooja_consultation",
                panditId: nil,
                scheduledDate: selectedDate,
                scheduledTime: selectedTimeSlot,
                timezone: TimeZone.current.identifier,
                sankalpName: authState.profileManager.profile.fullName.isEmpty ? nil : authState.profileManager.profile.fullName,
                sankalpGotra: nil,
                sankalpNakshatra: nil,
                specialRequests: topic.isEmpty ? nil : topic
            )

            _ = response
            showSuccess = true
        } catch {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .authenticationFailed, .tokenExpired:
                    errorMessage = "Sign in to book a consultation."
                case .offline:
                    errorMessage = "No internet connection. Please try again."
                case .timeout:
                    errorMessage = "Request timed out. Please try again."
                case .serverError(let code, _):
                    errorMessage = "Server error (\(code)). Please try again."
                default:
                    errorMessage = "Unable to book consultation. Please try again."
                }
            } else {
                errorMessage = "Unable to book consultation. Please try again."
            }
        }

        isLoading = false
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Booking Text Field

struct BookingTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            Text(title)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)

            TextField(placeholder, text: $text)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding(Cosmic.Spacing.s)
                .background(Color.cosmicSurface)
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
        }
    }
}

struct IngredientRow: View {
    let ingredient: PoojaIngredient
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Cosmic.Spacing.md) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.cosmicBody)
                    .foregroundStyle(isChecked ? Color.cosmicSuccess : Color.cosmicTextTertiary)

                Text(ingredient.name)
                    .font(.cosmicBody)
                    .foregroundStyle(isChecked ? Color.cosmicTextSecondary : Color.cosmicTextPrimary)
                    .strikethrough(isChecked, color: Color.cosmicTextTertiary)

                Spacer()

                Text(ingredient.quantity)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .padding(.vertical, Cosmic.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TempleView()
        .environmentObject(AuthState())
}
