import WidgetKit
import SwiftUI

/// Today's Horoscope Widget for home screen
struct TodaysHoroscopeWidget: Widget {
    let kind: String = "TodaysHoroscopeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodaysHoroscopeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Horoscope")
        .description("Get your daily cosmic insights right on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            horoscope: "The cosmos aligns in your favor today. Trust your intuition and embrace new opportunities.",
            keyThemes: ["Growth", "Love", "Career"],
            luckyColor: "Purple",
            luckyNumber: 7,
            moonPhase: "🌓"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            horoscope: "Today brings powerful energies for transformation and growth. The planetary alignments suggest this is an excellent time for introspection.",
            keyThemes: ["Career", "Love", "Growth", "Balance"],
            luckyColor: "Purple",
            luckyNumber: 7,
            moonPhase: "🌓"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let entries = await generateEntries()
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
    
    private func generateEntries() async -> [SimpleEntry] {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Generate entries for the next 24 hours (refreshed every 6 hours)
        for hourOffset in stride(from: 0, to: 24, by: 6) {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            
            // Try to fetch real horoscope data
            let horoscopeData = await fetchHoroscopeData()
            
            let entry = SimpleEntry(
                date: entryDate,
                horoscope: horoscopeData.horoscope,
                keyThemes: horoscopeData.keyThemes,
                luckyColor: horoscopeData.luckyColor,
                luckyNumber: horoscopeData.luckyNumber,
                moonPhase: horoscopeData.moonPhase
            )
            entries.append(entry)
        }
        
        return entries
    }
    
    private func fetchHoroscopeData() async -> HoroscopeData {
        do {
            // Try to fetch real horoscope data from shared app container
            // Note: Widgets run in separate process, so we'd need shared UserDefaults or App Groups
            let apiServices = APIServices.shared
            let horoscopeResponse = try await apiServices.getHoroscope(for: Date(), type: .daily)
            
            // Get current lunar phase from planetary data
            let lunarData = try await apiServices.getCurrentPlanetaryPositions()
            let moonData = lunarData["moon"]
            let moonPhase = calculateMoonPhase(from: moonData)
            
            // Extract themes and lucky elements from horoscope content
            let (themes, color, number) = extractLuckyElements(from: horoscopeResponse.content)
            
            return HoroscopeData(
                horoscope: horoscopeResponse.content,
                keyThemes: themes,
                luckyColor: color,
                luckyNumber: number,
                moonPhase: moonPhase
            )
        } catch {
            // Fallback to basic message if API fails
            return HoroscopeData(
                horoscope: "Connect to see your personalized cosmic insights for today.",
                keyThemes: ["Connection", "Insight", "Growth"],
                luckyColor: "Blue",
                luckyNumber: 7,
                moonPhase: "🌙"
            )
        }
    }
    
    private func calculateMoonPhase(from moonData: PlanetaryPosition?) -> String {
        guard let moon = moonData else { return "🌙" }
        
        // Calculate moon phase based on moon's position relative to sun
        let moonDegree = moon.degrees
        let phaseIndex = Int(moonDegree / 45) % 8
        
        let phases = ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"]
        return phases[phaseIndex]
    }
    
    private func extractLuckyElements(from content: String) -> ([String], String, Int) {
        // Simple keyword extraction for themes
        let themeKeywords = [
            "love": "Love", "career": "Career", "growth": "Growth",
            "wisdom": "Wisdom", "change": "Change", "balance": "Balance",
            "success": "Success", "intuition": "Intuition", "harmony": "Harmony"
        ]
        
        let colors = ["Purple", "Blue", "Green", "Gold", "Silver", "Red", "Orange"]
        let numbers = [1, 3, 7, 9, 11, 13, 21]
        
        var themes: [String] = []
        let lowercaseContent = content.lowercased()
        
        for (keyword, theme) in themeKeywords {
            if lowercaseContent.contains(keyword) && themes.count < 3 {
                themes.append(theme)
            }
        }
        
        // Ensure we have at least 3 themes
        while themes.count < 3 {
            let defaultThemes = ["Insight", "Growth", "Balance"]
            themes.append(defaultThemes[themes.count])
        }
        
        // Derive color and number from content hash for consistency
        let contentHash = abs(content.hashValue)
        let color = colors[contentHash % colors.count]
        let number = numbers[contentHash % numbers.count]
        
        return (Array(themes.prefix(3)), color, number)
    }
}

