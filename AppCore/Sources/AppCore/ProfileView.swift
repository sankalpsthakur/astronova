import SwiftUI
import AuthKit
import DataModels
import CloudKitKit
import AstroEngine

/// Calendar-based horoscope hub with free daily readings and premium content teasers.
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var selectedDate = Date()
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var bookmarkedReadings: [BookmarkedReading] = []
    @State private var selectedTab = 0
    
    private let tabs = ["Calendar", "Charts", "Bookmarks"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Text(tabs[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        CalendarHoroscopeView(
                            selectedDate: $selectedDate,
                            userProfile: userProfile,
                            onBookmark: bookmarkReading
                        )
                    case 1:
                        InteractiveChartsView(
                            selectedDate: selectedDate,
                            userProfile: userProfile
                        )
                    case 2:
                        BookmarkedReadingsView(
                            bookmarks: bookmarkedReadings,
                            onRemove: removeBookmark
                        )
                    default:
                        CalendarHoroscopeView(
                            selectedDate: $selectedDate,
                            userProfile: userProfile,
                            onBookmark: bookmarkReading
                        )
                    }
                }
            }
            .navigationTitle("Horoscope Hub")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .task {
            await loadProfile()
            await loadBookmarks()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    @MainActor
    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let recordID = try await CKContainer.cosmic.fetchUserRecordID()
            let profile: UserProfile = try await CKDatabaseProxy.private.fetch(type: UserProfile.self, id: recordID)
            userProfile = profile
        } catch {
            print("[ProfileView] Failed to load profile: \(error)")
            userProfile = nil
        }
    }
    
    @MainActor
    private func loadBookmarks() async {
        // Load bookmarked readings from CloudKit
        // Implementation would fetch saved bookmarks
        bookmarkedReadings = []
    }
    
    private func bookmarkReading(_ reading: HoroscopeReading) {
        let bookmark = BookmarkedReading(
            id: UUID(),
            date: reading.date,
            type: reading.type,
            title: reading.title,
            content: reading.content,
            createdAt: Date()
        )
        bookmarkedReadings.append(bookmark)
        // Save to CloudKit
    }
    
    private func removeBookmark(_ bookmark: BookmarkedReading) {
        bookmarkedReadings.removeAll { $0.id == bookmark.id }
        // Remove from CloudKit
    }
}

// MARK: - Calendar Horoscope View

struct CalendarHoroscopeView: View {
    @Binding var selectedDate: Date
    let userProfile: UserProfile?
    let onBookmark: (HoroscopeReading) -> Void
    
    @State private var showingMonthPicker = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Calendar Header with Month Navigation
                CalendarHeaderView(
                    selectedDate: $selectedDate,
                    showingMonthPicker: $showingMonthPicker
                )
                
                // Compact Calendar Grid
                CalendarGridView(selectedDate: $selectedDate)
                
                // Daily Synopsis (Free)
                DailySynopsisCard(
                    date: selectedDate,
                    userProfile: userProfile,
                    onBookmark: onBookmark
                )
                
                // Premium Content Teasers
                PremiumContentTeasers(date: selectedDate)
            }
            .padding()
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthPickerView(selectedDate: $selectedDate)
        }
    }
}

struct CalendarHeaderView: View {
    @Binding var selectedDate: Date
    @Binding var showingMonthPicker: Bool
    
