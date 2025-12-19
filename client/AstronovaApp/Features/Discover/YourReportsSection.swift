import SwiftUI

/// Section showing user's purchased/generated reports
struct YourReportsSection: View {
    let reports: [DetailedReport]
    let onReportTap: ((DetailedReport) -> Void)?
    let onViewAllTap: (() -> Void)?

    var body: some View {
        if reports.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your Reports")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text("\(reports.count) report\(reports.count == 1 ? "" : "s") ready")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    Spacer()

                    if reports.count > 3 {
                        Button {
                            CosmicHaptics.light()
                            onViewAllTap?()
                        } label: {
                            HStack(spacing: 4) {
                                Text("View all")
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicGold)
                        }
                    }
                }

                // Reports list (show max 3)
                VStack(spacing: Cosmic.Spacing.xs) {
                    ForEach(reports.prefix(3), id: \.reportId) { report in
                        YourReportCard(report: report) {
                            onReportTap?(report)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Your Report Card

private struct YourReportCard: View {
    let report: DetailedReport
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            CosmicHaptics.light()
            onTap()
        }) {
            HStack(spacing: Cosmic.Spacing.m) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(reportColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: reportIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(reportColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.cosmicCallout)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Status badge
                        statusBadge

                        // Date
                        if let dateStr = report.generatedAt {
                            Text(formatDate(dateStr))
                                .font(.system(size: 10))
                                .foregroundStyle(Color.cosmicTextSecondary)
                        }
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: Cosmic.Spacing.s) {
                    if report.downloadUrl != nil {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.cosmicGold)
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
                    .stroke(Color.cosmicGold.opacity(0.1), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var reportColor: Color {
        switch report.type.lowercased() {
        case "love_forecast": return .planetVenus
        case "career_forecast": return .planetSaturn
        case "birth_chart": return .cosmicGold
        case "year_ahead": return .planetJupiter
        case "transit_report": return .planetMercury
        default: return .cosmicGold
        }
    }

    private var reportIcon: String {
        switch report.type.lowercased() {
        case "love_forecast": return "heart.fill"
        case "career_forecast": return "briefcase.fill"
        case "birth_chart": return "sparkles"
        case "year_ahead": return "calendar"
        case "transit_report": return "arrow.triangle.swap"
        default: return "doc.text.fill"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let status = report.status?.lowercased() ?? "completed"

        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 6, height: 6)

            Text(status.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(statusColor(for: status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(statusColor(for: status).opacity(0.1))
        .clipShape(Capsule())
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "completed": return .green
        case "processing", "generating": return .orange
        case "failed": return .red
        default: return .cosmicTextSecondary
        }
    }

    private func formatDate(_ dateString: String) -> String {
        // Try ISO8601 format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: dateString) {
            return relativeDate(date)
        }

        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return relativeDate(date)
        }

        return dateString
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        YourReportsSection(
            reports: [
                DetailedReport(
                    reportId: "1",
                    type: "birth_chart",
                    title: "Your Birth Chart Reading",
                    content: "Full analysis...",
                    summary: "A comprehensive look at your natal chart.",
                    keyInsights: ["Sun in Leo", "Moon in Pisces"],
                    downloadUrl: "/api/v1/reports/1/pdf",
                    generatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
                    userId: "user1",
                    status: "completed"
                ),
                DetailedReport(
                    reportId: "2",
                    type: "love_forecast",
                    title: "2025 Love Forecast",
                    content: "Your romantic year...",
                    summary: "Romantic outlook for the year ahead.",
                    keyInsights: ["Venus transit", "Jupiter blessing"],
                    downloadUrl: "/api/v1/reports/2/pdf",
                    generatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-172800)),
                    userId: "user1",
                    status: "completed"
                ),
                DetailedReport(
                    reportId: "3",
                    type: "career_forecast",
                    title: "Career Forecast",
                    content: "Professional trajectory...",
                    summary: nil,
                    keyInsights: nil,
                    downloadUrl: nil,
                    generatedAt: ISO8601DateFormatter().string(from: Date()),
                    userId: "user1",
                    status: "processing"
                )
            ],
            onReportTap: { report in
                #if DEBUG
                debugPrint("[YourReportsSection] Tapped report: \(report.title)")
                #endif
            },
            onViewAllTap: {
                #if DEBUG
                debugPrint("[YourReportsSection] View all reports")
                #endif
            }
        )
        .padding()
    }
    .background(Color.cosmicBackground)
}
