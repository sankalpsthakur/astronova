import SwiftUI
import UserNotifications

struct HomeView: View {
    @EnvironmentObject private var auth: AuthState
    @StateObject private var vm: HomeViewModel
    @State private var mood: Double = 0.5
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var notificationAuthorized = false

    init(name: String? = nil, profileManager: UserProfileManager? = nil) {
        let pm = profileManager ?? AuthState().profileManager
        _vm = StateObject(wrappedValue: HomeViewModel(profileManager: pm))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(headerTitle).font(.title.bold())

                if let g = vm.guidance {
                    HStack(spacing: 12) {
                        QuickTile(title: "Focus", color: .indigo, detail: g.focus)
                            .onTapGesture { vm.triggerPaywallIfLocked() }
                        QuickTile(title: "Relationships", color: .pink, detail: g.relationships)
                            .onTapGesture { vm.triggerPaywallIfLocked() }
                        QuickTile(title: "Energy", color: .orange, detail: g.energy)
                            .onTapGesture { vm.triggerPaywallIfLocked() }
                    }

                    HStack {
                        Button {
                            if let img = ShareImageService.snapshot(of: shareCard(for: g)) {
                                shareImage = img; showShareSheet = true
                            }
                        } label: {
                            Label("Share Today", systemImage: "square.and.arrow.up")
                        }
                        Spacer()
                        if !notificationAuthorized {
                            Button {
                                Task { await requestDailyReminder() }
                            } label: {
                                Label("Enable reminder", systemImage: "bell")
                            }
                        }
                    }
                } else if vm.isLoading {
                    ProgressView().padding(.vertical, 40)
                } else if let error = vm.error {
                    Text(error).foregroundStyle(.secondary)
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
        .sheet(isPresented: $vm.showPaywall) { PaywallView() }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .task { await vm.load(); await refreshNotificationAuth() }
        .onAppear { Analytics.shared.track(.homeViewed, properties: nil) }
    }

    private var headerTitle: String {
        let name = auth.profileManager.profile.fullName
        return name.isEmpty ? "Today" : "Today for \(name)"
    }

    private func shareCard(for g: DailyGuidance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today for \(auth.profileManager.profile.fullName.isEmpty ? g.sign : auth.profileManager.profile.fullName)")
                .font(.headline)
            HStack(spacing: 8) {
                miniTile("Focus", g.focus, .indigo)
                miniTile("Relationships", g.relationships, .pink)
                miniTile("Energy", g.energy, .orange)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: 800, height: 400)
    }

    private func miniTile(_ title: String, _ detail: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(detail).font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func refreshNotificationAuth() async {
        let status = await NotificationService.shared.authorizationStatus()
        await MainActor.run { notificationAuthorized = (status == .authorized || status == .provisional) }
    }

    private func requestDailyReminder() async {
        let granted = await NotificationService.shared.requestAuthorization()
        if granted {
            let hour = Int(RemoteConfigService.shared.number(forKey: "daily_notification_default_hour", default: 9))
            await NotificationService.shared.scheduleDailyReminder(at: hour)
        }
        await refreshNotificationAuth()
        Analytics.shared.track(.notificationOptInPrompted, properties: ["granted": String(granted)])
        if granted { Analytics.shared.track(.notificationOptedIn, properties: nil) }
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
        HomeView()
            .environmentObject(AuthState())
    }
}
#endif
