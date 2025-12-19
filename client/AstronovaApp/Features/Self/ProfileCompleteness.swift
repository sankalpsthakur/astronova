import SwiftUI

// MARK: - Profile Completeness
// Progressive enhancement model - never blocking, always improving

struct ProfileCompleteness {
    let hasName: Bool
    let hasBirthDate: Bool
    let hasBirthTime: Bool
    let hasBirthPlace: Bool

    // MARK: - Computed Properties

    var level: CompletenessLevel {
        if hasBirthTime && hasBirthPlace {
            return .full
        } else if hasBirthTime || hasBirthPlace {
            return .enhanced
        } else if hasBirthDate {
            return .basic
        }
        return .minimal
    }

    var percentage: Int {
        var score = 0
        if hasName { score += 10 }
        if hasBirthDate { score += 30 }
        if hasBirthTime { score += 30 }
        if hasBirthPlace { score += 30 }
        return score
    }

    var missingItems: [MissingItem] {
        var items: [MissingItem] = []

        if !hasBirthTime {
            items.append(MissingItem(
                field: .birthTime,
                icon: "clock",
                title: "Birth Time",
                benefit: "Unlocks precise dasha timing & rising sign",
                priority: 1
            ))
        }

        if !hasBirthPlace {
            items.append(MissingItem(
                field: .birthPlace,
                icon: "location",
                title: "Birth Place",
                benefit: "Unlocks lagna, house positions & local transits",
                priority: 2
            ))
        }

        if !hasName {
            items.append(MissingItem(
                field: .name,
                icon: "person",
                title: "Name",
                benefit: "Personalize your cosmic journey",
                priority: 3
            ))
        }

        return items.sorted { $0.priority < $1.priority }
    }

    var nextUnlock: MissingItem? {
        missingItems.first
    }

    var canCalculateDasha: Bool {
        hasBirthDate // Minimum requirement
    }

    var canCalculatePreciseDasha: Bool {
        hasBirthDate && hasBirthTime
    }

    var canCalculateLagna: Bool {
        hasBirthDate && hasBirthTime && hasBirthPlace
    }

    var canCalculateTransits: Bool {
        hasBirthDate // Basic transits work with just sun sign
    }

    // MARK: - Initialization

    init(profile: UserProfile) {
        self.hasName = !profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.hasBirthDate = true // Always have a date (defaults to today)
        self.hasBirthTime = profile.birthTime != nil
        self.hasBirthPlace = profile.birthLatitude != nil && profile.birthLongitude != nil
    }
}

// MARK: - Completeness Level

enum CompletenessLevel: String, CaseIterable {
    case minimal = "Minimal"
    case basic = "Basic"
    case enhanced = "Enhanced"
    case full = "Full"

    var color: Color {
        switch self {
        case .minimal: return .cosmicTextTertiary
        case .basic: return .cosmicWarning
        case .enhanced: return .cosmicGold
        case .full: return .cosmicSuccess
        }
    }

    var icon: String {
        switch self {
        case .minimal: return "circle.dashed"
        case .basic: return "circle.bottomhalf.filled"
        case .enhanced: return "circle.inset.filled"
        case .full: return "checkmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .minimal: return "Add birth details to begin"
        case .basic: return "Basic insights available"
        case .enhanced: return "Enhanced accuracy"
        case .full: return "Maximum precision"
        }
    }
}

// MARK: - Missing Item

struct MissingItem: Identifiable {
    let id = UUID()
    let field: ProfileField
    let icon: String
    let title: String
    let benefit: String
    let priority: Int
}

enum ProfileField {
    case name
    case birthDate
    case birthTime
    case birthPlace
}

// MARK: - Completeness Badge View

struct CompletenessBadge: View {
    let completeness: ProfileCompleteness

    var body: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Image(systemName: completeness.level.icon)
                .font(.system(size: 12))
            Text(completeness.level.rawValue)
                .font(.cosmicCaption)
        }
        .foregroundStyle(completeness.level.color)
    }
}

// MARK: - Unlock Prompt View

struct UnlockPromptView: View {
    let item: MissingItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Cosmic.Spacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.cosmicGold.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: item.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.cosmicGold)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add \(item.title)")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Text(item.benefit)
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }

                Spacer()

                // Arrow
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.cosmicGold)
            }
            .padding(Cosmic.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                    .fill(Color.cosmicGold.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                            .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Accuracy Meter View

struct AccuracyMeterView: View {
    let completeness: ProfileCompleteness

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            HStack {
                Text("Chart Accuracy")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Spacer()
                Text("\(completeness.percentage)%")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(completeness.level.color)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cosmicTextTertiary.opacity(0.15))

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [completeness.level.color.opacity(0.7), completeness.level.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(completeness.percentage) / 100)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

#Preview("Profile Completeness") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        VStack(spacing: 20) {
            // Full profile
            let fullProfile = UserProfile(
                fullName: "John Doe",
                birthDate: Date(),
                birthTime: Date(),
                birthPlace: "New York",
                birthLatitude: 40.7,
                birthLongitude: -74.0,
                timezone: "America/New_York"
            )
            let fullCompleteness = ProfileCompleteness(profile: fullProfile)

            VStack(alignment: .leading) {
                Text("Full Profile").font(.cosmicHeadline).foregroundStyle(.white)
                CompletenessBadge(completeness: fullCompleteness)
                AccuracyMeterView(completeness: fullCompleteness)
            }
            .padding()
            .background(Color.cosmicStardust.opacity(0.5))
            .cornerRadius(12)

            // Partial profile
            let partialProfile = UserProfile(
                fullName: "",
                birthDate: Date(),
                birthTime: Date()
            )
            let partialCompleteness = ProfileCompleteness(profile: partialProfile)

            VStack(alignment: .leading, spacing: 12) {
                Text("Partial Profile").font(.cosmicHeadline).foregroundStyle(.white)
                CompletenessBadge(completeness: partialCompleteness)
                AccuracyMeterView(completeness: partialCompleteness)

                if let next = partialCompleteness.nextUnlock {
                    UnlockPromptView(item: next, onTap: {})
                }
            }
            .padding()
            .background(Color.cosmicStardust.opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
    }
}
