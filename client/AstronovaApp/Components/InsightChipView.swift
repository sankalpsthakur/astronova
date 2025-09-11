import SwiftUI

struct InsightChipView: View {
    let text: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .onTapGesture { action?() }
        .accessibilityAddTraits(.isButton)
    }
}

