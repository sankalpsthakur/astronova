//
//  TempleView.swift
//  AstronovaApp
//
//  The Temple tab - A sacred space for Astrologers, Oracle, and Pooja
//

import SwiftUI

// MARK: - Temple View

struct TempleView: View {
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false
    @State private var selectedSection: TempleSection = .astrologers
    @State private var showingOracleSheet = false
    @State private var selectedPooja: PoojaItem?
    @State private var selectedAstrologer: Astrologer?
    @State private var astrologers: [Astrologer] = Astrologer.samples
    @State private var isLoadingPandits = false
    @State private var panditLoadError: String?
    @State private var didLoadPandits = false

    enum TempleSection: CaseIterable {
        case astrologers
        case pooja

        var title: String {
            switch self {
            case .astrologers: return L10n.Temple.Sections.astrologers
            case .pooja: return L10n.Temple.Sections.pooja
            }
        }

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
                            VStack(spacing: Cosmic.Spacing.md) {
                                if isLoadingPandits {
                                    HStack(spacing: Cosmic.Spacing.xs) {
                                        ProgressView()
                                            .tint(Color.cosmicGold)
                                        Text("Loading pandits…")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, Cosmic.Spacing.screen)
                                } else if let panditLoadError {
                                    HStack(spacing: Cosmic.Spacing.xs) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicCopper)
                                        Text(panditLoadError)
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                        Spacer()
                                        Button("Retry") {
                                            Task { await loadPandits(force: true) }
                                        }
                                        .font(.cosmicCaptionEmphasis)
                                        .foregroundStyle(Color.cosmicGold)
                                    }
                                    .padding(.horizontal, Cosmic.Spacing.screen)
                                }

