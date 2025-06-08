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
                .onAppear {
                    // Initialize API connectivity check on app launch
                    Task {
                        await authState.checkAPIConnectivity()
                    }
                }
        }
    }
}
