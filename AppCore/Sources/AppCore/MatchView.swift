import SwiftUI
import CoreLocation
import DataModels
import AstroEngine
import CloudKit
import CloudKitKit
import Contacts
import ContactsUI


/// Interactive compatibility analysis with detailed scoring and insights.
struct MatchView: View {
    @State private var partnerName: String = ""
    @State private var partnerDOB: Date = .init()
    @State private var partnerLocation: String = ""
    @State private var partnerBirthTime: Date?
    @State private var includeBirthTime = false
    @State private var selectedFramework = 0
    @State private var score: KundaliMatch?
    @State private var selectedCategory = 0
    @State private var showingLocationPicker = false
    @State private var showingContactPicker = false
    @State private var showingContactsPermission = false
    @State private var contactsPermissionStatus: ContactsPermissionStatus = .notDetermined
    @StateObject private var repo = SavedMatchRepository()
    
    private let categories = ["Overview", "Detailed", "Aspects"]
    private let frameworks = ["Western", "Kundali"]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Contacts Integration Pitch
                    ContactsIntegrationCard(
                        permissionStatus: contactsPermissionStatus,
                        onRequestAccess: requestContactsAccess,
                        onSelectContact: { showingContactPicker = true }
                    )
                    
                    // Framework Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Compatibility Framework")
                            .font(.headline)
                        
