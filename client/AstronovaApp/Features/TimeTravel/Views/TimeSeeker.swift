import SwiftUI

// MARK: - Time Seeker
// Primary control: scrub month/year with inertia + “Now” snap.

struct TimeTravelScrubMotion: Equatable {
    let direction: CGFloat
    let speed: CGFloat
    let isScrubbing: Bool

    static let idle = TimeTravelScrubMotion(direction: 0, speed: 0, isScrubbing: false)
}

struct TimeSeeker: View {
    @Binding var selectedDate: Date
    let onDateChanged: () -> Void
    let onDragEnded: () -> Void
    let onScrubMotion: (TimeTravelScrubMotion) -> Void
    let onInsightTapped: (ScrubInsight) -> Void
    let insights: [ScrubInsight]
    let summary: String?

    @State private var isDragging = false
    @State private var dragStartDate: Date?
    @State private var lastScrubbedMonthsDelta: Int = 0
    @State private var lastHapticMonth: Int = 0
    @State private var lastHapticYear: Int = 0

    private let calendar = Calendar.current
    private let monthWidth: CGFloat = 60

    init(
        selectedDate: Binding<Date>,
        onDateChanged: @escaping () -> Void,
        onDragEnded: @escaping () -> Void,
        onScrubMotion: @escaping (TimeTravelScrubMotion) -> Void = { _ in },
        onInsightTapped: @escaping (ScrubInsight) -> Void = { _ in },
        insights: [ScrubInsight] = [],
        summary: String? = nil
    ) {
        _selectedDate = selectedDate
        self.onDateChanged = onDateChanged
        self.onDragEnded = onDragEnded
        self.onScrubMotion = onScrubMotion
        self.onInsightTapped = onInsightTapped
        self.insights = insights
        self.summary = summary
    }

    var body: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            // Main date display
            HStack {
                Button { adjustMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")

                Spacer()

                VStack(spacing: Cosmic.Spacing.xxs) {
                    Text(monthYearString)
                        .font(.cosmicTitle2)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text(relativeDescription)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.cosmicSpring, value: isDragging)

                Spacer()

                Button { adjustMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next month")
            }

            // Scrubber track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cosmicTextSecondary.opacity(0.2))
                        .frame(height: 8)

                    // “Now” marker at center
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.cosmicTextPrimary.opacity(0.35))
                        .frame(width: 2, height: 14)
                        .offset(x: geometry.size.width * 0.5 - 1)

                    // Fill from now → selected
                    let progress = progressToNow
                    let nowX = geometry.size.width * 0.5
                    let posX = geometry.size.width * progress
                    let startX = min(nowX, posX)
                    let width = max(1, abs(posX - nowX))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.cosmicGold.opacity(0.6), Color.cosmicGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width, height: 8)
                        .offset(x: startX)

