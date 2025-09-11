import SwiftUI

struct PlanetImpactGlossaryView: View {
    var activeMahadasha: String?
    var activeAntardasha: String?
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var filtered: [PlanetImpact] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return PlanetImpacts.all }
        let q = query.lowercased()
        return PlanetImpacts.all.filter { p in
            p.name.lowercased().contains(q) ||
            p.summary.lowercased().contains(q) ||
            p.keywords.contains(where: { $0.contains(q) })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let maha = activeMahadasha {
                    Section(header: Text("Active Dasha")) {
                        HStack {
                            Text("Mahadasha")
                            Spacer()
                            Label("\(maha)", systemImage: "sparkles")
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(.primary)
                        }
                        if let antar = activeAntardasha {
                            HStack {
                                Text("Antardasha")
                                Spacer()
                                Text(antar)
                            }
                        }
                    }
                }

                Section(header: Text("Planet Impacts")) {
                    ForEach(filtered) { p in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(p.symbol).font(.title3)
                                Text(p.name)
                                    .font(.headline)
                                if p.name == activeMahadasha || p.name == activeAntardasha {
                                    Text("active")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.thinMaterial, in: Capsule())
                                }
                            }
                            Text(p.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                ForEach(p.keywords.prefix(6), id: \.self) { k in
                                    Text(k)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.12), in: Capsule())
                                }
                            }
                            if !p.strengths.isEmpty {
                                Text("Do:")
                                    .font(.caption.bold())
                                Text("• " + p.strengths.joined(separator: "  • "))
                                    .font(.caption)
                            }
                            if !p.cautions.isEmpty {
                                Text("Watch:")
                                    .font(.caption.bold())
                                Text("• " + p.cautions.joined(separator: "  • "))
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Planet Impacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

