//
//  DIYPoojaListView.swift
//  AstronovaApp
//
//  Horizontal scroll of DIY Pooja cards for Temple tab
//

import SwiftUI

struct DIYPoojaListView: View {
    let poojas: [DIYPooja]

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(L10n.Temple.DIYPooja.sectionTitle)
                        .font(.cosmicTitle3)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.Temple.DIYPooja.sectionSubtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, Cosmic.Spacing.screen)

            // Horizontal scroll of pooja cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.md) {
                    ForEach(poojas) { pooja in
                        NavigationLink(value: pooja) {
                            DIYPoojaCardView(pooja: pooja)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
        }
    }
}

// MARK: - DIY Pooja Card

struct DIYPoojaCardView: View {
    let pooja: DIYPooja

    var body: some View {
        VStack(spacing: Cosmic.Spacing.s) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cosmicGold.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: pooja.iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.cosmicGold)
            }
            .accessibilityHidden(true)

            // Name
            Text(pooja.name)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Deity
            Text(pooja.deity)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(1)

            // Duration
            HStack(spacing: Cosmic.Spacing.xxs) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text("\(pooja.durationMinutes) min")
                    .font(.cosmicMicro)
            }
            .foregroundStyle(Color.cosmicTextTertiary)
        }
        .frame(width: 130)
        .padding(.vertical, Cosmic.Spacing.md)
        .padding(.horizontal, Cosmic.Spacing.s)
        .background {
            RoundedRectangle(cornerRadius: Cosmic.Radius.prominent)
                .fill(Color.cosmicSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pooja.name) pooja for \(pooja.deity), \(pooja.durationMinutes) minutes")
        .accessibilityHint("Double tap to start this pooja guide")
    }
}
