import SwiftUI

/// Horizontal strip showing top relationships with shared insights
struct ConnectionsStrip: View {
    let connections: [ConnectionCard]
    let onConnectionTap: ((ConnectionCard) -> Void)?
    let onSeeAllTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Connections")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("What's active between you")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                if !connections.isEmpty {
                    Button {
                        CosmicHaptics.light()
                        onSeeAllTap?()
                    } label: {
                        HStack(spacing: Cosmic.Spacing.xxs) {
                            Text("See all")
                            Image(systemName: "chevron.right")
                                .font(.cosmicMicro)
                        }
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicGold)
                    }
                }
            }

            if connections.isEmpty {
                emptyState
            } else {
                // Horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Cosmic.Spacing.m) {
                        ForEach(connections) { connection in
                            ConnectionCardView(connection: connection) {
                                onConnectionTap?(connection)
                            }
                        }
                    }
                    .padding(.vertical, 2) // For shadow
                }
            }
        }
    }

    private var emptyState: some View {
        Button {
            CosmicHaptics.light()
            onSeeAllTap?()
        } label: {
            HStack(spacing: Cosmic.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color.cosmicGold.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.cosmicGold)
                }

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Add your first connection")
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("See cosmic compatibility with friends & partners")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.cosmicGold)
            }
            .padding(Cosmic.Spacing.m)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.2), lineWidth: Cosmic.Border.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Connection Card Model

struct ConnectionCard: Identifiable {
    let id: String
    let name: String
    let initials: String
    let relationship: String // "partner", "friend", "family", etc.
    let sharedInsight: String
    let pulseIntensity: Double // 0-1
    let nextMarker: ConnectionMarker?
}

struct ConnectionMarker {
    let date: String
    let label: String // "peak", "challenge", "flow"
    let daysUntil: Int
}

// MARK: - Connection Card View

private struct ConnectionCardView: View {
    let connection: ConnectionCard
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                // Header with avatar and pulse
                HStack(spacing: Cosmic.Spacing.s) {
                    // Avatar with pulse
                    ZStack {
                        // Pulse ring
                        Circle()
                            .stroke(pulseColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 48, height: 48)
                            .scaleEffect(pulseScale)

                        // Avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cosmicGold.opacity(0.3), Color.cosmicGold.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(connection.initials)
                                    .font(.cosmicCallout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.cosmicTextPrimary)
                            )
                    }

                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text(connection.name)
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(connection.relationship.capitalized)
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }

                // Shared insight
                Text(connection.sharedInsight)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Next marker
                if let marker = connection.nextMarker {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Circle()
                            .fill(markerColor(for: marker.label))
                            .frame(width: 6, height: 6)

                        Text("\(marker.label.capitalized) in \(marker.daysUntil)d")
                            .font(.cosmicMicro)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
            .padding(Cosmic.Spacing.m)
            .frame(width: 180, alignment: .leading)
            .background(Color.cosmicSurface)
            .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.15), lineWidth: Cosmic.Border.hairline)
            )
            .cosmicElevation(.subtle)
        }
        .buttonStyle(.plain)
        .onAppear {
            startPulseAnimation()
        }
    }

    private var pulseColor: Color {
        if connection.pulseIntensity > 0.7 {
            return .cosmicWarning
        } else if connection.pulseIntensity > 0.4 {
            return .cosmicGold
        } else {
            return .cosmicSuccess
        }
    }

    private func markerColor(for label: String) -> Color {
        switch label.lowercased() {
        case "peak": return .cosmicSuccess
        case "challenge": return .cosmicWarning
        case "flow": return .cosmicGold
        default: return .cosmicTextSecondary
        }
    }

    private func startPulseAnimation() {
        let duration = 2.0 - connection.pulseIntensity // Higher intensity = faster pulse
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ConnectionsStrip(
            connections: [
                ConnectionCard(
                    id: "1",
                    name: "Sarah",
                    initials: "S",
                    relationship: "partner",
                    sharedInsight: "Strong emotional resonance today—good for heart-to-heart talks.",
                    pulseIntensity: 0.8,
                    nextMarker: ConnectionMarker(date: "2025-01-20", label: "peak", daysUntil: 3)
                ),
                ConnectionCard(
                    id: "2",
                    name: "Mike",
                    initials: "M",
                    relationship: "friend",
                    sharedInsight: "Creative synergy is high. Collaborate on projects.",
                    pulseIntensity: 0.5,
                    nextMarker: ConnectionMarker(date: "2025-01-25", label: "challenge", daysUntil: 8)
                ),
                ConnectionCard(
                    id: "3",
                    name: "Mom",
                    initials: "L",
                    relationship: "family",
                    sharedInsight: "Gentle communication needed. Listen more than speak.",
                    pulseIntensity: 0.3,
                    nextMarker: nil
                )
            ],
            onConnectionTap: { card in
                #if DEBUG
                debugPrint("[ConnectionsStrip] Tapped: \(card.name)")
                #endif
            },
            onSeeAllTap: {
                #if DEBUG
                debugPrint("[ConnectionsStrip] See all connections")
                #endif
            }
        )
        .padding()

        Divider()

        // Empty state
        ConnectionsStrip(
            connections: [],
            onConnectionTap: nil,
            onSeeAllTap: {
                #if DEBUG
                debugPrint("[ConnectionsStrip] Add connection")
                #endif
            }
        )
        .padding()
    }
    .background(Color.cosmicBackground)
}
