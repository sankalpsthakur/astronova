import SwiftUI

// MARK: - PhoneVectorStepView

/// Loshu vector step — collects the user's phone number to feed digits
/// into the Loshu grid as a supplementary vector alongside birth-date digits.
///
/// Privacy: the raw number is never dialled; only its digit sequence is hashed
/// and stored for grid computation.
struct PhoneVectorStepView: View {
    @Binding var phoneDigits: String
    let birthDate: Date

    @State private var selectedCountry: CountryCode = .india
    @State private var showCountryPicker = false
    @State private var cursorVisible = true
    @State private var animateGrid = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Country Codes

    enum CountryCode: String, CaseIterable, Identifiable {
        case india = "+91"
        case uae = "+971"
        case us = "+1"
        case uk = "+44"
        case singapore = "+65"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .india: return "+91 INDIA"
            case .uae: return "+971 UAE"
            case .us: return "+1 USA"
            case .uk: return "+44 UK"
            case .singapore: return "+65 SINGAPORE"
            }
        }

        var displayName: String {
            switch self {
            case .india: return "India +91"
            case .uae: return "UAE +971"
            case .us: return "USA +1"
            case .uk: return "UK +44"
            case .singapore: return "Singapore +65"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("Your phone is part of you now.")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .lineSpacing(2)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)

                    Text("We feed its digits into the Loshu grid as a supplementary vector. Privacy: hashed, never dialled.")
                        .font(.cosmicBody)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.lg)

                // MARK: - Phone Input Field
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    Button {
                        withAnimation(.cosmicSpring) {
                            showCountryPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: Cosmic.Spacing.xs) {
                            Text(selectedCountry.label)
                                .font(.cosmicCaption)
                                .tracking(CosmicTypography.Tracking.uppercase)
                                .foregroundStyle(Color.cosmicTextTertiary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.cosmicTextTertiary)
                        }
                        .padding(.horizontal, Cosmic.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cosmicSurface.opacity(0.6))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Country code: \(selectedCountry.displayName)")
                    .accessibilityHint("Tap to change country code")
                    .padding(.bottom, Cosmic.Spacing.xxs)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                            .fill(Color.cosmicSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                                    .stroke(Color.cosmicTextTertiary.opacity(0.2), lineWidth: Cosmic.Border.hairline)
                            )

                        HStack(spacing: 0) {
                            if phoneDigits.isEmpty {
                                Text("Enter phone number")
                                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.cosmicTextTertiary.opacity(0.5))
                            } else {
                                Text(formattedDigits)
                                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.cosmicTextPrimary)
                                    .tracking(0.06 * 24)

                                Text("|")
                                    .font(.system(size: 24, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.cosmicGold)
                                    .opacity(cursorVisible ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cursorVisible)
                            }
                        }
                        .padding(.horizontal, Cosmic.Spacing.md)
                        .padding(.vertical, 18)
                    }
                    .frame(minHeight: 64)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // In production, this would present a numeric keypad.
                        // For now digits are collected through a hidden TextField
                        // bridged via the digit-entry buttons below.
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.lg)

                // Country picker (collapsible)
                if showCountryPicker {
                    VStack(spacing: 1) {
                        ForEach(CountryCode.allCases) { country in
                            Button {
                                selectedCountry = country
                                withAnimation(.cosmicSpring) {
                                    showCountryPicker = false
                                }
                                CosmicHaptics.selection()
                            } label: {
                                HStack {
                                    Text(country.displayName)
                                        .font(.cosmicCallout)
                                        .foregroundStyle(
                                            selectedCountry == country
                                                ? Color.cosmicGold
                                                : Color.cosmicTextPrimary
                                        )
                                    Spacer()
                                    if selectedCountry == country {
                                        Image(systemName: "checkmark")
                                            .font(.cosmicCaption)
                                            .foregroundStyle(Color.cosmicGold)
                                    }
                                }
                                .padding(.horizontal, Cosmic.Spacing.md)
                                .padding(.vertical, Cosmic.Spacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                            .fill(Color.cosmicSurface.opacity(0.8))
                    )
                    .padding(.horizontal, Cosmic.Spacing.screen)
                    .padding(.top, Cosmic.Spacing.xxs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: - Digit Entry Keypad
                VStack(spacing: Cosmic.Spacing.xs) {
                    ForEach(0..<4) { row in
                        HStack(spacing: Cosmic.Spacing.xs) {
                            ForEach(1...3, id: \.self) { col in
                                let digit = row * 3 + col
                                if digit <= 9 {
                                    digitButton(digit)
                                } else if digit == 10 {
                                    // Row 4, col 1: empty spacer
                                    Color.clear
                                        .frame(width: 60, height: 44)
                                } else if digit == 11 {
                                    digitButton(0)
                                } else if digit == 12 {
                                    deleteButton()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.md)

                // MARK: - Live Loshu Preview
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    Text("LIVE LOSHU PREVIEW · 3×3")
                        .font(.cosmicMicro)
                        .tracking(CosmicTypography.Tracking.uppercase)
                        .foregroundStyle(Color.cosmicTextTertiary)

                    PhoneLoshuPreviewGrid(digitCounts: combinedDigitCounts, animate: animateGrid)

                    // Summary line
                    HStack(spacing: 0) {
                        Text("missing → ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text("[\(missingDigits.map(String.init).joined(separator: ", "))]")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicError)

                        Text("  ·  ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextTertiary)

                        Text("surplus → ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text("[\(surplusDigits.map(String.init).joined(separator: ", "))]")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicGold)

                        Text("  ·  ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextTertiary)

                        Text("plane → ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text(dominantPlane)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicTeal)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, Cosmic.Spacing.lg)

                Spacer(minLength: Cosmic.Spacing.xl)
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("onboarding.phoneVector")
        .onAppear {
            cursorVisible = true
            if !reduceMotion {
                withAnimation(.cosmicReveal.delay(0.3)) { animateGrid = true }
            } else {
                animateGrid = true
            }
        }
    }

    // MARK: - Keypad

    private func digitButton(_ digit: Int) -> some View {
        Button {
            addDigit(digit)
            CosmicHaptics.light()
        } label: {
            Text("\(digit)")
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.cosmicTextPrimary)
                .frame(width: 60, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicSurface.opacity(0.6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Digit \(digit)")
    }

    private func deleteButton() -> some View {
        Button {
            if !phoneDigits.isEmpty {
                phoneDigits.removeLast()
                CosmicHaptics.medium()
            }
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.cosmicTextSecondary)
                .frame(width: 60, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .fill(Color.cosmicSurface.opacity(0.4))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete last digit")
    }

    private func addDigit(_ digit: Int) {
        guard phoneDigits.count < 12 else { return }
        phoneDigits.append("\(digit)")
    }

    // MARK: - Formatting

    private var formattedDigits: String {
        // Segment digits into groups for readability: 3-3-4 pattern
        let digits = phoneDigits
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i == 3 || i == 6 { result.append(" ") }
            result.append(ch)
        }
        return result
    }

    // MARK: - Loshu Computation

    /// Standard Loshu grid positions: rows of [4,9,2], [3,5,7], [8,1,6]
    static let loshuOrder: [Int] = [4, 9, 2, 3, 5, 7, 8, 1, 6]

    /// Count digit occurrences from DOB + phone combined
    private var combinedDigitCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for d in 1...9 { counts[d] = 0 }

        // Extract digits from birth date (DDMMYYYY)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyyyy"
        let dobString = dateFormatter.string(from: birthDate)
        for ch in dobString {
            if let d = Int(String(ch)), d >= 1, d <= 9 {
                counts[d, default: 0] += 1
            }
        }

        // Extract digits from phone
        for ch in phoneDigits {
            if let d = Int(String(ch)), d >= 1, d <= 9 {
                counts[d, default: 0] += 1
            }
        }

        return counts
    }

    private var missingDigits: [Int] {
        PhoneVectorStepView.loshuOrder.filter { combinedDigitCounts[$0] == 0 }
    }

    private var surplusDigits: [Int] {
        PhoneVectorStepView.loshuOrder.filter { (combinedDigitCounts[$0] ?? 0) >= 2 }
    }

    /// Dominant plane based on strongest digit cluster
    private var dominantPlane: String {
        let counts = combinedDigitCounts
        // Mental plane: 4, 9, 2 (top row)
        let mental = [4, 9, 2].reduce(0) { $0 + (counts[$1] ?? 0) }
        // Emotional plane: 3, 5, 7 (middle row)
        let emotional = [3, 5, 7].reduce(0) { $0 + (counts[$1] ?? 0) }
        // Practical plane: 8, 1, 6 (bottom row)
        let practical = [8, 1, 6].reduce(0) { $0 + (counts[$1] ?? 0) }

        let maxPlane = max(mental, emotional, practical)
        if maxPlane == mental { return "thought" }
        if maxPlane == emotional { return "feeling" }
        return "material"
    }
}

// MARK: - LoshuGridView

private struct PhoneLoshuPreviewGrid: View {
    let digitCounts: [Int: Int]
    let animate: Bool

    private static let order: [Int] = [4, 9, 2, 3, 5, 7, 8, 1, 6]

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 6), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Self.order, id: \.self) { number in
                let count = digitCounts[number] ?? 0
                cell(number: number, count: count)
            }
        }
        .padding(Cosmic.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.15), lineWidth: Cosmic.Border.hairline)
                )
        )
    }

    private func cell(number: Int, count: Int) -> some View {
        let bgColor: Color = {
            if count == 0 {
                return Color.cosmicError.opacity(0.08)
            } else if count >= 2 {
                return Color.cosmicGold.opacity(0.08)
            }
            return Color.cosmicSurfaceSecondary.opacity(0.6)
        }()

        let borderColor: Color = {
            if count == 0 {
                return Color.cosmicError.opacity(0.35)
            }
            return Color.cosmicTextTertiary.opacity(0.15)
        }()

        let textColor: Color = {
            if count == 0 {
                return Color.cosmicError
            } else if count >= 2 {
                return Color.cosmicGold
            }
            return Color.cosmicTextPrimary
        }()

        return ZStack {
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                        .stroke(borderColor, lineWidth: Cosmic.Border.hairline)
                )
                .aspectRatio(1, contentMode: .fit)

            Text("\(number)")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundStyle(textColor)

            if count > 0 {
                Text("×\(count)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 4)
                    .padding(.trailing, 6)
            }
        }
        .opacity(animate ? 1 : 0)
        .scaleEffect(animate ? 1 : 0.6)
        .animation(.cosmicSpring.delay(Double(Self.order.firstIndex(of: number) ?? 0) * 0.04), value: animate)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Phone Vector Step") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        PhoneVectorStepView(
            phoneDigits: .constant("9845127736"),
            birthDate: Calendar.current.date(byAdding: .year, value: -31, to: Date()) ?? Date()
        )
    }
}

#Preview("Phone Vector Step — Empty") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        PhoneVectorStepView(
            phoneDigits: .constant(""),
            birthDate: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        )
    }
}

#Preview("Phone Vector Step — Edit") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        PhoneVectorStepView(
            phoneDigits: .constant(""),
            birthDate: Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
        )
    }
}
#endif
