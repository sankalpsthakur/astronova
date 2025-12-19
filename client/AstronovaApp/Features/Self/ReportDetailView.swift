import SwiftUI
import PDFKit

// MARK: - Report Detail View
// Shows a generated report with PDF rendering and share functionality

struct ReportDetailView: View {
    let report: DetailedReport
    @Environment(\.dismiss) private var dismiss

    @State private var pdfData: Data?
    @State private var isLoadingPDF = false
    @State private var pdfError: String?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicVoid.ignoresSafeArea()

                if isLoadingPDF {
                    loadingView
                } else if let error = pdfError {
                    errorView(error)
                } else if let data = pdfData {
                    pdfView(data)
                } else {
                    contentView
                }
            }
            .navigationTitle(report.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.cosmicGold)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if pdfData != nil || report.downloadUrl != nil {
                            Button {
                                CosmicHaptics.medium()
                                showingShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Color.cosmicGold)
                            }
                        }

                        if report.downloadUrl != nil && pdfData == nil {
                            Button {
                                Task { await loadPDF() }
                            } label: {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundStyle(Color.cosmicGold)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = pdfData {
                    ShareSheet(items: [data])
                }
            }
        }
        .task {
            if report.downloadUrl != nil {
                await loadPDF()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.cosmicGold)

            Text("Loading your report...")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.cosmicWarning)

            Text("Unable to load PDF")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(error)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task { await loadPDF() }
            } label: {
                Text("Try Again")
                    .font(.cosmicCallout)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cosmicGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Fallback to text content
            Button {
                pdfError = nil
            } label: {
                Text("View Text Version")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
    }

    // MARK: - PDF View

    private func pdfView(_ data: Data) -> some View {
        PDFKitView(data: data)
            .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Content View (Text fallback)

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    HStack {
                        reportTypeBadge
                        Spacer()
                        statusBadge
                    }

                    Text(report.title)
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    if let date = report.generatedAt {
                        Text("Generated \(formatDate(date))")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }

                Divider()
                    .background(Color.cosmicGold.opacity(0.2))

                // Summary
                if let summary = report.summary {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                        Text("Summary")
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicGold)

                        Text(summary)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextPrimary)
                    }
                }

                // Key Insights
                if let insights = report.keyInsights, !insights.isEmpty {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                        Text("Key Insights")
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicGold)

                        ForEach(insights, id: \.self) { insight in
                            HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                                Image(systemName: "sparkle")
                                    .font(.caption)
                                    .foregroundStyle(Color.cosmicGold)
                                    .padding(.top, 2)

                                Text(insight)
                                    .font(.cosmicBody)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                            }
                        }
                    }
                }

                Divider()
                    .background(Color.cosmicGold.opacity(0.2))

                // Full Content
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    Text("Full Report")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicGold)

                    Text(report.content)
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .lineSpacing(4)
                }

                // Bottom padding
                Color.clear.frame(height: 60)
            }
            .padding(Cosmic.Spacing.screen)
        }
    }

    // MARK: - Components

    private var reportTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: reportIcon)
                .font(.caption)
            Text(formatReportType(report.type))
                .font(.cosmicCaption)
        }
        .foregroundStyle(reportColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(reportColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusBadge: some View {
        let status = report.status?.lowercased() ?? "completed"
        return HStack(spacing: 4) {
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

    // MARK: - Helpers

    private func loadPDF() async {
        guard let urlPath = report.downloadUrl else { return }

        isLoadingPDF = true
        pdfError = nil

        do {
            let data = try await APIServices.shared.generateReportPDF(reportId: report.reportId)
            pdfData = data
        } catch {
            pdfError = error.localizedDescription
            #if DEBUG
            print("[ReportDetailView] Failed to load PDF: \(error)")
            #endif
        }

        isLoadingPDF = false
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

    private func formatReportType(_ type: String) -> String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
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
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: dateString) {
            return relativeDate(date)
        }

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

// MARK: - PDFKit View

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor(Color.cosmicVoid)

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}

// MARK: - Preview

#Preview {
    ReportDetailView(
        report: DetailedReport(
            reportId: "1",
            type: "birth_chart",
            title: "Your Complete Birth Chart Analysis",
            content: """
            Welcome to your comprehensive birth chart analysis. This report provides deep insights into your natal planetary positions and their influence on your life path.

            **Sun in Leo**
            Your Sun placement in Leo indicates a natural leadership quality and creative expression. You shine brightest when you can express your authentic self and inspire others.

            **Moon in Pisces**
            With your Moon in Pisces, you have a deeply intuitive and empathetic emotional nature. You may find yourself drawn to artistic or spiritual pursuits that allow you to channel your rich inner world.

            **Rising Sign: Virgo**
            Your Virgo Ascendant gives you an analytical and detail-oriented approach to life. Others may see you as practical, helpful, and organized.
            """,
            summary: "A comprehensive analysis of your natal chart revealing key personality traits and life themes.",
            keyInsights: [
                "Sun in Leo: Natural leadership and creative expression",
                "Moon in Pisces: Deep intuition and emotional sensitivity",
                "Virgo Rising: Practical and analytical approach"
            ],
            downloadUrl: "/api/v1/reports/1/pdf",
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            userId: "user1",
            status: "completed"
        )
    )
}