                                AstrologersSection(
                                    astrologers: astrologers,
                                    onSelect: { selectedAstrologer = $0 }
                                )
                            }
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
        .task {
            await loadPandits()
        }
        .onAppear {
            // Check if we should show Oracle with chat packages (triggered from PaywallView)
            if triggerShowChatPackages {
                triggerShowChatPackages = false
                showingOracleSheet = true
            }
        }
        .onChange(of: triggerShowChatPackages) { _, newValue in
            if newValue {
                triggerShowChatPackages = false
                showingOracleSheet = true
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

    @MainActor
    private func loadPandits(force: Bool = false) async {
        if isLoadingPandits {
            return
        }
        if didLoadPandits && !force {
            return
        }

        isLoadingPandits = true
        panditLoadError = nil

        defer {
            isLoadingPandits = false
            didLoadPandits = true
        }

        do {
            let pandits = try await APIServices.shared.listPandits(availableOnly: false)
            let mapped = pandits.map(Astrologer.fromPandit)
            if !mapped.isEmpty {
                astrologers = mapped
            }
        } catch let error as NetworkError {
            switch error {
            case .offline:
                panditLoadError = L10n.Errors.noInternet
            case .timeout:
                panditLoadError = L10n.Errors.timeout
            case .authenticationFailed, .tokenExpired:
                panditLoadError = L10n.Errors.generic
            default:
                panditLoadError = L10n.Errors.generic
            }
        } catch {
            panditLoadError = L10n.Errors.generic
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
            .accessibleIconButton()
            .accessibilityLabel(L10n.Actions.close)
            .accessibilityHint(L10n.Oracle.Accessibility.closeHint)
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
            Text(L10n.Temple.title)
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
                        Text(section.title)
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
                .accessibleTouchTarget()
                .accessibilityLabel(section.title)
                .accessibilityHint(section == .astrologers
                                   ? L10n.Temple.Sections.astrologersHint
                                   : L10n.Temple.Sections.poojaHint)
                .accessibilityAddTraits(selection == section ? [.isSelected] : [])
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
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(L10n.Temple.OracleQuickAccess.title)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(L10n.Temple.OracleQuickAccess.subtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicGold)
                    .accessibilityHidden(true)
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
        .accessibilityIdentifier(AccessibilityID.oracleQuickAccessButton)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.Temple.OracleQuickAccess.accessibilityLabel)
        .accessibilityHint(L10n.Temple.OracleQuickAccess.accessibilityHint)
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
                    Text(L10n.Temple.Astrologers.headerTitle)
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.Temple.Astrologers.headerSubtitle)
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
                            .accessibilityHidden(true)
                        Text(L10n.Temple.Astrologers.availableNow)
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
                            .accessibilityHidden(true)
                        Text(L10n.Temple.Astrologers.currentlyOffline)
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
                        .accessibilityHidden(true)

                    if astrologer.isOnline {
                        Circle()
                            .fill(Color.cosmicSuccess)
                            .frame(width: 16, height: 16)
                            .overlay {
                                Circle()
                                    .stroke(Color.cosmicVoid, lineWidth: 2)
                            }
                            .accessibilityHidden(true)
                    }
                }

                // Name
                Text(astrologer.name)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

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
                        .accessibilityHidden(true)
                    Text(String(format: "%.1f", astrologer.rating))
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                // Price
                Text(L10n.Temple.Astrologers.pricePerMinute("\(astrologer.pricePerMinute)"))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L10n.Temple.Astrologers.cardAccessibilityLabel(
                name: astrologer.name,
                experience: astrologer.experience,
                rating: String(format: "%.1f", astrologer.rating),
                specialization: astrologer.specialization,
                pricePerMinute: "\(astrologer.pricePerMinute)",
                isOnline: astrologer.isOnline
            )
        )
        .accessibilityHint(L10n.Temple.Astrologers.cardAccessibilityHint)
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
                            StatBadge(
                                icon: "star.fill",
                                value: String(format: "%.1f", astrologer.rating),
                                label: L10n.Temple.Astrologers.reviews(astrologer.reviewCount)
                            )
                            StatBadge(
                                icon: "clock.fill",
                                value: astrologer.experience,
                                label: L10n.Temple.Astrologers.experienceLabel
                            )
                            StatBadge(
                                icon: "indianrupeesign",
                                value: "\(astrologer.pricePerMinute)",
                                label: L10n.Temple.Astrologers.perMinuteLabel
                            )
                        }
                    }
                    .padding(.top, Cosmic.Spacing.xl)

                    // Languages
                    DetailSection(title: L10n.Temple.Astrologers.languagesTitle) {
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
                    DetailSection(title: L10n.Temple.Astrologers.expertiseTitle) {
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
                            Text(astrologer.isOnline
                                 ? L10n.Temple.Astrologers.startConsultation
                                 : L10n.Temple.Astrologers.notifyWhenAvailable)
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
                    .accessibleIconButton()
                    .accessibilityLabel(L10n.Actions.close)
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
                        Text(L10n.Temple.Muhurat.title)
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(L10n.Temple.Muhurat.subtitle)
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
                        Text(L10n.Temple.Pooja.ritualsTitle)
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(L10n.Temple.Pooja.ritualsSubtitle)
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
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L10n.Temple.Muhurat.accessibilityLabel(
                name: muhurat.name,
                quality: muhurat.quality.displayName,
                timeRange: muhurat.timeRange,
                description: muhurat.description
            )
        )
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
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(pooja.name)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(pooja.description)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(2)

                    HStack(spacing: Cosmic.Spacing.s) {
                        Label(pooja.duration, systemImage: "clock")
                        Label(L10n.Temple.Pooja.itemsCount(pooja.ingredients.count), systemImage: "list.bullet")
                    }
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Cosmic.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                    .fill(Color.cosmicSurface)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L10n.Temple.Pooja.cardAccessibilityLabel(
                name: pooja.name,
                duration: pooja.duration,
                items: pooja.ingredients.count,
                description: pooja.description
            )
        )
        .accessibilityHint(L10n.Temple.Pooja.cardAccessibilityHint)
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
                                .accessibilityHidden(true)
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
                        Text(L10n.Temple.Pooja.benefitsTitle)
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextTertiary)
                            .accessibilityAddTraits(.isHeader)

                        FlowLayout(spacing: Cosmic.Spacing.s) {
                            ForEach(pooja.benefits, id: \.self) { benefit in
                                HStack(spacing: Cosmic.Spacing.xxs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.cosmicSuccess)
                                        .accessibilityHidden(true)
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
                            Text(L10n.Temple.Pooja.ingredientsChecklistTitle)
                                .font(.cosmicTitle3)
                                .foregroundStyle(Color.cosmicTextPrimary)
                                .accessibilityAddTraits(.isHeader)
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
                            Text(L10n.Temple.Pooja.bookThisPooja)
                        }
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicVoid)
                        .frame(maxWidth: .infinity)
                        .frame(height: Cosmic.ButtonHeight.large)
                        .background(LinearGradient.cosmicAntiqueGold)
                        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                    }
                    .accessibilityLabel(L10n.Temple.Pooja.bookThisPoojaLabel)
                    .accessibilityHint(L10n.Temple.Pooja.bookThisPoojaHint)
                    .padding(.horizontal, Cosmic.Spacing.screen)

                    Spacer()
                        .frame(height: 40)
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.Temple.Pooja.detailsTitle)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .accessibleIconButton()
                    .accessibilityLabel(L10n.Actions.close)
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
    @State private var showingVideoSession = false
    @State private var videoSessionId: String = ""

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
                                Text(L10n.Temple.Booking.selectDate)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .accessibilityAddTraits(.isHeader)

                                DatePicker(
                                    L10n.Temple.Consultation.consultationDateLabel,
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color.cosmicGold)
                                .colorScheme(.dark)
                                .accessibilityLabel(L10n.Temple.Booking.poojaDateLabel)
                                .accessibilityHint(L10n.Temple.Booking.poojaDateHint)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Time Selection
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text(L10n.Temple.Booking.selectTime)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .accessibilityAddTraits(.isHeader)

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
                                        .accessibleTouchTarget()
                                        .accessibilityLabel(L10n.Temple.Booking.timeSlotLabel(slot))
                                        .accessibilityHint(L10n.Temple.Booking.timeSlotHint)
                                        .accessibilityAddTraits(selectedTimeSlot == slot ? [.isSelected] : [])
                                    }
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Sankalp Details
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                                Text(L10n.Temple.Booking.sankalpDetails)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .accessibilityAddTraits(.isHeader)

                                VStack(spacing: Cosmic.Spacing.s) {
                                    BookingTextField(
                                        title: L10n.Temple.Booking.sankalpNameTitle,
                                        text: $sankalpName,
                                        placeholder: L10n.Temple.Booking.sankalpNamePlaceholder
                                    )
                                    BookingTextField(
                                        title: L10n.Temple.Booking.sankalpGotraTitle,
                                        text: $sankalpGotra,
                                        placeholder: L10n.Temple.Booking.sankalpGotraPlaceholder
                                    )
                                    BookingTextField(
                                        title: L10n.Temple.Booking.sankalpNakshatraTitle,
                                        text: $sankalpNakshatra,
                                        placeholder: L10n.Temple.Booking.sankalpNakshatraPlaceholder
                                    )
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Special Requests
                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text(L10n.Temple.Booking.specialRequestsOptional)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .accessibilityAddTraits(.isHeader)

                                TextEditor(text: $specialRequests)
                                    .font(.cosmicBody)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(Cosmic.Spacing.s)
                                    .background(Color.cosmicSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                                    .accessibilityLabel(L10n.Temple.Booking.specialRequestsLabel)
                                    .accessibilityHint(L10n.Temple.Booking.specialRequestsHint)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Error Message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicError)
                                    .padding(.horizontal, Cosmic.Spacing.screen)
                                    .accessibilityLabel(L10n.Errors.accessibilityLabel(error))
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
                                        Text(L10n.Temple.Booking.confirmButton)
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
                            .accessibilityLabel(L10n.Temple.Booking.confirmBookingLabel)
                            .accessibilityHint(L10n.Temple.Booking.confirmBookingHint)
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            Spacer().frame(height: 40)
                        }
                        .padding(.top, Cosmic.Spacing.md)
                    }
                } else {
                    VStack {
                        Spacer()
                        AuthRequiredView(
                            title: L10n.Temple.Booking.signInTitle,
                            message: L10n.Temple.Booking.signInMessage
                        )
                        Spacer()
                    }
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.Temple.Booking.bookPoojaTitle)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .accessibleIconButton()
                    .accessibilityLabel(L10n.Actions.close)
                }
            }
        }
        .alert(L10n.Temple.Booking.bookingConfirmedTitle, isPresented: $showSuccess) {
            Button(L10n.Actions.ok) { dismiss() }
        } message: {
            if let response = bookingResponse {
                Text(L10n.Temple.Booking.bookingConfirmedMessage(
                    date: response.scheduledDate,
                    time: response.scheduledTime
                ))
            }
        }
        .fullScreenCover(isPresented: $showingVideoSession, content: videoSessionCover)
    }

    @ViewBuilder
    private func videoSessionCover() -> some View {
        let userName = authState.profileManager.profile.fullName
        VideoSessionWebView(
            sessionId: videoSessionId,
            userName: userName
        )
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
                    errorMessage = L10n.Temple.Errors.signInPooja
                case .offline:
                    errorMessage = L10n.Errors.noInternet
                case .timeout:
                    errorMessage = L10n.Errors.timeout
                case .serverError(let code, _):
                    errorMessage = L10n.Errors.serverError(code)
                default:
                    errorMessage = L10n.Temple.Errors.bookingFailed
                }
            } else {
                errorMessage = L10n.Temple.Errors.bookingFailed
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

    /// Extract session ID from session link URL
    /// Example: "https://astronova.app/api/v1/temple/session/abc-123" -> "abc-123"
    private func extractSessionId(from sessionLink: String) -> String? {
        guard let url = URL(string: sessionLink) else { return nil }
        let pathComponents = url.pathComponents
        // Session ID is the last path component
        return pathComponents.last
    }

    /// Open video session with given session ID
    private func openVideoSession(sessionId: String) {
        videoSessionId = sessionId
        showingVideoSession = true
    }
}

