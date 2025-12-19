import SwiftUI

// MARK: - Compatibility Journey View
// Time navigation for the relationship - not just "today", a forecast you can scrub.
// Day strip (7 days) + 30-day sparkline with peaks/troughs.

struct CompatibilityJourneyView: View {
    let journey: JourneyForecast
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void

    @State private var showFullForecast = false

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            // Day strip (7 days)
            dayStrip

            // Peak windows callout
            if let nextPeak = upcomingPeakWindow {
                peakWindowCallout(nextPeak)
            }

            // 30-day sparkline
            sparklineChart
                .frame(height: 60)

            // Expand button
            Button(action: {
                showFullForecast = true
                CosmicHaptics.light()
            }) {
                HStack {
                    Text("View 30-day forecast")
                        .font(.caption.weight(.medium))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(Color.cosmicGold.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cosmicNebula, lineWidth: 1)
                )
        )
        .sheet(isPresented: $showFullForecast) {
            FullForecastSheet(journey: journey, selectedDate: $selectedDate, onDateSelected: onDateSelected)
        }
    }

    // MARK: - Day Strip

    private var dayStrip: some View {
        HStack(spacing: 8) {
            ForEach(next7Days, id: \.self) { date in
                DayCell(
                    date: date,
                    marker: markerFor(date),
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                        onDateSelected(date)
                        CosmicHaptics.selection()
                    }
                )
            }
        }
    }

    private var next7Days: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: Date())
        }
    }

    private func markerFor(_ date: Date) -> DayMarker? {
        journey.dailyMarkers.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Peak Window Callout

    private var upcomingPeakWindow: PeakWindow? {
        journey.peakWindows.first { $0.startDate > Date() || $0.endDate > Date() }
    }

    private func peakWindowCallout(_ peak: PeakWindow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(Color.cosmicGold)

            VStack(alignment: .leading, spacing: 2) {
                Text(peak.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text(peakDateRange(peak))
                    .font(.caption2)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Spacer()

            Text(peak.suggestion)
                .font(.caption2)
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(maxWidth: 120)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cosmicGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func peakDateRange(_ peak: PeakWindow) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: peak.startDate)) - \(formatter.string(from: peak.endDate))"
    }

    // MARK: - Sparkline Chart

    private var sparklineChart: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let count = journey.dailyMarkers.count
                guard count > 1 else { return }

                let stepX = width / CGFloat(count - 1)

                // Draw gradient background for peak windows
                for peak in journey.peakWindows {
                    if let startIdx = journey.dailyMarkers.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: peak.startDate) }),
                       let endIdx = journey.dailyMarkers.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: peak.endDate) }) {
                        let startX = CGFloat(startIdx) * stepX
                        let endX = CGFloat(endIdx) * stepX
                        let rect = CGRect(x: startX, y: 0, width: endX - startX, height: height)
                        context.fill(
                            Rectangle().path(in: rect),
                            with: .color(Color.cosmicGold.opacity(0.1))
                        )
                    }
                }

                // Draw the line
                var path = Path()
                for (index, marker) in journey.dailyMarkers.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height * (1 - marker.intensity.height)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                // Line stroke
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [Color.cosmicTeal.opacity(0.5), Color.cosmicGold, Color.cosmicTeal.opacity(0.5)]),
                        startPoint: CGPoint(x: 0, y: height / 2),
                        endPoint: CGPoint(x: width, y: height / 2)
                    ),
                    lineWidth: 2
                )

                // Dots for significant days
                for (index, marker) in journey.dailyMarkers.enumerated() {
                    if marker.intensity == .peak || marker.intensity == .challenging {
                        let x = CGFloat(index) * stepX
                        let y = height * (1 - marker.intensity.height)
                        let dotSize: CGFloat = 6
                        let color: Color = marker.intensity == .peak ? .cosmicGold : Color(red: 0.95, green: 0.5, blue: 0.5)

                        context.fill(
                            Circle().path(in: CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)),
                            with: .color(color)
                        )
                    }
                }

                // Selected date indicator
                if let selectedIdx = journey.dailyMarkers.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
                    let x = CGFloat(selectedIdx) * stepX
                    let marker = journey.dailyMarkers[selectedIdx]
                    let y = height * (1 - marker.intensity.height)

                    // Vertical line
                    var vLine = Path()
                    vLine.move(to: CGPoint(x: x, y: 0))
                    vLine.addLine(to: CGPoint(x: x, y: height))
                    context.stroke(vLine, with: .color(Color.cosmicNebula), lineWidth: 1)

                    // Larger dot
                    let dotSize: CGFloat = 10
                    context.fill(
                        Circle().path(in: CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)),
                        with: .color(.white)
                    )
                }
            }
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let marker: DayMarker?
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Day name
                Text(dayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.cosmicTextTertiary)

                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.cosmicBackground : Color.cosmicTextPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.cosmicGold : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(isToday && !isSelected ? Color.cosmicGold.opacity(0.5) : Color.clear, lineWidth: 1)
                    )

                // Intensity indicator
                intensityDot
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDateLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let dateStr = formatter.string(from: date)
        let intensityStr = marker?.intensity.rawValue ?? "unknown"
        let selectedStr = isSelected ? ", selected" : ""
        let todayStr = isToday ? ", today" : ""
        return "\(dateStr)\(todayStr)\(selectedStr), \(intensityStr) energy"
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    @ViewBuilder
    private var intensityDot: some View {
        if let marker = marker {
            Circle()
                .fill(intensityColor(marker.intensity))
                .frame(width: 6, height: 6)
        } else {
            Circle()
                .fill(Color.clear)
                .frame(width: 6, height: 6)
        }
    }

    private func intensityColor(_ intensity: DayIntensity) -> Color {
        switch intensity {
        case .peak: return Color.cosmicGold
        case .elevated: return Color.cosmicTeal
        case .neutral: return Color.cosmicTextTertiary
        case .challenging: return Color(red: 0.95, green: 0.5, blue: 0.5)
        case .quiet: return Color.cosmicNebula
        }
    }
}

