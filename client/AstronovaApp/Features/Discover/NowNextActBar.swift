import SwiftUI

/// Sticky bar showing Now (theme) / Next (countdown) / Act (action chip)
struct NowNextActBar: View {
    let theme: String
    let nextShift: DiscoverNextShift?
    let primaryAction: DiscoverAction?
    let onActionTap: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed bar
            HStack(spacing: Cosmic.Spacing.m) {
                // Now
                nowSection

                Divider()
                    .frame(height: 24)
                    .background(Color.cosmicGold.opacity(0.3))

                // Next
                nextSection

                Spacer()

                // Act chip
                if let action = primaryAction {
                    actChip(action)
                }
            }
            .padding(.horizontal, Cosmic.Spacing.m)
            .padding(.vertical, Cosmic.Spacing.s)
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .overlay(
                        LinearGradient(
                            colors: [Color.cosmicGold.opacity(0.05), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.15), lineWidth: Cosmic.Border.hairline)
            )
            .cosmicElevation(.medium)

            // Expanded details (optional)
            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
            CosmicHaptics.light()
        }
    }

    // MARK: - Now Section

    private var nowSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("NOW")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.cosmicGold)
                .tracking(1)

            Text(truncatedTheme)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineLimit(1)
        }
        .frame(minWidth: 80, alignment: .leading)
    }

    private var truncatedTheme: String {
        if theme.count > 30 {
            return String(theme.prefix(27)) + "..."
        }
        return theme
    }

    // MARK: - Next Section

    private var nextSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("NEXT")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.cosmicTextSecondary)
                .tracking(1)

            if let shift = nextShift {
                HStack(spacing: 4) {
                    Text("\(shift.daysUntil)d")
                        .font(.cosmicCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(countdownColor(for: shift.daysUntil))

                    if let summary = shift.summary {
                        Text(summary)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("—")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
        .frame(minWidth: 70, alignment: .leading)
    }

    private func countdownColor(for days: Int) -> Color {
        if days <= 3 {
            return .orange
        } else if days <= 7 {
            return .cosmicGold
        } else {
            return .cosmicTextSecondary
        }
    }

    // MARK: - Act Chip

    private func actChip(_ action: DiscoverAction) -> some View {
        Button {
            CosmicHaptics.medium()
            onActionTap?()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: action.type == "do" ? "bolt.fill" : "xmark.circle")
                    .font(.system(size: 10))

                Text(shortActionText(action.text))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(action.type == "do" ? Color.cosmicGold : Color.cosmicTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(action.type == "do" ? Color.cosmicGold.opacity(0.15) : Color.cosmicSurface)
            )
            .overlay(
                Capsule()
                    .stroke(Color.cosmicGold.opacity(0.3), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private func shortActionText(_ text: String) -> String {
        let words = text.components(separatedBy: " ")
        if words.count > 3 {
            return words.prefix(3).joined(separator: " ")
        }
        return text
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            // Full theme
            Text(theme)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineSpacing(4)

            // Next shift details
            if let shift = nextShift {
                HStack(spacing: Cosmic.Spacing.s) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.cosmicGold)

                    VStack(alignment: .leading, spacing: 2) {
                        if let from = shift.from, let to = shift.to {
                            Text("\(from) → \(to)")
                                .font(.cosmicCallout)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.cosmicTextPrimary)
                        }

                        Text("in \(shift.daysUntil) days")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
        }
        .padding(Cosmic.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
    }
}

// MARK: - Blur View Helper

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        NowNextActBar(
            theme: "Channel your natural achievement into meaningful projects.",
            nextShift: DiscoverNextShift(
                date: "2025-01-25",
                daysUntil: 6,
                level: "antardasha",
                from: "Jupiter",
                to: "Saturn",
                summary: "Saturn period begins"
            ),
            primaryAction: DiscoverAction(id: "act_1", text: "Focus on one priority", type: "do")
        ) {
            #if DEBUG
            debugPrint("[NowNextActBar] Action tapped")
            #endif
        }
        .padding()

        NowNextActBar(
            theme: "Stay grounded in your discipline to navigate the day ahead.",
            nextShift: nil,
            primaryAction: DiscoverAction(id: "act_2", text: "Reflect and journal", type: "do")
        ) {
            #if DEBUG
            debugPrint("[NowNextActBar] Action tapped")
            #endif
        }
        .padding()
    }
    .background(Color.cosmicBackground)
}