// MARK: - Consultation Booking Sheet

struct ConsultationBookingSheet: View {
    let astrologer: Astrologer
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authState: AuthState

    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var selectedTimeSlot: String = "10:00"
    @State private var topic: String = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var bookingResponse: PoojaBookingResponse?
    @State private var consultationType: PoojaType?
    @State private var isLoadingConsultationType = false
    @State private var availableTimeSlots: [String] = []
    @State private var isLoadingAvailability = false
    @State private var availabilityError: String?

    private let fallbackTimeSlots = ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00", "18:00", "19:00"]

    private var displayedTimeSlots: [String] {
        astrologer.apiPanditId == nil ? fallbackTimeSlots : availableTimeSlots
    }

    private var durationMinutes: Int {
        consultationType?.durationMinutes ?? 30
    }

    private var totalPrice: Int {
        consultationType?.basePrice ?? (durationMinutes * astrologer.pricePerMinute)
    }

    private var canBook: Bool {
        if astrologer.apiPanditId != nil {
            return !isLoading && !isLoadingAvailability && availabilityError == nil && !selectedTimeSlot.isEmpty
        }
        return !isLoading && !selectedTimeSlot.isEmpty
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
                                    Text(L10n.Temple.Astrologers.pricePerMinute("₹\(astrologer.pricePerMinute)"))
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
                                Text(L10n.Temple.Consultation.selectDate)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)

