import Foundation

/// Builds Lo Shu magic square based on birth data.
public final class LoShuCalc {
    public init() {}

    /// Generates a 3x3 Lo Shu square based on birth date.
    public func square(for date: Date) -> [[Int]] {
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let string = String(format: "%04d%02d%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        var counts = Array(repeating: 0, count: 9)
        for ch in string {
            if let v = ch.wholeNumberValue, v > 0 {
                counts[v-1] += 1
            }
        }
        return [
            [counts[0], counts[1], counts[2]],
            [counts[3], counts[4], counts[5]],
            [counts[6], counts[7], counts[8]],
        ]
    }
}