// MARK: - Entry Data

struct SimpleEntry: TimelineEntry {
    let date: Date
    let horoscope: String
    let keyThemes: [String]
    let luckyColor: String
    let luckyNumber: Int
    let moonPhase: String
}

struct HoroscopeData {
    let horoscope: String
    let keyThemes: [String]
    let luckyColor: String
    let luckyNumber: Int
    let moonPhase: String
}

// MARK: - Widget Views

struct TodaysHoroscopeWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(entry.moonPhase)
                    .font(.title2)
                Spacer()
                Text(formatTime(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Today's Insight")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(entry.horoscope.prefix(60) + "...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Spacer()
            
            HStack {
                Text("Lucky: \(entry.luckyNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(colorForName(entry.luckyColor))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Main content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Horoscope")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(entry.moonPhase)
                        .font(.title2)
                }
                
                Text(entry.horoscope.prefix(120) + (entry.horoscope.count > 120 ? "..." : ""))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                HStack {
                    Text("Lucky Elements")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorForName(entry.luckyColor))
                            .frame(width: 12, height: 12)
                        
                        Text("\(entry.luckyNumber)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // Right side - Key themes
            VStack(alignment: .leading, spacing: 6) {
                Text("Key Themes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                
                ForEach(entry.keyThemes.prefix(3), id: \.self) { theme in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.purple.opacity(0.6))
                            .frame(width: 4, height: 4)
                        
                        Text(theme)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: 80)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Horoscope")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(formatDate(entry.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(entry.moonPhase)
                    .font(.largeTitle)
            }
            
            // Main horoscope text
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Insight")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(entry.horoscope)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            
            // Key themes section
            VStack(alignment: .leading, spacing: 12) {
                Text("Key Themes for Today")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(entry.keyThemes, id: \.self) { theme in
                        HStack {
                            Circle()
                                .fill(.purple.opacity(0.6))
                                .frame(width: 6, height: 6)
                            
                            Text(theme)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            Spacer()
            
            // Lucky elements
            HStack {
                Text("Lucky Elements")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Color:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Circle()
                            .fill(colorForName(entry.luckyColor))
                            .frame(width: 16, height: 16)
                        
                        Text(entry.luckyColor)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Number:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(entry.luckyNumber)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Helper Functions

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

private func colorForName(_ colorName: String) -> Color {
    switch colorName.lowercased() {
    case "purple":
        return .purple
    case "blue":
        return .blue
    case "green":
        return .green
    case "gold":
        return .yellow
    case "silver":
        return .gray
    default:
        return .purple
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodaysHoroscopeWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        horoscope: "The cosmos aligns in your favor today. Trust your intuition and embrace new opportunities that come your way.",
        keyThemes: ["Career", "Love", "Growth"],
        luckyColor: "Purple",
        luckyNumber: 7,
        moonPhase: "🌓"
    )
}

#Preview(as: .systemMedium) {
    TodaysHoroscopeWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        horoscope: "Today brings powerful energies for transformation and growth. The planetary alignments suggest this is an excellent time for introspection and setting new intentions.",
        keyThemes: ["Career", "Love", "Growth", "Balance"],
        luckyColor: "Blue",
        luckyNumber: 3,
        moonPhase: "🌔"
    )
}

#Preview(as: .systemLarge) {
    TodaysHoroscopeWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        horoscope: "The universe recognizes your unique frequency today. You are being called to step into your power and embrace the magic that flows through you. This cosmic alignment brings opportunities for deep transformation and spiritual growth.",
        keyThemes: ["Transformation", "Opportunity", "Peace", "Wisdom"],
        luckyColor: "Gold",
        luckyNumber: 11,
        moonPhase: "🌕"
    )
}