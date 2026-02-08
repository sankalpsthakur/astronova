//
//  PanchangDisplayView.swift
//  AstronovaApp
//
//  Displays Panchang data: tithi, nakshatra, yoga, karana
//

import SwiftUI

struct PanchangDisplayView: View {
    let panchang: PanchangData

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            Text(L10n.Temple.Muhurat.panchang)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Cosmic.Spacing.s) {
                    PanchangBadge(icon: "moon.fill", label: L10n.Temple.Muhurat.tithi, value: panchang.tithi)
                    PanchangBadge(icon: "star.fill", label: L10n.Temple.Muhurat.nakshatra, value: panchang.nakshatra)
                    PanchangBadge(icon: "figure.yoga", label: L10n.Temple.Muhurat.yoga, value: panchang.yoga)
                    PanchangBadge(icon: "circle.hexagonpath", label: L10n.Temple.Muhurat.karana, value: panchang.karana)
                }
            }
        }
    }
}

struct PanchangBadge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Cosmic.Spacing.xxs) {
            HStack(spacing: Cosmic.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.cosmicGold)
                Text(label)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Text(value)
                .font(.cosmicCaptionEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
        .padding(.horizontal, Cosmic.Spacing.s)
        .padding(.vertical, Cosmic.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                .fill(Color.cosmicSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
