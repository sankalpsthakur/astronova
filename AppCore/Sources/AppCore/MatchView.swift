import SwiftUI
import DataModels


/// Simple UI to pick a partner birthday and display kundali match score.
struct MatchView: View {
    @State private var partnerName: String = ""
    @State private var partnerDOB: Date = .init()
    @State private var score: KundaliMatch?
    @StateObject private var repo = SavedMatchRepository()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Partner")) {
                    TextField("Name", text: $partnerName)
                    DatePicker("Birthday", selection: $partnerDOB, displayedComponents: .date)
                }
                Section {
                    Button("Compare") { compute() }
                        .disabled(partnerName.isEmpty)
                }
                if let score = score {
                    Section(header: Text("Score")) {
                        Text("Total Points: \(score.scoreTotal)/36")
                            .font(.title3.weight(.semibold))
                        Button("Save Match") {
                            Task { try? await repo.save(score) }
                        }
                    }
                }
            }
            .navigationTitle("Match")
        }
    }

    private func compute() {
        // Stub algorithm until AstroEngine is fully wired.
        score = KundaliMatch(
            partnerName: partnerName,
            partnerDOB: partnerDOB,
            scoreTotal: Int.random(in: 18...36),
            aspectJSON: "{}",
            createdAt: Date()
        )
    }
}

