import SwiftUI

struct PaywallView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Astronova Pro")
                .font(.largeTitle.bold())
            Text("Unlock deeper insights, compatibility, and more.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Year-ahead reports", systemImage: "calendar.badge.plus")
                Label("Compatibility insights", systemImage: "heart.circle")
                Label("Saved profiles", systemImage: "person.2.circle")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Analytics.shared.track(.paywallShown, properties: ["variant": RemoteConfigService.shared.string(forKey: "paywall_variant", default: "A")])
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
#endif