// MARK: - Full Forecast Sheet

struct FullForecastSheet: View {
    let journey: JourneyForecast
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Legend
                    legendView

                    // Calendar grid
                    calendarGrid

                    // Peak windows
                    if !journey.peakWindows.isEmpty {
                        peakWindowsSection
                    }
                }
                .padding()
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationTitle("30-Day Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            ForecastLegendItem(color: Color.cosmicGold, label: "Peak")
            ForecastLegendItem(color: Color.cosmicTeal, label: "Elevated")
            ForecastLegendItem(color: Color.cosmicTextTertiary, label: "Neutral")
            ForecastLegendItem(color: Color(red: 0.95, green: 0.5, blue: 0.5), label: "Challenging")
        }
        .font(.caption2)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(journey.dailyMarkers) { marker in
                CalendarDayCell(
                    marker: marker,
                    isSelected: calendar.isDate(marker.date, inSameDayAs: selectedDate),
                    onTap: {
                        selectedDate = marker.date
                        onDateSelected(marker.date)
                        CosmicHaptics.selection()
                    }
                )
            }
        }
    }

    private var peakWindowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimal Windows")
                .font(.headline)
                .foregroundStyle(Color.cosmicTextPrimary)

            ForEach(journey.peakWindows) { peak in
                PeakWindowCard(peak: peak)
            }
        }
    }
}

struct ForecastLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }
}

struct CalendarDayCell: View {
    let marker: DayMarker
    let isSelected: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: marker.date))")
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.cosmicBackground : Color.cosmicTextPrimary)

                if let reason = marker.reason {
                    Text(reason.prefix(8))
                        .font(.system(size: 6))
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.cosmicGold : intensityBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var intensityBackground: Color {
        switch marker.intensity {
        case .peak: return Color.cosmicGold.opacity(0.3)
        case .elevated: return Color.cosmicTeal.opacity(0.2)
        case .neutral: return Color.cosmicSurface
        case .challenging: return Color(red: 0.95, green: 0.5, blue: 0.5).opacity(0.2)
        case .quiet: return Color.cosmicSurface.opacity(0.5)
        }
    }
}

struct PeakWindowCard: View {
    let peak: PeakWindow

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.cosmicGold)
                    Text(peak.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                Text("\(dateFormatter.string(from: peak.startDate)) - \(dateFormatter.string(from: peak.endDate))")
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Spacer()

            Text(peak.suggestion)
                .font(.caption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cosmicGold.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        CompatibilityJourneyView(
            journey: .mock,
            selectedDate: .constant(Date()),
            onDateSelected: { _ in }
        )
        .padding()
    }
}
