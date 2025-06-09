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
    @StateObject private var dependencies = DependencyContainer.shared
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .withDependencies(dependencies)
                .withCoordinator(coordinator)
                .onAppear {
                    // Initialize API connectivity check on app launch
                    Task {
                        await authState.checkAPIConnectivity()
                    }
                }
        }
    }
}
