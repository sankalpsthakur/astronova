import SwiftUI
import DataModels

/// Displays a zodiac sign card with basic styling.
public struct ZodiacCard: View {
    public let sign: String

    public init(sign: String) {
        self.sign = sign
    }

    public var body: some View {
        Text(sign)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke())
    }
}