    var body: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Button {
                showingMonthPicker = true
            } label: {
                VStack(spacing: 4) {
                    Text(DateFormatter.monthYear.string(from: selectedDate))
                        .font(.title2.weight(.semibold))
                    Text("Tap to change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Weekday headers
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(height: 30)
            }
            
            // Calendar days
            ForEach(daysInMonth, id: \.self) { date in
                CalendarDayView(
                    date: date,
                    selectedDate: $selectedDate,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    hasReading: hasHoroscopeReading(for: date)
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Find the first day of the week for the month
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date] = []
        var date = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: monthStart)!
        
        // Generate 42 days (6 weeks)
        for _ in 0..<42 {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return days
    }
    
    private func hasHoroscopeReading(for date: Date) -> Bool {
        // Only allow past or today
        return date <= Date()
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let isSelected: Bool
    let isToday: Bool
    let hasReading: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button {
            selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.callout.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(textColor)
                
                if hasReading {
                    Circle()
                        .fill(.blue)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return .blue }
        if !calendar.isDate(date, equalTo: selectedDate, toGranularity: .month) { return .secondary }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isSelected { return .blue }
        if isToday { return .blue.opacity(0.2) }
        return .clear
    }
}

struct DailySynopsisCard: View {
    let date: Date
    let userProfile: UserProfile?
    let onBookmark: (HoroscopeReading) -> Void
    
    @State private var reading: HoroscopeReading?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Synopsis")
                        .font(.headline)
                    Text(DateFormatter.fullDate.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let reading = reading {
                    Button {
                        onBookmark(reading)
                    } label: {
                        Image(systemName: "bookmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if let reading = reading {
                Text(reading.content)
                    .font(.callout)
                    .lineSpacing(4)
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.orange)
                    Text("Free daily insight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading daily synopsis...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task {
            await loadDailyReading()
        }
        .onChange(of: date) { _ in
            Task { await loadDailyReading() }
        }
    }
    
    @MainActor
    private func loadDailyReading() async {
        // Simulate loading daily reading
        try? await Task.sleep(for: .milliseconds(500))
        
        let sunSign = userProfile?.sunSign ?? "aries"
        reading = HoroscopeReading(
            id: UUID(),
            date: date,
            type: .daily,
            title: "Daily Synopsis",
            content: generateDailySynopsis(for: sunSign, date: date)
        )
    }
    
    private func generateDailySynopsis(for sunSign: String, date: Date) -> String {
        let insights = [
            "The cosmic energies today bring opportunities for personal growth and meaningful connections.",
            "Your intuition is heightened today, making it an excellent time for important decisions.",
            "Creative energy flows strongly through you today, perfect for artistic pursuits.",
            "Focus on relationships and communication today as the planets align favorably.",
            "Financial opportunities may present themselves today - stay alert to possibilities."
        ]
        return insights.randomElement() ?? insights[0]
    }
}

struct PremiumContentTeasers: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Unlock Detailed Insights")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                PremiumTeaserCard(
                    title: "Love Forecast",
                    description: "Detailed romantic insights",
                    icon: "heart.fill",
                    color: .pink,
                    price: "$2.99"
                )
                
                PremiumTeaserCard(
                    title: "Birth Chart Reading",
                    description: "Complete natal analysis",
                    icon: "circle.grid.cross.fill",
                    color: .purple,
                    price: "$9.99"
                )
                
                PremiumTeaserCard(
                    title: "Career Forecast",
                    description: "Professional guidance",
                    icon: "briefcase.fill",
                    color: .blue,
                    price: "$4.99"
                )
                
                PremiumTeaserCard(
                    title: "Year Ahead",
                    description: "12-month outlook",
                    icon: "calendar",
                    color: .green,
                    price: "$19.99"
                )
            }
        }
    }
}

