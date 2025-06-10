//
//  AstronovaAppApp.swift
//  AstronovaApp
//
//  Created by Sankalp Thakur on 6/6/25.
//

import SwiftUI
import Intents

@main
struct AstronovaAppApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .onAppear {
                    setupAppOnLaunch()
                }
                .onContinueUserActivity("GetHoroscopeIntent") { userActivity in
                    handleSiriIntent(userActivity)
                }
                .onContinueUserActivity("CheckCompatibilityIntent") { userActivity in
                    handleSiriIntent(userActivity)
                }
                .onContinueUserActivity("com.sankalp.AstronovaApp.openApp") { userActivity in
                    handleSiriIntent(userActivity)
                }
        }
    }
    
    private func setupAppOnLaunch() {
        Task {
            // Initialize API connectivity check on app launch
            await authState.checkAPIConnectivity()
            
            // TODO: Setup Siri Shortcuts donations (requires Xcode project configuration)
            // SiriShortcutDonationManager.shared.setupShortcutsOnAppLaunch()
            
            // TODO: Register for App Intents (iOS 16+) (requires Xcode project configuration)
            // if #available(iOS 16.0, *) {
            //     App Intents are automatically registered when imported
            // }
        }
    }
    
    private func handleSiriIntent(_ userActivity: NSUserActivity) {
        // TODO: Implement Siri Intent handling (requires Xcode project configuration)
        // guard let intent = userActivity.interaction?.intent else { return }
        // 
        // switch intent {
        // case is GetHoroscopeIntent:
        //     Navigate to Today tab
        //     NotificationCenter.default.post(name: .switchToTab, object: 0)
        // 
        // case is CheckCompatibilityIntent:
        //     Navigate to Compatibility tab
        //     NotificationCenter.default.post(name: .switchToTab, object: 1)
        // 
        // case is OpenAstronovaAppIntent:
        //     App is already open, no additional action needed
        //     break
        // 
        // default:
        //     break
        // }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
}
