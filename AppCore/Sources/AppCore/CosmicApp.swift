import SwiftUI
import AuthKit

@main
public struct CosmicApp: App {
    @StateObject private var auth = AuthManager()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
        }
    }
}
