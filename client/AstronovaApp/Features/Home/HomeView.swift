import SwiftUI

struct HomeView: View {
    let name: String
    @State private var mood: Double = 0.5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today for \(name)").font(.title.bold())

                HStack(spacing: 12) {
                    QuickTile(title: "Focus", color: .indigo, detail: "Best for deep work 10–1")
                    QuickTile(title: "Relationships", color: .pink, detail: "Listen more than speak")
                    QuickTile(title: "Energy", color: .orange, detail: "Peak mid-afternoon")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Check-in").font(.headline)
                    HStack {
                        Image(systemName: "face.smiling")
                        Slider(value: $mood)
                    }
                }
            }
            .padding()
        }
        .onAppear { Analytics.shared.track(.homeViewed, properties: nil) }
    }
}

private struct QuickTile: View {
    let title: String
    let color: Color
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).foregroundStyle(.white)
            Text(detail).font(.caption).foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding()
        .background(color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(name: "Alex")
    }
}
#endif

