import SwiftUI

public struct TodayShareCard: View {
    let title: String
    let focus: String
    let relationships: String
    let energy: String

    public init(title: String, focus: String, relationships: String, energy: String) {
        self.title = title
        self.focus = focus
        self.relationships = relationships
        self.energy = energy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold())
            HStack(spacing: 8) {
                tile("Focus", focus, .indigo)
                tile("Relationships", relationships, .pink)
                tile("Energy", energy, .orange)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 800, height: 400)
    }

    private func tile(_ title: String, _ detail: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(detail).font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

public struct RetrogradeShareCard: View {
    let planet: String
    let dateRange: String
    let tip: String

    public init(planet: String, dateRange: String, tip: String = "Review, don't rush. Revisit plans.") {
        self.planet = planet
        self.dateRange = dateRange
        self.tip = tip
    }

    public var body: some View {
        VStack(spacing: 14) {
            Text("\(planet) Retrograde")
                .font(.largeTitle.bold())
            Text(dateRange)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(tip)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(width: 800, height: 600)
    }
}

