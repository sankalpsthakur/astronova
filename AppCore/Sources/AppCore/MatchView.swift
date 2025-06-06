import SwiftUI
import CoreLocation
import DataModels
import AstroEngine
import CloudKit
import CloudKitKit


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
                            Task { 
                                try? await repo.save(score)
                                await repo.refresh()
                            }
                        }
                    }
                }
                
                if !repo.matches.isEmpty {
                    Section(header: Text("Saved Matches")) {
                        ForEach(repo.matches, id: \.createdAt) { match in
                            SavedMatchRow(match: match) {
                                Task {
                                    if let recordID = match.recordID {
                                        try? await repo.delete(id: recordID)
                                        await repo.refresh()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Match")
            .task {
                await repo.refresh()
            }
        }
    }

    private func compute() {
        Task {
            do {
                // Get user's profile for real birth data
                let recordID = try await CKContainer.cosmic.fetchUserRecordID()
                let profile: UserProfile = try await CKDatabaseProxy.private.fetch(type: UserProfile.self, id: recordID)
                
                let me = BirthData(date: profile.birthDate,
                                   time: profile.birthTime,
                                   location: profile.birthPlace)
                let partner = BirthData(date: partnerDOB,
                                        time: nil,
                                        location: profile.birthPlace) // Use same location as user for simplicity
                
                await MainActor.run {
                    score = MatchService().compare(myData: me,
                                                   partnerData: partner,
                                                   partnerName: partnerName)
                }
            } catch {
                print("[MatchView] Failed to load profile: \(error)")
            }
        }
    }
}

struct SavedMatchRow: View {
    let match: KundaliMatch
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.partnerName)
                    .font(.headline)
                Text(formatDate(match.partnerDOB))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Score: \(match.scoreTotal)/36")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

