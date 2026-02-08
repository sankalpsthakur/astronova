//
//  MuhuratCardView.swift
//  AstronovaApp
//
//  Muhurat timing card with quality indicators
//

import SwiftUI

struct MuhuratCardView: View {
    let muhurat: Muhurat
    var compact: Bool = true

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
                .lineLimit(compact ? 2 : 4)
                .fixedSize(horizontal: false, vertical: true)

            if !compact {
                // Suitable activities
                if !muhurat.suitable.isEmpty {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text("Suitable")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicSuccess)
                        FlowLayout(spacing: Cosmic.Spacing.xxs) {
                            ForEach(muhurat.suitable, id: \.self) { item in
                                Text(item)
                                    .font(.cosmicMicro)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .padding(.horizontal, Cosmic.Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.cosmicSuccess.opacity(0.15)))
                            }
                        }
                    }
                }

                // Avoid activities
                if !muhurat.avoid.isEmpty {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text("Avoid")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicError)
                        FlowLayout(spacing: Cosmic.Spacing.xxs) {
                            ForEach(muhurat.avoid, id: \.self) { item in
                                Text(item)
                                    .font(.cosmicMicro)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .padding(.horizontal, Cosmic.Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.cosmicError.opacity(0.15)))
                            }
                        }
                    }
                }
            }
        }
        .frame(width: compact ? 160 : nil)
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
