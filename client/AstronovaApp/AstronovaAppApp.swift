//
//  AstronovaAppApp.swift
//  AstronovaApp
//
//  Created by Sankalp Thakur on 6/6/25.
//

import SwiftUI

@main
struct AstronovaAppApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .onAppear { Analytics.shared.track(.appLaunched, properties: nil) }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
}