                    // Thumb
                    Circle()
                        .fill(Color.cosmicTextPrimary)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: geometry.size.width * progress - 10)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(.cosmicSpring, value: isDragging)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleDrag(value.translation.width)
                        }
                        .onEnded { value in
                            handleDragEnd(velocity: value.predictedEndTranslation.width - value.translation.width)
                        }
                )
            }
            .frame(height: 24)

            // Quick actions
            HStack(spacing: Cosmic.Spacing.md) {
                ForEach([-1, 0, 1], id: \.self) { yearOffset in
                    let year = calendar.component(.year, from: Date()) + yearOffset
                    let isSelected = calendar.component(.year, from: selectedDate) == year

                    Button { jumpToYear(year) } label: {
                        Text(String(year))
                            .font(isSelected ? .cosmicCaptionEmphasis : .cosmicCaption)
                            .foregroundStyle(isSelected ? Color.cosmicTextPrimary : Color.cosmicTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? Color.cosmicGold.opacity(0.2) : Color.clear,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button { snapToNow() } label: {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Image(systemName: "clock.fill")
                            .font(.cosmicCaption)
                        Text("Now")
                            .font(.cosmicCaptionEmphasis)
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cosmicGold.opacity(0.15), in: Capsule())
                }
                .opacity(isToday ? 0.5 : 1.0)
                .disabled(isToday)
                .accessibilityLabel("Jump to today")
            }

            // Per-scrub feedback
            if !insights.isEmpty || summary != nil {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            ForEach(insights.prefix(4)) { insight in
                                Button {
                                    guard insight.element != nil else { return }
                                    CosmicHaptics.light()
                                    onInsightTapped(insight)
                                } label: {
                                    Text(insight.text)
                                        .font(.cosmicCaptionEmphasis)
                                        .foregroundStyle(feedbackForeground(for: insight.tone))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(feedbackBackground(for: insight.tone), in: Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(feedbackForeground(for: insight.tone).opacity(0.18), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(insight.element == nil)
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    if let summary {
                        Text(summary)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .transition(.opacity)
                    }
                }
                .animation(.cosmicSmooth, value: insights)
            }
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        .onAppear {
            lastHapticMonth = calendar.component(.month, from: selectedDate)
            lastHapticYear = calendar.component(.year, from: selectedDate)
        }
    }

    // MARK: - Computed

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var relativeDescription: String {
        let now = Date()
        let components = calendar.dateComponents([.month], from: now, to: selectedDate)
        guard let months = components.month else { return "" }
        if months == 0 { return "This month" }
        if months > 0 { return "\(months) month\(months == 1 ? "" : "s") from now" }
        return "\(abs(months)) month\(abs(months) == 1 ? "" : "s") ago"
    }

    private var isToday: Bool {
        calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }

    private var progressToNow: CGFloat {
        let now = Date()
        let months = calendar.dateComponents([.month], from: now, to: selectedDate).month ?? 0
        let normalized = (CGFloat(months) + 24) / 48
        return max(0, min(1, normalized))
    }

    // MARK: - Actions

    private func adjustMonth(by offset: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: offset, to: selectedDate) else { return }
        onScrubMotion(TimeTravelScrubMotion(direction: offset >= 0 ? 1 : -1, speed: 0.32, isScrubbing: true))
        emitHapticsIfBoundaryCrossed(newDate: newDate)
        withAnimation(.cosmicSpring) { selectedDate = newDate }
        onDateChanged()
        onDragEnded()
    }

    private func jumpToYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.year = year
        guard let newDate = calendar.date(from: components) else { return }
        let direction = Calendar.current.component(.year, from: newDate) >= Calendar.current.component(.year, from: selectedDate) ? 1 : -1
        onScrubMotion(TimeTravelScrubMotion(direction: CGFloat(direction), speed: 0.28, isScrubbing: true))
        emitHapticsIfBoundaryCrossed(newDate: newDate)
        withAnimation(.cosmicSpring) { selectedDate = newDate }
        onDateChanged()
        onDragEnded()
    }

    private func snapToNow() {
        CosmicHaptics.light()
        let direction = isToday ? 0 : (calendar.compare(selectedDate, to: Date(), toGranularity: .month) == .orderedAscending ? 1 : -1)
        onScrubMotion(TimeTravelScrubMotion(direction: CGFloat(direction), speed: 0.5, isScrubbing: true))
        withAnimation(.cosmicBounce) { selectedDate = Date() }
        onDateChanged()
        onDragEnded()
    }

    private func handleDrag(_ translation: CGFloat) {
        if dragStartDate == nil {
            dragStartDate = selectedDate
            lastScrubbedMonthsDelta = 0
            isDragging = true
        }

        guard let dragStartDate else { return }

        let direction: CGFloat = translation > 0 ? 1 : (translation < 0 ? -1 : 0)
        let normalized = min(1.0, abs(translation) / (monthWidth * 2.5))
        onScrubMotion(TimeTravelScrubMotion(direction: direction, speed: normalized, isScrubbing: true))

        let monthsDelta = Int(translation / monthWidth)
        guard monthsDelta != lastScrubbedMonthsDelta else { return }
        lastScrubbedMonthsDelta = monthsDelta

        guard let newDate = calendar.date(byAdding: .month, value: monthsDelta, to: dragStartDate) else { return }
        emitHapticsIfBoundaryCrossed(newDate: newDate)
        selectedDate = newDate
        onDateChanged()
    }

    private func handleDragEnd(velocity: CGFloat) {
        isDragging = false
        dragStartDate = nil
        lastScrubbedMonthsDelta = 0

        let rawInertia = velocity / (monthWidth * 2)
        let inertiaMonths = max(-8, min(8, Int(rawInertia.rounded())))

        if inertiaMonths != 0 {
            for i in 1...abs(inertiaMonths) {
                let delay = Double(i) * 0.05
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guard let newDate = calendar.date(byAdding: .month, value: inertiaMonths > 0 ? 1 : -1, to: selectedDate) else { return }
                    let remaining = CGFloat(abs(inertiaMonths) - (i - 1))
                    let intensity = min(1.0, 0.18 + remaining / 3.0)
                    onScrubMotion(TimeTravelScrubMotion(direction: inertiaMonths > 0 ? 1 : -1, speed: intensity, isScrubbing: true))
                    emitHapticsIfBoundaryCrossed(newDate: newDate)
                    withAnimation(.cosmicQuick) { selectedDate = newDate }
                    onDateChanged()
                    if i == abs(inertiaMonths) { onDragEnded() }
                }
            }
        } else {
            onDragEnded()
        }
    }

    private func emitHapticsIfBoundaryCrossed(newDate: Date) {
        let newMonth = calendar.component(.month, from: newDate)
        let newYear = calendar.component(.year, from: newDate)

        if newMonth != lastHapticMonth {
            CosmicHaptics.selection()
            lastHapticMonth = newMonth
        }
        if newYear != lastHapticYear {
            CosmicHaptics.medium()
            lastHapticYear = newYear
        }
    }

    private func feedbackForeground(for tone: ScrubInsight.Tone) -> Color {
        switch tone {
        case .supportive: return .cosmicSuccess
        case .challenging: return .cosmicError
        case .review: return .cosmicWarning
        case .neutral: return .cosmicTextSecondary
        }
    }

    private func feedbackBackground(for tone: ScrubInsight.Tone) -> Color {
        switch tone {
        case .supportive: return Color.cosmicSuccess.opacity(0.12)
        case .challenging: return Color.cosmicError.opacity(0.12)
        case .review: return Color.cosmicWarning.opacity(0.12)
        case .neutral: return Color.cosmicTextSecondary.opacity(0.12)
        }
    }
}