                        Picker("Framework", selection: $selectedFramework) {
                            ForEach(frameworks.indices, id: \.self) { index in
                                Text(frameworks[index]).tag(index)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Partner Input Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.pink)
                            Text("Manual Partner Entry")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            TextField("Partner's Name", text: $partnerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            DatePicker("Birth Date", 
                                      selection: $partnerDOB, 
                                      in: ...Date(),
                                      displayedComponents: .date)
                            
                            // Birth Time (required for Kundali)
                            if selectedFramework == 1 { // Kundali
                                Toggle("Include Birth Time", isOn: $includeBirthTime)
                                
                                if includeBirthTime {
                                    DatePicker("Birth Time", 
                                              selection: Binding(
                                                get: { partnerBirthTime ?? Date() },
                                                set: { partnerBirthTime = $0 }
                                              ),
                                              displayedComponents: .hourAndMinute)
                                }
                            }
                            
                            // Birth Location (optional for Western, preferred for Kundali)
                            HStack {
                                TextField("Birth Location \(selectedFramework == 1 ? "(Recommended)" : "(Optional)")", text: $partnerLocation)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("📍") {
                                    showingLocationPicker = true
                                }
                            }
                        }
                        
                        Button("Analyze Compatibility") {
                            compute()
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(partnerName.isEmpty ? .gray : .pink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(partnerName.isEmpty)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Compatibility Results
                    if let score = score {
                        VStack(spacing: 20) {
                            // Score Overview
                            CompatibilityScoreCard(match: score)
                            
                            // Category Selector
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories.indices, id: \.self) { index in
                                    Text(categories[index]).tag(index)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            // Category Content
                            Group {
                                switch selectedCategory {
                                case 0:
                                    CompatibilityOverview(match: score)
                                case 1:
                                    DetailedCompatibilityView(match: score)
                                case 2:
                                    AspectsCompatibilityView(match: score)
                                default:
                                    CompatibilityOverview(match: score)
                                }
                            }
                            
                            // Save Button
                            Button("Save This Match") {
                                Task { 
                                    try? await repo.save(score)
                                    await repo.refresh()
                                }
                            }
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                    
                    // Saved Matches
                    if !repo.matches.isEmpty {
                        SavedMatchesSection(matches: repo.matches) { match in
                            Task {
                                if let recordID = match.recordID {
                                    try? await repo.delete(id: recordID)
                                    await repo.refresh()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Compatibility")
            .task {
                await repo.refresh()
                checkContactsPermission()
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationSearchView(query: $partnerLocation, selectedLocation: .constant(nil))
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView { contact in
                fillFromContact(contact)
            }
        }
        .alert("Connect with Your Contacts", isPresented: $showingContactsPermission) {
            Button("Allow Access") {
                requestContactsAccess()
            }
            Button("Maybe Later", role: .cancel) {}
        } message: {
            Text("Find out what the stars say about your compatibility with friends, family, and colleagues. Make your relationships richer with cosmic insights.")
        }
    }
    
    private func checkContactsPermission() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        contactsPermissionStatus = ContactsPermissionStatus(from: status)
    }
    
    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                checkContactsPermission()
                if granted {
                    showingContactPicker = true
                }
            }
        }
    }
    
    private func fillFromContact(_ contact: CNContact) {
        partnerName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        
        // Try to extract birth date from contact if available
        if let birthday = contact.birthday {
            let calendar = Calendar.current
            let components = DateComponents(
                year: birthday.year,
                month: birthday.month,
                day: birthday.day
            )
            if let birthDate = calendar.date(from: components) {
                partnerDOB = birthDate
            }
        }
        
        // Note: Birth time and location would need to be manually entered
        // as they're not typically stored in contacts
    }

    private func compute() {
        Task {
            do {
                // Get user's profile for real birth data
                let recordID = try await CKContainer.cosmic.fetchUserRecordID()
                let profile: UserProfile = try await CKDatabaseProxy.private.fetch(type: UserProfile.self, id: recordID)
                
                let me = BirthData(date: profile.birthDate,
                                   time: profile.birthTime,
                                   location: profile.birthPlace)
                
                // For Kundali framework, include birth time if provided
                let partnerTimeComponents = (selectedFramework == 1 && includeBirthTime) ? 
                    Calendar.current.dateComponents([.hour, .minute], from: partnerBirthTime ?? Date()) : nil
                
                let partner = BirthData(date: partnerDOB,
                                        time: partnerTimeComponents,
                                        location: profile.birthPlace) // Use user's location as fallback
                
                await MainActor.run {
                    score = MatchService().compare(myData: me,
                                                   partnerData: partner,
                                                   partnerName: partnerName)
                }
            } catch {
                print("[MatchView] Failed to load profile: \(error)")
            }
        }
    }
}

// MARK: - Compatibility Views

struct CompatibilityScoreCard: View {
    let match: KundaliMatch
    
    var body: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(match.scoreTotal) / 36.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(match.scoreTotal)")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(scoreColor)
                    Text("out of 36")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                Text(match.partnerName)
                    .font(.title2.weight(.semibold))
                Text(compatibilityLevel)
                    .font(.callout)
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(scoreColor.opacity(0.1), in: Capsule())
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var scoreColor: Color {
        switch match.scoreTotal {
        case 0...12: return .red
        case 13...24: return .orange
        case 25...30: return .yellow
        case 31...36: return .green
        default: return .gray
        }
    }
    
    private var compatibilityLevel: String {
        switch match.scoreTotal {
        case 0...12: return "Low Compatibility"
        case 13...24: return "Moderate Compatibility"
        case 25...30: return "High Compatibility"
        case 31...36: return "Excellent Compatibility"
        default: return "Unknown"
        }
    }
}

struct CompatibilityOverview: View {
    let match: KundaliMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compatibility Overview")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                OverviewCard(title: "Emotional Bond", score: Int(round(Double(match.scoreTotal) / 36.0 * 10)), icon: "heart.fill", color: .pink)
                OverviewCard(title: "Mental Harmony", score: Int(round(Double(match.scoreTotal) / 36.0 * 10)), icon: "brain.head.profile", color: .blue)
                OverviewCard(title: "Physical Attraction", score: Int(round(Double(match.scoreTotal) / 36.0 * 10)), icon: "sparkles", color: .purple)
                OverviewCard(title: "Long-term Potential", score: Int(round(Double(match.scoreTotal) / 36.0 * 10)), icon: "infinity", color: .green)
            }
            .padding(.horizontal)
        }
    }
}

struct OverviewCard: View {
    let title: String
    let score: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("\(score)/10")
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailedCompatibilityView: View {
    let match: KundaliMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Analysis")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                DetailRow(category: "Varna (Spiritual Compatibility)", score: 1, maxScore: 1)
                DetailRow(category: "Vashya (Attraction)", score: 2, maxScore: 2)
                DetailRow(category: "Tara (Health & Longevity)", score: 3, maxScore: 3)
                DetailRow(category: "Yoni (Sexual Compatibility)", score: 4, maxScore: 4)
                DetailRow(category: "Graha Maitri (Mental Compatibility)", score: 5, maxScore: 5)
                DetailRow(category: "Gana (Temperament)", score: 6, maxScore: 6)
                DetailRow(category: "Bhakoot (Love & Affection)", score: 7, maxScore: 7)
                DetailRow(category: "Nadi (Health of Progeny)", score: 8, maxScore: 8)
            }
            .padding(.horizontal)
        }
    }
}