                                DatePicker(
                                    L10n.Temple.Booking.dateLabel,
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(Color.cosmicGold)
                                .accessibilityLabel(L10n.Temple.Consultation.consultationDateLabel)
                                .accessibilityHint(L10n.Temple.Consultation.consultationDateHint)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text(L10n.Temple.Consultation.selectTime)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)

                                if isLoadingAvailability {
                                    HStack(spacing: Cosmic.Spacing.xs) {
                                        ProgressView()
                                            .tint(Color.cosmicGold)
                                        Text("Loading availability…")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                    }
                                    .padding(.vertical, Cosmic.Spacing.xs)
                                }

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Cosmic.Spacing.s) {
                                    ForEach(displayedTimeSlots, id: \.self) { slot in
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
                                        .accessibleTouchTarget()
                                        .accessibilityLabel(L10n.Temple.Booking.timeSlotLabel(slot))
                                        .accessibilityHint(L10n.Temple.Booking.timeSlotHint)
                                        .accessibilityAddTraits(selectedTimeSlot == slot ? [.isSelected] : [])
                                    }
                                }

                                if let availabilityError {
                                    HStack(spacing: Cosmic.Spacing.xs) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicCopper)
                                        Text(availabilityError)
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicTextSecondary)
                                    }
                                    .padding(.vertical, Cosmic.Spacing.xs)
                                } else if astrologer.apiPanditId != nil && !isLoadingAvailability && availableTimeSlots.isEmpty {
                                    Text("No slots available for this date.")
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                        .padding(.vertical, Cosmic.Spacing.xs)
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text(L10n.Temple.Consultation.duration)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .accessibilityAddTraits(.isHeader)

                                HStack(spacing: Cosmic.Spacing.s) {
                                    Text(L10n.Temple.Consultation.minutes(durationMinutes))
                                        .font(.cosmicCalloutEmphasis)
                                        .foregroundStyle(Color.cosmicTextPrimary)
                                    Spacer()
                                    if isLoadingConsultationType {
                                        ProgressView()
                                            .tint(Color.cosmicGold)
                                    }
                                }
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                                Text(L10n.Temple.Consultation.topicOptional)
                                    .font(.cosmicCaptionEmphasis)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .accessibilityAddTraits(.isHeader)

                                TextEditor(text: $topic)
                                    .font(.cosmicBody)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(Cosmic.Spacing.s)
                                    .background(Color.cosmicSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
                                    .accessibilityLabel(L10n.Temple.Consultation.consultationTopicLabel)
                                    .accessibilityHint(L10n.Temple.Consultation.consultationTopicHint)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            // Payment Notice
                            VStack(spacing: Cosmic.Spacing.xs) {
                                HStack {
                                    Text(L10n.Temple.Consultation.total)
                                        .font(.cosmicCalloutEmphasis)
                                        .foregroundStyle(Color.cosmicTextSecondary)
                                    Spacer()
                                    Text("₹\(totalPrice)")
                                        .font(.cosmicHeadline)
                                        .foregroundStyle(Color.cosmicGold)
                                }

                                Text("Session link appears after your booking is confirmed.")
                                    .font(.cosmicMicro)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicError)
                                    .padding(.horizontal, Cosmic.Spacing.screen)
                                    .accessibilityLabel(L10n.Errors.accessibilityLabel(error))
                            }

                            Button {
                                Task { await bookConsultation() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(Color.cosmicVoid)
                                    } else {
                                        Image(systemName: "calendar.badge.checkmark")
                                        Text(L10n.Temple.Consultation.bookConsultation)
                                    }
                                }
                                .font(.cosmicHeadline)
                                .foregroundStyle(Color.cosmicVoid)
                                .frame(maxWidth: .infinity)
                                .frame(height: Cosmic.ButtonHeight.large)
                                .background(LinearGradient.cosmicAntiqueGold)
                                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.prominent))
                            }
                            .disabled(!canBook)
                            .accessibilityLabel(L10n.Temple.Consultation.bookConsultationLabel)
                            .accessibilityHint(L10n.Temple.Consultation.bookConsultationHint)
                            .padding(.horizontal, Cosmic.Spacing.screen)

                            Spacer().frame(height: 40)
                        }
                        .padding(.top, Cosmic.Spacing.md)
                    }
                } else {
                    VStack {
                        Spacer()
                        AuthRequiredView(
                            title: L10n.Temple.Consultation.signInTitle,
                            message: L10n.Temple.Consultation.signInMessage
                        )
                        Spacer()
                    }
                }
            }
            .background(Color.cosmicVoid)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.Temple.Consultation.navTitle)
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.cosmicTitle3)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .accessibleIconButton()
                    .accessibilityLabel(L10n.Actions.close)
                }
            }
        }
        .alert(L10n.Temple.Consultation.bookedTitle, isPresented: $showSuccess) {
            Button(L10n.Actions.ok) { dismiss() }
        } message: {
            let message = L10n.Temple.Consultation.bookedMessage(
                date: formattedDate(selectedDate),
                time: selectedTimeSlot
            )
            if let response = bookingResponse {
                Text("\(message)\n\nBooking ID: \(response.bookingId)")
            } else {
                Text(message)
            }
        }
        .task {
            await loadConsultationType()
            await loadAvailability()
        }
        .onChange(of: selectedDate) { _, _ in
            Task { await loadAvailability() }
        }
    }

    private func bookConsultation() async {
        guard !selectedTimeSlot.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIServices.shared.createPoojaBooking(
                poojaTypeId: "pooja_consultation",
                panditId: astrologer.apiPanditId,
                scheduledDate: selectedDate,
                scheduledTime: selectedTimeSlot,
                timezone: TimeZone.current.identifier,
                sankalpName: authState.profileManager.profile.fullName.isEmpty ? nil : authState.profileManager.profile.fullName,
                sankalpGotra: nil,
                sankalpNakshatra: nil,
                specialRequests: topic.isEmpty ? nil : topic
            )

            bookingResponse = response
            showSuccess = true
            CosmicHaptics.success()
        } catch {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .authenticationFailed, .tokenExpired:
                    errorMessage = L10n.Temple.Errors.signInConsultation
                case .offline:
                    errorMessage = L10n.Errors.noInternet
                case .timeout:
                    errorMessage = L10n.Errors.timeout
                case .serverError(let code, _):
                    errorMessage = L10n.Errors.serverError(code)
                default:
                    errorMessage = L10n.Temple.Errors.consultationFailed
                }
            } else {
                errorMessage = L10n.Temple.Errors.consultationFailed
            }
            CosmicHaptics.error()
        }

        isLoading = false
    }

    private func formattedDate(_ date: Date) -> String {
        LocaleFormatter.shared.mediumDate.string(from: date)
    }

    @MainActor
    private func loadConsultationType() async {
        guard !isLoadingConsultationType, consultationType == nil else { return }
        isLoadingConsultationType = true
        defer { isLoadingConsultationType = false }

        do {
            consultationType = try await APIServices.shared.getPoojaType(poojaId: "pooja_consultation")
        } catch {
            // Non-blocking: keep UI functional with local fallback pricing/duration.
        }
    }

    @MainActor
    private func loadAvailability() async {
        guard let panditId = astrologer.apiPanditId else {
            availableTimeSlots = []
            availabilityError = nil
            return
        }
        guard !isLoadingAvailability else { return }

        isLoadingAvailability = true
        availabilityError = nil
        defer { isLoadingAvailability = false }

        do {
            let slots = try await APIServices.shared.getPanditAvailability(panditId: panditId, date: selectedDate)
            let times = slots.filter(\.available).map(\.time).sorted()
            availableTimeSlots = times
            if !times.contains(selectedTimeSlot) {
                selectedTimeSlot = times.first ?? ""
            }
        } catch {
            availableTimeSlots = []
            selectedTimeSlot = ""
            if let networkError = error as? NetworkError {
                switch networkError {
                case .offline:
                    availabilityError = L10n.Errors.noInternet
                case .timeout:
                    availabilityError = L10n.Errors.timeout
                default:
                    availabilityError = L10n.Errors.generic
                }
            } else {
                availabilityError = L10n.Errors.generic
            }
        }
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
                .accessibilityLabel(title)
                .accessibilityHint(placeholder)
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
                    .accessibilityHidden(true)

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
            .frame(minHeight: Cosmic.TouchTarget.minimum)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ingredient.name), \(ingredient.quantity)")
        .accessibilityValue(isChecked ? L10n.Temple.Accessibility.checked : L10n.Temple.Accessibility.unchecked)
        .accessibilityHint(L10n.Temple.Accessibility.toggleHint)
    }
}

// MARK: - Preview

#Preview {
    TempleView()
        .environmentObject(AuthState())
}
