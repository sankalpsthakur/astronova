import SwiftUI
import HoroscopeService

/// Displays the daily horoscope for the signed-in user's sun sign.
struct TodayView: View {
    @StateObject private var repo = HoroscopeRepository()

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Today")
        }
        .task {
            try? await repo.fetchToday()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let today = repo.today {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(today.shortText)
                        .font(.body)
                    if let extended = today.extendedText {
                        Text(extended)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        } else {
            LoadingView()
        }
    }
}
