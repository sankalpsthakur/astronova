import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    private let refreshTaskIdentifier = "com.astronova.offlineRefresh"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            if let refreshTask = task as? BGAppRefreshTask {
                self.handleRefresh(task: refreshTask)
            }
        }
        scheduleRefresh()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleRefresh()
    }

    private func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 2), matchingPolicy: .nextTime)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule offline refresh: \(error)")
        }
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        scheduleRefresh()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            await LocalDataService.shared.snapshotDailyContent()
            task.setTaskCompleted(success: true)
        }
    }
}
