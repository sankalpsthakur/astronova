import SwiftUI

/// 14-day forecast strip showing intensity markers
struct NextUpTimeline: View {
    let markers: [TimelineMarker]
    let nextShift: DiscoverNextShift?
    let onMarkerTap: ((TimelineMarker) -> Void)?
    let onTimeTravelTap: (() -> Void)?

    @State private var selectedMarker: TimelineMarker?

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Next 14 Days")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("Frequency forecast at a glance")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Button {
                    CosmicHaptics.light()
                    onTimeTravelTap?()
                } label: {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Text("Time Travel")
                        Image(systemName: "chevron.right")
                            .font(.cosmicMicro)
                    }
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
                }
            }

            // Timeline strip
            VStack(spacing: Cosmic.Spacing.xs) {
                // Markers row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(markers) { marker in
                            TimelineMarkerView(
                                marker: marker,
                                isSelected: selectedMarker?.id == marker.id,
                                isToday: isToday(marker)
                            ) {
                                CosmicHaptics.light()
                                withAnimation(.spring(response: 0.3)) {
                                    selectedMarker = selectedMarker?.id == marker.id ? nil : marker
                                }
                                onMarkerTap?(marker)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Legend
                HStack(spacing: Cosmic.Spacing.m) {
                    legendItem(label: "Ease", color: .cosmicSuccess)
                    legendItem(label: "Effort", color: .cosmicWarning)
                    legendItem(label: "Intensity", color: .cosmicError)
                }
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextSecondary)
            }

            // Selected marker detail or next shift
            if let selected = selectedMarker {
                selectedMarkerDetail(selected)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let shift = nextShift {
                nextShiftPreview(shift)
            }
        }
    }

    // MARK: - Legend Item

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: Cosmic.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }

    // MARK: - Selected Marker Detail

    private func selectedMarkerDetail(_ marker: TimelineMarker) -> some View {
        HStack(spacing: Cosmic.Spacing.m) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text(formatDate(marker.date))
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text(descriptionFor(marker))
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Spacer()

            // Intensity visualization
            VStack(spacing: Cosmic.Spacing.xxs) {
                Text("Frequency")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)

                HStack(spacing: Cosmic.Spacing.xxs) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < intensityLevel(marker.intensity) ? colorFor(marker.label) : Color.cosmicTextSecondary.opacity(0.2))
                            .frame(width: 4, height: 8 + CGFloat(i) * 3)
                    }
                }
            }

            Button {
                CosmicHaptics.medium()
                onTimeTravelTap?()
            } label: {
                Text("Explore")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.sm)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background(Color.cosmicGold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(colorFor(marker.label).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Next Shift Preview

    private func nextShiftPreview(_ shift: DiscoverNextShift) -> some View {
        HStack(spacing: Cosmic.Spacing.m) {
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 20))
                .foregroundStyle(Color.cosmicGold)

            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text("Upcoming Shift")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)

                if let from = shift.from, let to = shift.to {
                    Text("\(from) → \(to)")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                } else if let summary = shift.summary {
                    Text(summary)
                        .font(.cosmicCallout)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Cosmic.Spacing.xxs) {
                Text("\(shift.daysUntil)")
                    .font(.cosmicTitle1)
                    .foregroundStyle(Color.cosmicGold)

                Text("days")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.2), lineWidth: Cosmic.Border.hairline)
        )
    }

    // MARK: - Helpers

    private func isToday(_ marker: TimelineMarker) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return marker.date == formatter.string(from: Date())
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMM d"
        return displayFormatter.string(from: date)
    }

    private func descriptionFor(_ marker: TimelineMarker) -> String {
        switch marker.label.lowercased() {
        case "ease": return "Smooth energy flow—good for starting new projects."
        case "effort": return "Extra focus needed—prioritize what matters most."
        case "intensity": return "High-frequency day—channel energy intentionally."
        default: return "Standard energy levels."
        }
    }

    private func colorFor(_ label: String) -> Color {
        switch label.lowercased() {
        case "ease": return .cosmicSuccess
        case "effort": return .cosmicWarning
        case "intensity": return .cosmicError
        default: return .cosmicGold
        }
    }

    private func intensityLevel(_ intensity: Double) -> Int {
        return max(1, min(5, Int(intensity * 5) + 1))
    }
}

// MARK: - Timeline Marker View

private struct TimelineMarkerView: View {
    let marker: TimelineMarker
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Cosmic.Spacing.xxs) {
                // Day label
                Text(marker.dayOfWeek.prefix(1))
                    .font(.cosmicMicro)
                    .foregroundStyle(isToday ? Color.cosmicGold : Color.cosmicTextSecondary)

                // Intensity dot
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(isSelected ? 1.0 : 0.6))
                        .frame(width: dotSize, height: dotSize)

                    if isToday {
                        Circle()
                            .stroke(Color.cosmicGold, lineWidth: 2)
                            .frame(width: dotSize + 6, height: dotSize + 6)
                    }

                    if isSelected {
                        Circle()
                            .stroke(dotColor, lineWidth: 2)
                            .frame(width: dotSize + 8, height: dotSize + 8)
                    }
                }
                .frame(width: 28, height: 28)

                // Date number
                Text(dayNumber)
                    .font(isToday ? .cosmicMicro.weight(.bold) : .cosmicMicro)
                    .foregroundStyle(isToday ? Color.cosmicTextPrimary : Color.cosmicTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var dotColor: Color {
        switch marker.label.lowercased() {
        case "ease": return .cosmicSuccess
        case "effort": return .cosmicWarning
        case "intensity": return .cosmicError
        default: return .cosmicGold
        }
    }

    private var dotSize: CGFloat {
        let base: CGFloat = 8
        return base + CGFloat(marker.intensity * 8)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: marker.date) else { return "" }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        return dayFormatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let today = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    let markers = (0..<14).map { offset -> TimelineMarker in
        let date = Calendar.current.date(byAdding: .day, value: offset, to: today)!
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        let intensity = Double.random(in: 0.2...1.0)
        let label = intensity < 0.4 ? "ease" : (intensity < 0.7 ? "effort" : "intensity")

        return TimelineMarker(
            date: formatter.string(from: date),
            dayOfWeek: dayFormatter.string(from: date),
            intensity: intensity,
            label: label
        )
    }

    return ScrollView {
        NextUpTimeline(
            markers: markers,
            nextShift: DiscoverNextShift(
                date: "2025-01-25",
                daysUntil: 8,
                level: "antardasha",
                from: "Jupiter",
                to: "Saturn",
                summary: "Saturn period begins"
            ),
            onMarkerTap: { marker in
                #if DEBUG
                debugPrint("[NextUpTimeline] Tapped marker: \(marker.date)")
                #endif
            },
            onTimeTravelTap: {
                #if DEBUG
                debugPrint("[NextUpTimeline] Open Time Travel")
                #endif
            }
        )
        .padding()
    }
    .background(Color.cosmicBackground)
}
