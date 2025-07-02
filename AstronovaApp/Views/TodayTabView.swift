import SwiftUI
import Foundation

struct TodayTab: View {
    @EnvironmentObject private var auth: AuthState
    @State private var showingWelcome = false
    @State private var animateWelcome = false
    @State private var planetaryPositions: [PlanetaryPosition] = []
    @State private var isLoadingHoroscope = false
    @State private var isLoadingPlanets = false
    @AppStorage("app_launch_count") private var appLaunchCount = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    welcomeSection
                    PrimaryCTASection()
                    
                    // Today's date
                    HStack {
                        Text("Today's Horoscope")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    todaysHoroscopeSection
                    
                    planetaryPositionsSection
                    
                    // Discovery CTAs
                    DiscoveryCTASection()
                    
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .refreshable {
                await refreshContent()
            }
            .navigationTitle("Today")
        }
        .onAppear {
            if shouldShowWelcome {
                showingWelcome = true
                let springAnimation = Animation.spring(response: 0.8, dampingFraction: 0.6)
                let delayedAnimation = springAnimation.delay(0.5)
                withAnimation(delayedAnimation) {
                    animateWelcome = true
                }
            }
            planetaryPositions = [] // Temporary fallback
        }
    }
    
    @ViewBuilder
    private var todaysHoroscopeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🌟")
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text("Daily Insight")
                        .font(.headline)
                    Text("Cosmic Guidance")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
            }
            
            if isLoadingHoroscope {
                HoroscopeSkeleton()
            } else {
                Text("Today brings powerful energies for transformation and growth. The planetary alignments suggest this is an excellent time for introspection and setting new intentions. Trust your intuition as you navigate the day's opportunities.")
                    .font(.body)
                    .lineSpacing(4)
                
                Divider()
                
                keyThemesSection
                
                Divider()
                
                luckyElementsSection
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var keyThemesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Themes")
                .font(.headline)
            
            HStack {
                VStack {
                    Text("💼")
                        .font(.title3)
                    Text("Career")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("❤️")
                        .font(.title3)
                    Text("Love")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("🌱")
                        .font(.title3)
                    Text("Growth")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("⚖️")
                        .font(.title3)
                    Text("Balance")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var luckyElementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Lucky Elements")
                .font(.headline)
            
            HStack {
                Label("Purple", systemImage: "circle.fill")
                    .foregroundStyle(Color.purple)
                Spacer()
                Label("7", systemImage: "star.fill")
                    .foregroundStyle(Color.yellow)
            }
            .font(.subheadline)
        }
    }
    
    @ViewBuilder
    private var planetaryPositionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Planetary Energies")
                .font(.headline)
            
            Text("Planetary data will be displayed here when available.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var shouldShowWelcome: Bool {
        appLaunchCount < 3
    }
    
    @ViewBuilder
    private var welcomeSection: some View {
        if shouldShowWelcome {
            WelcomeToTodayCard(onDismiss: {
                showingWelcome = false
            })
            .transition(AnyTransition.scale.combined(with: .opacity))
        }
    }
}

struct WelcomeToTodayCard: View {
    let onDismiss: () -> Void
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .scaleEffect(animateIcon ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Your Cosmic Journey!")
                        .font(.headline.weight(.semibold))
                    Text("Your personalized daily guidance awaits")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            
            HStack(spacing: 12) {
                Text("💫")
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Explore the app")
                        .font(.callout.weight(.medium))
                    Text("• Check daily insights below")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Find compatibility matches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("• Chat with your AI astrologer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            animateIcon = true
        }
    }
}

struct PrimaryCTASection: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CTACard(
                    title: "Check Compatibility",
                    subtitle: "With someone special",
                    icon: "heart.circle.fill",
                    color: .pink,
                    action: {
                        switchToTab(1)
                    }
                )
                
                CTACard(
                    title: "Ask the Stars",
                    subtitle: "AI guidance & insights",
                    icon: "message.circle.fill",
                    color: .blue,
                    action: {
                        switchToTab(3)
                    }
                )
            }
        }
    }
    
    private func switchToTab(_ index: Int) {
        HapticFeedbackService.shared.tabNavigation()
        NotificationCenter.default.post(name: .switchToTab, object: index)
    }
}

struct CTACard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct DiscoveryCTASection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Discover More")
                    .font(.headline)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                DiscoveryCard(
                    title: "Explore Your Birth Chart",
                    description: "Dive deep into your cosmic blueprint and personality insights",
                    icon: "circle.grid.cross.fill",
                    color: .purple,
                    action: switchToProfileCharts
                )
                
                DiscoveryCard(
                    title: "Track Planetary Transits",
                    description: "See how current cosmic events affect your daily life",
                    icon: "globe",
                    color: .green,
                    action: switchToProfileCharts
                )
                
                DiscoveryCard(
                    title: "Save Your Favorite Readings",
                    description: "Bookmark insights that resonate with you for future reference",
                    icon: "bookmark.circle.fill",
                    color: .orange,
                    action: switchToProfileBookmarks
                )
            }
        }
    }
    
    private func switchToProfileCharts() {
        HapticFeedbackService.shared.lightImpact()
        NotificationCenter.default.post(name: .switchToTab, object: 4)
        NotificationCenter.default.post(name: .switchToProfileSection, object: 1)
    }
    
    private func switchToProfileBookmarks() {
        HapticFeedbackService.shared.lightImpact()
        NotificationCenter.default.post(name: .switchToTab, object: 4)
        NotificationCenter.default.post(name: .switchToProfileSection, object: 2)
    }
    
    @MainActor
    private func refreshContent() async {
        // Show loading states
        isLoadingHoroscope = true
        isLoadingPlanets = true
        
        // Refresh auth state and API connectivity
        await auth.checkAPIConnectivity()
        
        // Simulate horoscope loading
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        isLoadingHoroscope = false
        
        // Refresh user data if available
        if auth.hasFullFunctionality {
            await auth.refreshUserData()
        }
        
        // Simulate planetary data loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isLoadingPlanets = false
        
        // Add haptic feedback
        HapticFeedbackService.shared.loadingComplete()
    }
}

struct DiscoveryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}