struct DetailRow: View {
    let category: String
    let score: Int
    let maxScore: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.callout)
                Text("\(score)/\(maxScore) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ProgressView(value: Double(score), total: Double(maxScore))
                .frame(width: 60)
                .progressViewStyle(LinearProgressViewStyle(tint: score == maxScore ? .green : .orange))
        }
        .padding(.vertical, 4)
    }
}

struct AspectsCompatibilityView: View {
    let match: KundaliMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Astrological Aspects")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                AspectCard(
                    title: "Sun-Moon Harmony",
                    description: "Your core personalities complement each other well, creating a balanced dynamic.",
                    strength: .high,
                    icon: "sun.max.fill",
                    color: .orange
                )
                
                AspectCard(
                    title: "Venus-Mars Attraction",
                    description: "Strong romantic and physical attraction between you both.",
                    strength: .medium,
                    icon: "heart.fill",
                    color: .pink
                )
                
                AspectCard(
                    title: "Mercury Communication",
                    description: "Good potential for understanding and clear communication.",
                    strength: .high,
                    icon: "message.fill",
                    color: .blue
                )
            }
            .padding(.horizontal)
        }
    }
}

struct AspectCard: View {
    let title: String
    let description: String
    let strength: CompatibilityStrength
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(strength.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(strengthColor.opacity(0.2), in: Capsule())
                    .foregroundStyle(strengthColor)
            }
            
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var strengthColor: Color {
        switch strength {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

enum CompatibilityStrength: String {
    case high = "Strong"
    case medium = "Good"
    case low = "Weak"
}

struct SavedMatchesSection: View {
    let matches: [KundaliMatch]
    let onDelete: (KundaliMatch) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.blue)
                Text("Saved Matches")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(matches) { match in
                    SavedMatchRow(match: match) {
                        onDelete(match)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SavedMatchRow: View {
    let match: KundaliMatch
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(match.partnerName)
                    .font(.headline)
                Text(formatDate(match.partnerDOB))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text("Score: \(match.scoreTotal)/36")
                        .font(.callout.weight(.medium))
                    Spacer()
                    Text(compatibilityLevel)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(scoreColor.opacity(0.2), in: Capsule())
                        .foregroundStyle(scoreColor)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var scoreColor: Color {
        switch match.scoreTotal {
        case 0...12: return .red
        case 13...24: return .orange
        case 25...30: return .yellow
        case 31...36: return .green
        default: return .gray
        }
    }
    
    private var compatibilityLevel: String {
        switch match.scoreTotal {
        case 0...12: return "Low"
        case 13...24: return "Moderate"
        case 25...30: return "High"
        case 31...36: return "Excellent"
        default: return "Unknown"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Contacts Integration

struct ContactsIntegrationCard: View {
    let permissionStatus: ContactsPermissionStatus
    let onRequestAccess: () -> Void
    let onSelectContact: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect with Your Contacts")
                        .font(.headline)
                    Text("Make your relationships richer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            Text("Find out what the stars say about your compatibility with friends, family, and colleagues. Discover cosmic insights about your existing relationships.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)
                Text("Instantly analyze compatibility with your contacts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Group {
                switch permissionStatus {
                case .notDetermined:
                    Button("Connect Contacts") {
                        onRequestAccess()
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                case .authorized:
                    Button("Select from Contacts") {
                        onSelectContact()
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                case .denied:
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Contacts access denied")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        
                        Text("Enable in Settings > Privacy & Security > Contacts to use this feature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ContactPickerView: UIViewControllerRepresentable {
    let onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (CNContact) -> Void
        
        init(onContactSelected: @escaping (CNContact) -> Void) {
            self.onContactSelected = onContactSelected
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onContactSelected(contact)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

enum ContactsPermissionStatus {
    case notDetermined
    case authorized
    case denied
    
    init(from cnStatus: CNAuthorizationStatus) {
        switch cnStatus {
        case .notDetermined:
            self = .notDetermined
        case .authorized:
            self = .authorized
        case .denied, .restricted:
            self = .denied
        @unknown default:
            self = .notDetermined
        }
    }
}

