import SwiftUI

/// Context-aware report suggestions based on current cosmic state
struct ContextAwareReportCTAs: View {
    let domainWeights: DomainWeights?
    let energyState: EnergyState?
    let hasSubscription: Bool
    let onReportTap: ((String) -> Void)?
    let onExploreAllTap: (() -> Void)?

    private var suggestedReports: [SuggestedReport] {
        guard let weights = domainWeights else {
            return defaultReports
        }

        // Sort domains by weight to prioritize suggestions
        let sortedDomains: [(String, Double)] = [
            ("self", weights.`self`),
            ("love", weights.love),
            ("work", weights.work),
            ("mind", weights.mind)
        ].sorted { $0.1 > $1.1 }

        // Map to report suggestions
        return sortedDomains.prefix(3).compactMap { domain, weight in
            reportFor(domain: domain, weight: weight)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deepen Your Understanding")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("Reports attuned to today's frequency")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Button {
                    CosmicHaptics.light()
                    onExploreAllTap?()
                } label: {
                    HStack(spacing: 4) {
                        Text("All reports")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
                }
            }

            // Suggested reports
            VStack(spacing: Cosmic.Spacing.s) {
                ForEach(suggestedReports) { report in
                    SuggestedReportCard(
                        report: report,
                        hasSubscription: hasSubscription
                    ) {
                        onReportTap?(report.type)
                    }
                }
            }
        }
    }

    // MARK: - Report Mapping

    private func reportFor(domain: String, weight: Double) -> SuggestedReport {
        switch domain {
        case "love":
            return SuggestedReport(
                type: "love_forecast",
                title: "Love Forecast",
                subtitle: "Romantic timing & compatibility",
                reason: "Love frequency elevated (\(Int(weight * 100))%)",
                icon: "heart.fill",
                color: .planetVenus,
                productId: "report_love"
            )
        case "work":
            return SuggestedReport(
                type: "career_forecast",
                title: "Career Forecast",
                subtitle: "Professional trajectory & timing",
                reason: "Work frequency is strong (\(Int(weight * 100))%)",
                icon: "briefcase.fill",
                color: .planetSaturn,
                productId: "report_career"
            )
        case "mind":
            return SuggestedReport(
                type: "transit_report",
                title: "Transit Analysis",
                subtitle: "Current planetary influences",
                reason: "Mental frequency heightened (\(Int(weight * 100))%)",
                icon: "brain.head.profile",
                color: .planetMercury,
                productId: nil  // No matching product, uses fallback
            )
        case "self":
            return SuggestedReport(
                type: "birth_chart",
                title: "Birth Chart Reading",
                subtitle: "Your cosmic blueprint",
                reason: "Self-attunement in focus (\(Int(weight * 100))%)",
                icon: "sparkles",
                color: .cosmicGold,
                productId: "report_general"
            )
        default:
            return SuggestedReport(
                type: "year_ahead",
                title: "Year Ahead",
                subtitle: "12-month cosmic roadmap",
                reason: "Plan your journey",
                icon: "calendar",
                color: .cosmicGold,
                productId: nil  // No matching product, uses fallback
            )
        }
    }

    private var defaultReports: [SuggestedReport] {
        [
            SuggestedReport(
                type: "birth_chart",
                title: "Birth Chart Reading",
                subtitle: "Your cosmic blueprint",
                reason: "Essential foundation",
                icon: "sparkles",
                color: .cosmicGold,
                productId: "report_general"
            ),
            SuggestedReport(
                type: "year_ahead",
                title: "Year Ahead",
                subtitle: "12-month cosmic roadmap",
                reason: "Plan your journey",
                icon: "calendar",
                color: .planetJupiter,
                productId: nil  // No matching product, uses fallback
            ),
            SuggestedReport(
                type: "love_forecast",
                title: "Love Forecast",
                subtitle: "Romantic timing & compatibility",
                reason: "Understand relationship patterns",
                icon: "heart.fill",
                color: .planetVenus,
                productId: "report_love"
            )
        ]
    }
}

// MARK: - Suggested Report Model

struct SuggestedReport: Identifiable {
    var id: String { type }
    let type: String
    let title: String
    let subtitle: String
    let reason: String
    let icon: String
    let color: Color
    let productId: String?

    /// Price from StoreKit (via ShopCatalog), falling back to estimate
    var price: String {
        if let productId = productId {
            return ShopCatalog.price(for: productId)
        }
        return "$14.99"  // Fallback for unmapped reports
    }
}

// MARK: - Suggested Report Card

private struct SuggestedReportCard: View {
    let report: SuggestedReport
    let hasSubscription: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            CosmicHaptics.medium()
            onTap()
        }) {
            HStack(spacing: Cosmic.Spacing.m) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(report.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: report.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(report.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.cosmicCallout)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(report.subtitle)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    // Reason tag
                    HStack(spacing: 4) {
                        Circle()
                            .fill(report.color)
                            .frame(width: 4, height: 4)

                        Text(report.reason)
                            .font(.cosmicMicro)
                            .foregroundStyle(report.color)
                    }
                }

                Spacer()

                // Price / CTA
                VStack(alignment: .trailing, spacing: 4) {
                    if hasSubscription {
                        Text("Included")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicSuccess)
                    } else {
                        Text(report.price)
                            .font(.cosmicCaption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
            .padding(Cosmic.Spacing.m)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(report.color.opacity(0.2), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        ContextAwareReportCTAs(
            domainWeights: DomainWeights(
                self: 0.2,
                love: 0.35,
                work: 0.3,
                mind: 0.15
            ),
            energyState: EnergyState(
                id: "flowing",
                label: "Flowing",
                description: "Smooth progress",
                icon: "wind"
            ),
            hasSubscription: false,
            onReportTap: { type in
                #if DEBUG
                debugPrint("[ContextAwareReportCTAs] Tapped report: \(type)")
                #endif
            },
            onExploreAllTap: {
                #if DEBUG
                debugPrint("[ContextAwareReportCTAs] Explore all")
                #endif
            }
        )
        .padding()
    }
    .background(Color.cosmicBackground)
}
