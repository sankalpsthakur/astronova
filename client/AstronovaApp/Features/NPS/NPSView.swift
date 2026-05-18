import SwiftUI

// MARK: - NPSView
//
// 1-question NPS sheet. 0–10 slider + optional comment field.
// Surfaced by `NPSService` after Oracle session #5 or first Cosmic Diary entry.

public struct NPSView: View {
    let trigger: NPSTrigger
    var onDismiss: () -> Void
    var onSubmit: (Int, String) -> Void

    @State private var score: Double = 8
    @State private var comment: String = ""
    @State private var submitted = false
    @Environment(\.dismiss) private var dismiss

    public init(
        trigger: NPSTrigger,
        onDismiss: @escaping () -> Void,
        onSubmit: @escaping (Int, String) -> Void
    ) {
        self.trigger = trigger
        self.onDismiss = onDismiss
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Quick question")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("How likely are you to recommend Astronova to a friend?")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("nps_question")
            }
            .padding(.horizontal)

            // Slider 0–10
            VStack(spacing: 12) {
                Text("\(Int(score))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("nps_score")

                Slider(value: $score, in: 0...10, step: 1)
                    .accessibilityIdentifier("nps_slider")
                    .padding(.horizontal)

                HStack {
                    Text("Not likely")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Very likely")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            // Optional comment
            VStack(alignment: .leading, spacing: 6) {
                Text("Anything we should know? (optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Optional comment", text: $comment, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("nps_comment")
            }
            .padding(.horizontal)

            // Submit + dismiss
            HStack(spacing: 12) {
                Button("Not now") {
                    onDismiss()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("nps_dismiss")

                Button {
                    submitted = true
                    onSubmit(Int(score), comment)
                    dismiss()
                } label: {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("nps_submit")
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top, 28)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("nps_sheet")
    }
}

#if DEBUG
#Preview("NPS sheet") {
    NPSView(
        trigger: .oracleSession5,
        onDismiss: {},
        onSubmit: { _, _ in }
    )
}
#endif