struct PremiumTeaserCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let price: String
    
    var body: some View {
        Button {
            // Handle premium purchase
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Text(price)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color, in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Interactive Charts View

struct InteractiveChartsView: View {
    let selectedDate: Date
    let userProfile: UserProfile?
    
    @State private var selectedChart = 0
    
    private let chartTypes = ["Birth Chart", "Transit Chart", "Progressions"]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Chart Type Selector
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(chartTypes.indices, id: \.self) { index in
                        Text(chartTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Chart Display
                Group {
                    switch selectedChart {
                    case 0:
                        BirthChartView(userProfile: userProfile)
                    case 1:
                        TransitChartView(date: selectedDate, userProfile: userProfile)
                    case 2:
                        ProgressionChartView(date: selectedDate, userProfile: userProfile)
                    default:
                        BirthChartView(userProfile: userProfile)
                    }
                }
                
                // Chart Legend
                ChartLegendView()
            }
            .padding()
        }
    }
}

struct BirthChartView: View {
    let userProfile: UserProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Birth Chart")
                .font(.headline)
            
            // Placeholder for birth chart
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    .frame(height: 300)
                
                Text("🌟")
                    .font(.system(size: 60))
                
                Text("Interactive Birth Chart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            if userProfile == nil {
                Text("Complete your profile to view your birth chart")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct TransitChartView: View {
    let date: Date
    let userProfile: UserProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transit Chart - \(DateFormatter.shortDate.string(from: date))")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.3), lineWidth: 2)
                    .frame(height: 300)
                
                Text("🌙")
                    .font(.system(size: 60))
                
                Text("Current Transits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ProgressionChartView: View {
    let date: Date
    let userProfile: UserProfile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progressions - \(DateFormatter.shortDate.string(from: date))")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(.purple.opacity(0.3), lineWidth: 2)
                    .frame(height: 300)
                
                Text("⭐")
                    .font(.system(size: 60))
                
                Text("Secondary Progressions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ChartLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chart Legend")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LegendItem(symbol: "☉", name: "Sun", color: .orange)
                LegendItem(symbol: "☽", name: "Moon", color: .blue)
                LegendItem(symbol: "☿", name: "Mercury", color: .gray)
                LegendItem(symbol: "♀", name: "Venus", color: .pink)
                LegendItem(symbol: "♂", name: "Mars", color: .red)
                LegendItem(symbol: "♃", name: "Jupiter", color: .green)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct LegendItem: View {
    let symbol: String
    let name: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(symbol)
                .font(.title3)
                .foregroundStyle(color)
            Text(name)
                .font(.callout)
            Spacer()
        }
    }
}

// MARK: - Bookmarked Readings View

struct BookmarkedReadingsView: View {
    let bookmarks: [BookmarkedReading]
    let onRemove: (BookmarkedReading) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarked Readings",
                        systemImage: "bookmark",
                        description: Text("Bookmark your favorite horoscope readings to find them here.")
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ForEach(bookmarks) { bookmark in
                        BookmarkCard(bookmark: bookmark) {
                            onRemove(bookmark)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct BookmarkCard: View {
    let bookmark: BookmarkedReading
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.title)
                        .font(.headline)
                    Text(DateFormatter.fullDate.string(from: bookmark.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            Text(bookmark.content)
                .font(.callout)
                .lineSpacing(3)
            
            HStack {
                Text(bookmark.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.2), in: Capsule())
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text("Saved \(relativeString(from: bookmark.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private func relativeString(from date: Date) -> String {
    RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
}

// MARK: - Supporting Views and Models

struct MonthPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Month",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .onChange(of: selectedDate) { newValue in
                let comps = Calendar.current.dateComponents([.year, .month], from: newValue)
                selectedDate = Calendar.current.date(from: comps) ?? newValue
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account") {
                    Button("Sign Out", role: .destructive) {
                        Task { await auth.signOut() }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Daily Horoscope", isOn: .constant(true))
                    Toggle("Premium Content", isOn: .constant(false))
                }
                
                Section("About") {
                    Text("Astronova v1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Data Models

struct HoroscopeReading {
    let id: UUID
    let date: Date
    let type: ReadingType
    let title: String
    let content: String
}

struct BookmarkedReading: Identifiable {
    let id: UUID
    let date: Date
    let type: ReadingType
    let title: String
    let content: String
    let createdAt: Date
}

enum ReadingType {
    case daily
    case love
    case career
    case birthChart
    case yearAhead
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .love: return "Love"
        case .career: return "Career"
        case .birthChart: return "Birth Chart"
        case .yearAhead: return "Year Ahead"
        }
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
}

#if DEBUG
#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
#endif