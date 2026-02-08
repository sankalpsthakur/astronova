//
//  TempleModels.swift
//  AstronovaApp
//
//  Models for the Temple tab - Astrologers, Muhurat, Pooja, Booking,
//  Temple Bell, DIY Pooja, Vedic Library, and Panchang
//

import Foundation

// MARK: - Astrologer Models (Local/Sample)

struct Astrologer: Identifiable {
    let id: String
    let name: String
    let specialization: String
    let experience: String
    let rating: Double
    let reviewCount: Int
    let pricePerMinute: Int
    let avatarURL: String?
    let isOnline: Bool
    let languages: [String]
    let expertise: [String]

    /// When this `Astrologer` was created from a real pandit profile, `id` is the API `panditId`.
    /// Sample astrologers use `ast_...` IDs and should not be passed to booking endpoints.
    var apiPanditId: String? {
        id.hasPrefix("ast_") ? nil : id
    }

    static let samples: [Astrologer] = [
        Astrologer(
            id: "ast_001",
            name: "Astrologer Sharma",
            specialization: "Vedic Astrology",
            experience: "25+ years",
            rating: 4.9,
            reviewCount: 2847,
            pricePerMinute: 30,
            avatarURL: nil,
            isOnline: true,
            languages: ["Hindi", "English"],
            expertise: ["Birth Chart", "Kundli Matching", "Career"]
        ),
        Astrologer(
            id: "ast_002",
            name: "Acharya Mishra",
            specialization: "Nadi Astrology",
            experience: "18 years",
            rating: 4.8,
            reviewCount: 1923,
            pricePerMinute: 25,
            avatarURL: nil,
            isOnline: true,
            languages: ["Hindi", "Tamil", "English"],
            expertise: ["Nadi Reading", "Past Life", "Remedies"]
        ),
        Astrologer(
            id: "ast_003",
            name: "Dr. Kavitha Iyer",
            specialization: "KP Astrology",
            experience: "15 years",
            rating: 4.7,
            reviewCount: 1456,
            pricePerMinute: 35,
            avatarURL: nil,
            isOnline: false,
            languages: ["English", "Tamil"],
            expertise: ["KP System", "Horary", "Medical Astrology"]
        ),
        Astrologer(
            id: "ast_004",
            name: "Jyotishi Ramdev",
            specialization: "Lal Kitab",
            experience: "20 years",
            rating: 4.6,
            reviewCount: 2103,
            pricePerMinute: 20,
            avatarURL: nil,
            isOnline: true,
            languages: ["Hindi", "Punjabi"],
            expertise: ["Lal Kitab", "Vastu", "Remedies"]
        )
    ]
}

extension Astrologer {
    static func fromPandit(_ pandit: PanditProfile) -> Astrologer {
        let pricePerMinute = max(1, pandit.pricePerSession / 30)
        return Astrologer(
            id: pandit.id,
            name: pandit.name,
            specialization: pandit.primarySpecialization,
            experience: pandit.experienceString,
            rating: pandit.rating,
            reviewCount: pandit.reviewCount,
            pricePerMinute: pricePerMinute,
            avatarURL: pandit.avatarUrl,
            isOnline: pandit.isAvailable,
            languages: pandit.languages,
            expertise: pandit.specializations
        )
    }
}

// MARK: - API Response Models

/// Pooja type from API
struct PoojaType: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let deity: String
    let durationMinutes: Int
    let basePrice: Int
    let iconName: String
    let benefits: [String]
    let ingredients: [String]
    let mantras: [String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        deity = try container.decode(String.self, forKey: .deity)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        basePrice = try container.decode(Int.self, forKey: .basePrice)
        iconName = try container.decode(String.self, forKey: .iconName)
        benefits = try container.decodeIfPresent([String].self, forKey: .benefits) ?? []
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        mantras = try container.decodeIfPresent([String].self, forKey: .mantras)
    }
}

/// Pandit profile from API
struct PanditProfile: Codable, Identifiable {
    let id: String
    let name: String
    let specializations: [String]
    let languages: [String]
    let experienceYears: Int
    let rating: Double
    let reviewCount: Int
    let pricePerSession: Int
    let avatarUrl: String?
    let bio: String?
    let isVerified: Bool
    let isAvailable: Bool

    var experienceString: String {
        return "\(experienceYears)+ years"
    }

    var primarySpecialization: String {
        return specializations.first ?? "Vedic Astrology"
    }
}

/// Availability slot
struct AvailabilitySlot: Codable, Identifiable {
    var id: String { "\(date)-\(time)" }
    let date: String
    let time: String
    let available: Bool
}

/// Booking response from create
struct PoojaBookingResponse: Codable {
    let bookingId: String
    let status: String
    let scheduledDate: String
    let scheduledTime: String
    let amountDue: Int
    let message: String
}

/// Booking list item
struct PoojaBooking: Codable, Identifiable {
    let id: String
    let poojaTypeId: String
    let poojaName: String
    let poojaIcon: String
    let durationMinutes: Int
    let panditId: String?
    let panditName: String?
    let scheduledDate: String
    let scheduledTime: String
    let timezone: String
    let status: String
    let sankalpName: String?
    let amountPaid: Int
    let paymentStatus: String
    let sessionLink: String?
    let createdAt: String

    var statusDisplay: BookingStatus {
        BookingStatus(rawValue: status) ?? .pending
    }
}

/// Detailed booking
struct PoojaBookingDetail: Codable, Identifiable {
    let id: String
    let poojaTypeId: String
    let poojaName: String
    let poojaIcon: String
    let durationMinutes: Int
    let benefits: [String]
    let ingredients: [String]
    let panditId: String?
    let panditName: String?
    let panditAvatar: String?
    let scheduledDate: String
    let scheduledTime: String
    let timezone: String
    let status: String
    let sankalpName: String?
    let sankalpGotra: String?
    let sankalpNakshatra: String?
    let specialRequests: String?
    let amountPaid: Int
    let paymentStatus: String
    let sessionLink: String?
    let createdAt: String

    var statusDisplay: BookingStatus {
        BookingStatus(rawValue: status) ?? .pending
    }
}

/// Cancel booking response
struct CancelBookingResponse: Codable {
    let bookingId: String
    let status: String
    let message: String
}

/// Session link response
struct SessionLinkResponse: Codable {
    let sessionId: String
    let sessionLink: String
    let status: String
    let message: String

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case sessionLink
        case userLink
        case status
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "confirmed"
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        if let link = try container.decodeIfPresent(String.self, forKey: .sessionLink) {
            sessionLink = link
        } else if let link = try container.decodeIfPresent(String.self, forKey: .userLink) {
            sessionLink = link
        } else {
            sessionLink = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(sessionLink, forKey: .sessionLink)
        try container.encode(status, forKey: .status)
        try container.encode(message, forKey: .message)
    }
}

/// Booking status enum
enum BookingStatus: String, CaseIterable {
    case pending
    case confirmed
    case inProgress = "in_progress"
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .pending: return "cosmicWarning"
        case .confirmed: return "cosmicSuccess"
        case .inProgress: return "cosmicGold"
        case .completed: return "cosmicAmethyst"
        case .cancelled: return "cosmicError"
        }
    }
}

// MARK: - Muhurat Models

struct Muhurat: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let startTime: Date
    let endTime: Date
    let quality: MuhuratQuality
    let suitable: [String]
    let avoid: [String]

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, startTime, endTime, quality, suitable, avoid
    }

    init(id: String, name: String, description: String, startTime: Date, endTime: Date, quality: MuhuratQuality, suitable: [String], avoid: [String]) {
        self.id = id
        self.name = name
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
        self.suitable = suitable
        self.avoid = avoid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        quality = try container.decode(MuhuratQuality.self, forKey: .quality)
        suitable = try container.decodeIfPresent([String].self, forKey: .suitable) ?? []
        avoid = try container.decodeIfPresent([String].self, forKey: .avoid) ?? []

        let startTimeString = try container.decode(String.self, forKey: .startTime)
        let endTimeString = try container.decode(String.self, forKey: .endTime)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]
        if let s = iso.date(from: startTimeString) ?? isoBasic.date(from: startTimeString) {
            startTime = s
        } else {
            throw DecodingError.dataCorruptedError(forKey: .startTime, in: container, debugDescription: "Invalid ISO8601 date: \(startTimeString)")
        }
        if let e = iso.date(from: endTimeString) ?? isoBasic.date(from: endTimeString) {
            endTime = e
        } else {
            throw DecodingError.dataCorruptedError(forKey: .endTime, in: container, debugDescription: "Invalid ISO8601 date: \(endTimeString)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(quality, forKey: .quality)
        try container.encode(suitable, forKey: .suitable)
        try container.encode(avoid, forKey: .avoid)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        try container.encode(iso.string(from: startTime), forKey: .startTime)
        try container.encode(iso.string(from: endTime), forKey: .endTime)
    }

    static func sampleMuhurats() -> [Muhurat] {
        let calendar = Calendar.current
        let now = Date()

        return [
            Muhurat(
                id: "muh_001",
                name: "Abhijit Muhurat",
                description: "Most auspicious time of the day, ruled by Lord Vishnu",
                startTime: calendar.date(bySettingHour: 11, minute: 48, second: 0, of: now) ?? now,
                endTime: calendar.date(bySettingHour: 12, minute: 36, second: 0, of: now) ?? now,
                quality: .excellent,
                suitable: ["New ventures", "Important decisions", "Travel", "Investments"],
                avoid: []
            ),
            Muhurat(
                id: "muh_002",
                name: "Brahma Muhurat",
                description: "Divine hour before sunrise, ideal for spiritual practices",
                startTime: calendar.date(bySettingHour: 4, minute: 24, second: 0, of: now) ?? now,
                endTime: calendar.date(bySettingHour: 5, minute: 12, second: 0, of: now) ?? now,
                quality: .excellent,
                suitable: ["Meditation", "Yoga", "Prayers", "Study"],
                avoid: ["Material activities"]
            ),
            Muhurat(
                id: "muh_003",
                name: "Rahu Kalam",
                description: "Inauspicious period ruled by Rahu - avoid new beginnings",
                startTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now,
                endTime: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now) ?? now,
                quality: .avoid,
                suitable: [],
                avoid: ["New ventures", "Travel", "Important work", "Purchases"]
            ),
            Muhurat(
                id: "muh_004",
                name: "Godhuli Muhurat",
                description: "Twilight hour when cows return - auspicious for marriages",
                startTime: calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now) ?? now,
                endTime: calendar.date(bySettingHour: 18, minute: 10, second: 0, of: now) ?? now,
                quality: .good,
                suitable: ["Weddings", "Ceremonies", "Housewarming"],
                avoid: []
            )
        ]
    }
}

enum MuhuratQuality: String, Codable {
    case excellent
    case good
    case neutral
    case avoid

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .neutral: return "Neutral"
        case .avoid: return "Avoid"
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .neutral: return "circle.fill"
        case .avoid: return "xmark.circle.fill"
        }
    }
}

// MARK: - Pooja Models

struct PoojaItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let duration: String
    let deity: String
    let benefits: [String]
    let ingredients: [PoojaIngredient]

    static let samples: [PoojaItem] = [
        PoojaItem(
            id: "pooja_001",
            name: "Ganesh Puja",
            description: "Remove obstacles and invite new beginnings",
            iconName: "sparkles",
            duration: "45 mins",
            deity: "Lord Ganesha",
            benefits: ["Remove obstacles", "New beginnings", "Success", "Wisdom"],
            ingredients: [
                PoojaIngredient(name: "Modak", quantity: "5 pieces", category: .offering),
                PoojaIngredient(name: "Red flowers", quantity: "21 flowers", category: .flowers),
                PoojaIngredient(name: "Durva grass", quantity: "21 blades", category: .special),
                PoojaIngredient(name: "Coconut", quantity: "1 whole", category: .offering),
                PoojaIngredient(name: "Vermillion (Sindoor)", quantity: "1 packet", category: .essential),
                PoojaIngredient(name: "Incense sticks", quantity: "1 pack", category: .essential)
            ]
        ),
        PoojaItem(
            id: "pooja_002",
            name: "Lakshmi Puja",
            description: "Invoke prosperity and abundance",
            iconName: "indianrupeesign.circle.fill",
            duration: "60 mins",
            deity: "Goddess Lakshmi",
            benefits: ["Wealth", "Prosperity", "Good fortune", "Abundance"],
            ingredients: [
                PoojaIngredient(name: "Lotus flowers", quantity: "11 flowers", category: .flowers),
                PoojaIngredient(name: "Gold/Silver coins", quantity: "Few pieces", category: .special),
                PoojaIngredient(name: "Rice (Akshat)", quantity: "250g", category: .essential),
                PoojaIngredient(name: "Turmeric powder", quantity: "50g", category: .essential),
                PoojaIngredient(name: "Kumkum", quantity: "1 packet", category: .essential),
                PoojaIngredient(name: "Ghee lamp", quantity: "1 diya", category: .essential)
            ]
        ),
        PoojaItem(
            id: "pooja_003",
            name: "Navagraha Shanti",
            description: "Planetary harmony and cosmic balance",
            iconName: "moon.stars.fill",
            duration: "90 mins",
            deity: "Nine Planets",
            benefits: ["Planetary balance", "Reduce malefic effects", "Peace", "Harmony"],
            ingredients: [
                PoojaIngredient(name: "9 types of grains", quantity: "100g each", category: .special),
                PoojaIngredient(name: "9 colored cloths", quantity: "1 each color", category: .special),
                PoojaIngredient(name: "9 types of flowers", quantity: "11 each", category: .flowers),
                PoojaIngredient(name: "Sesame oil", quantity: "250ml", category: .essential),
                PoojaIngredient(name: "Camphor", quantity: "1 packet", category: .essential),
                PoojaIngredient(name: "Sandalwood paste", quantity: "50g", category: .essential)
            ]
        ),
        PoojaItem(
            id: "pooja_004",
            name: "Satyanarayan Katha",
            description: "Fulfill wishes and seek divine blessings",
            iconName: "sun.max.fill",
            duration: "120 mins",
            deity: "Lord Vishnu",
            benefits: ["Wish fulfillment", "Prosperity", "Peace", "Divine blessings"],
            ingredients: [
                PoojaIngredient(name: "Banana", quantity: "2 dozens", category: .offering),
                PoojaIngredient(name: "Wheat flour", quantity: "500g", category: .offering),
                PoojaIngredient(name: "Sugar", quantity: "500g", category: .offering),
                PoojaIngredient(name: "Tulsi leaves", quantity: "21 leaves", category: .special),
                PoojaIngredient(name: "Panchamrit", quantity: "Prepared", category: .essential),
                PoojaIngredient(name: "Mango leaves", quantity: "5 leaves", category: .special)
            ]
        )
    ]
}

struct PoojaIngredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: String
    let category: IngredientCategory
}

enum IngredientCategory: String, Codable {
    case essential
    case flowers
    case offering
    case special

    var displayName: String {
        switch self {
        case .essential: return "Essential"
        case .flowers: return "Flowers"
        case .offering: return "Offerings"
        case .special: return "Special Items"
        }
    }

    var icon: String {
        switch self {
        case .essential: return "checkmark.seal.fill"
        case .flowers: return "leaf.fill"
        case .offering: return "gift.fill"
        case .special: return "star.fill"
        }
    }
}

// MARK: - Temple Bell Models

struct TempleBellState: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastRingDay: String?
    var totalRings: Int
    var reminderHour: Int
    var reminderEnabled: Bool

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastRingDay: String? = nil, totalRings: Int = 0, reminderHour: Int = 8, reminderEnabled: Bool = true) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastRingDay = lastRingDay
        self.totalRings = totalRings
        self.reminderHour = reminderHour
        self.reminderEnabled = reminderEnabled
    }

    var hasRungToday: Bool {
        lastRingDay == Self.todayKey()
    }

    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    static func yesterdayKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }

    static func load() -> TempleBellState {
        guard let data = UserDefaults.standard.data(forKey: "temple_bell_state"),
              let state = try? JSONDecoder().decode(TempleBellState.self, from: data) else {
            return TempleBellState()
        }
        return state
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "temple_bell_state")
        }
    }
}

// MARK: - DIY Pooja Models

struct DIYPooja: Codable, Identifiable, Hashable {
    static func == (lhs: DIYPooja, rhs: DIYPooja) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let name: String
    let description: String
    let deity: String
    let deityDescription: String
    let significance: String
    let iconName: String
    let durationMinutes: Int
    let steps: [DIYPoojaStep]
    let ingredients: [DIYPoojaIngredient]

    static let samples: [DIYPooja] = [
        DIYPooja(
            id: "diy_001",
            name: "Ganesh Pooja",
            description: "Daily prayer to Lord Ganesha, the remover of obstacles",
            deity: "Lord Ganesha",
            deityDescription: "Elephant-headed god of wisdom, success, and new beginnings",
            significance: "Ganesh Pooja is traditionally performed before any new venture or important task. It removes obstacles and brings wisdom.",
            iconName: "sparkles",
            durationMinutes: 30,
            steps: [
                DIYPoojaStep(id: "diy_001_s1", stepNumber: 1, title: "Dhyana (Meditation)", description: "Sit facing east. Close your eyes and meditate on Lord Ganesha's form.", mantraSanskrit: "Om Gam Ganapataye Namaha", mantraTransliteration: "Om Gam Ga-na-pa-ta-ye Na-ma-ha", mantraMeaning: "Salutations to Lord Ganesha", timerDurationSeconds: 120),
                DIYPoojaStep(id: "diy_001_s2", stepNumber: 2, title: "Avahana (Invocation)", description: "Place the Ganesha idol or image on a clean altar. Sprinkle water around it.", mantraSanskrit: "Agajaanana Padmaarkam Gajaananam Aharnisham", mantraTransliteration: "A-ga-jaa-na-na Pad-maar-kam Ga-jaa-na-nam A-har-ni-sham", mantraMeaning: "I meditate on the elephant-faced one day and night", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_001_s3", stepNumber: 3, title: "Offer Durva Grass", description: "Offer 21 blades of durva grass to Lord Ganesha. Durva is his favorite offering.", mantraSanskrit: "Durvaankurairapi Samyuktaih Poojayaami Gajaaananam", mantraTransliteration: "Dur-vaan-ku-rair-a-pi Sam-yuk-taih Poo-ja-yaa-mi Ga-jaa-na-nam", mantraMeaning: "I worship Lord Ganesha with durva grass sprouts", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_001_s4", stepNumber: 4, title: "Offer Modak", description: "Offer modak (sweet dumplings) as prasad. Modak is Lord Ganesha's favorite food.", mantraSanskrit: "Naivedyam Gruhyataam Deva Bhaktim Me Achalam Kuru", mantraTransliteration: "Nai-ved-yam Gruh-ya-taam De-va Bhak-tim Me A-cha-lam Ku-ru", mantraMeaning: "Accept this offering, O Lord, and make my devotion unwavering", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_001_s5", stepNumber: 5, title: "Aarti", description: "Light the ghee lamp and perform aarti by moving it clockwise before the deity.", mantraSanskrit: "Jai Ganesh Jai Ganesh Jai Ganesh Deva", mantraTransliteration: "Jai Ga-nesh Jai Ga-nesh Jai Ga-nesh De-va", mantraMeaning: "Victory to Lord Ganesha", timerDurationSeconds: 180),
                DIYPoojaStep(id: "diy_001_s6", stepNumber: 6, title: "Mantra Chanting", description: "Chant the Ganesha mantra 108 times using a mala (prayer beads).", mantraSanskrit: "Om Gam Ganapataye Namaha", mantraTransliteration: "Om Gam Ga-na-pa-ta-ye Na-ma-ha", mantraMeaning: "Salutations to Lord Ganesha", timerDurationSeconds: 600)
            ],
            ingredients: [
                DIYPoojaIngredient(id: "diy_001_i1", name: "Modak", quantity: "5 pieces", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_001_i2", name: "Durva Grass", quantity: "21 blades", category: .special, isOptional: false),
                DIYPoojaIngredient(id: "diy_001_i3", name: "Red Flowers", quantity: "11 flowers", category: .flowers, isOptional: false),
                DIYPoojaIngredient(id: "diy_001_i4", name: "Ghee Lamp", quantity: "1 diya", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_001_i5", name: "Incense Sticks", quantity: "2 sticks", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_001_i6", name: "Coconut", quantity: "1 whole", category: .offering, isOptional: true)
            ]
        ),
        DIYPooja(
            id: "diy_002",
            name: "Shiva Pooja",
            description: "Sacred worship of Lord Shiva with abhishekam and bilva leaves",
            deity: "Lord Shiva",
            deityDescription: "The auspicious destroyer and transformer among the Hindu trinity",
            significance: "Shiva Pooja purifies the mind and soul. Monday is especially sacred for Shiva worship. It grants peace and liberation.",
            iconName: "moon.fill",
            durationMinutes: 45,
            steps: [
                DIYPoojaStep(id: "diy_002_s1", stepNumber: 1, title: "Dhyana (Meditation)", description: "Sit in a calm place and meditate on Lord Shiva's cosmic form.", mantraSanskrit: "Dhyaayennittyam Mahesham Rajatagirinibham Chaaruchhandraavathamsam", mantraTransliteration: "Dhyaa-yen-nit-tyam Ma-he-sham Ra-ja-ta-gi-ri-ni-bham", mantraMeaning: "I meditate on the great Lord who shines like a silver mountain", timerDurationSeconds: 120),
                DIYPoojaStep(id: "diy_002_s2", stepNumber: 2, title: "Abhishekam (Sacred Bath)", description: "Pour water, then milk, then honey over the Shiva Lingam while chanting.", mantraSanskrit: "Om Namah Shivaya", mantraTransliteration: "Om Na-mah Shi-vaa-ya", mantraMeaning: "I bow to Lord Shiva", timerDurationSeconds: 300),
                DIYPoojaStep(id: "diy_002_s3", stepNumber: 3, title: "Offer Bilva Leaves", description: "Place bilva (bael) leaves on the Shiva Lingam. Offer in sets of three.", mantraSanskrit: "Tridalam Trigunaakaaram Trinetram Cha Triyaayudham", mantraTransliteration: "Tri-da-lam Tri-gu-naa-kaa-ram Tri-ne-tram Cha Tri-yaa-yu-dham", mantraMeaning: "The three-leafed bilva represents the three qualities and the three-eyed Lord", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_002_s4", stepNumber: 4, title: "Apply Vibhuti", description: "Apply sacred ash (vibhuti) to the Lingam and your forehead.", mantraSanskrit: "Shivam Shivakaram Shaantam Shivaatmaanam Shivottamam", mantraTransliteration: "Shi-vam Shi-va-ka-ram Shaan-tam Shi-vaat-maa-nam Shi-vot-ta-mam", mantraMeaning: "Shiva is auspicious, the creator of auspiciousness, peaceful", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_002_s5", stepNumber: 5, title: "Aarti", description: "Light camphor and perform aarti, moving the flame clockwise.", mantraSanskrit: "Om Jai Shiv Omkara Swami Jai Shiv Omkara", mantraTransliteration: "Om Jai Shiv Om-ka-ra Swaa-mi Jai Shiv Om-ka-ra", mantraMeaning: "Victory to Lord Shiva, the embodiment of Om", timerDurationSeconds: 180),
                DIYPoojaStep(id: "diy_002_s6", stepNumber: 6, title: "Rudra Mantra", description: "Chant the Panchakshari mantra 108 times.", mantraSanskrit: "Om Namah Shivaya", mantraTransliteration: "Om Na-mah Shi-vaa-ya", mantraMeaning: "I bow to Lord Shiva", timerDurationSeconds: 600),
                DIYPoojaStep(id: "diy_002_s7", stepNumber: 7, title: "Pradakshina", description: "Walk around the Shiva Lingam or altar clockwise three times.", mantraSanskrit: "Yaani Kaani Cha Paapaani Janmaantara Kritaani Cha", mantraTransliteration: "Yaa-ni Kaa-ni Cha Paa-paa-ni Jan-maan-ta-ra Kri-taa-ni Cha", mantraMeaning: "May all sins from this and past lives be destroyed", timerDurationSeconds: nil)
            ],
            ingredients: [
                DIYPoojaIngredient(id: "diy_002_i1", name: "Bilva Leaves", quantity: "21 leaves", category: .special, isOptional: false),
                DIYPoojaIngredient(id: "diy_002_i2", name: "Milk", quantity: "250ml", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_002_i3", name: "Honey", quantity: "2 tbsp", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_002_i4", name: "Vibhuti (Sacred Ash)", quantity: "1 packet", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_002_i5", name: "Camphor", quantity: "5 pieces", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_002_i6", name: "White Flowers", quantity: "11 flowers", category: .flowers, isOptional: true)
            ]
        ),
        DIYPooja(
            id: "diy_003",
            name: "Lakshmi Pooja",
            description: "Worship of Goddess Lakshmi for wealth, prosperity, and abundance",
            deity: "Goddess Lakshmi",
            deityDescription: "Goddess of wealth, fortune, prosperity, and beauty",
            significance: "Lakshmi Pooja invites prosperity and abundance. Friday is the most auspicious day. It is central to Diwali celebrations.",
            iconName: "indianrupeesign.circle.fill",
            durationMinutes: 40,
            steps: [
                DIYPoojaStep(id: "diy_003_s1", stepNumber: 1, title: "Kalash Sthapana", description: "Fill a copper pot with water, place mango leaves and a coconut on top.", mantraSanskrit: "Om Shri Mahalakshmyai Namaha", mantraTransliteration: "Om Shri Ma-ha-lak-shm-yai Na-ma-ha", mantraMeaning: "Salutations to the great Goddess Lakshmi", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_003_s2", stepNumber: 2, title: "Dhyana (Meditation)", description: "Meditate on Goddess Lakshmi seated on a lotus, bestowing blessings.", mantraSanskrit: "Sarva Mangala Maangalye Shive Sarvaartha Saadhike", mantraTransliteration: "Sar-va Man-ga-la Maan-gal-ye Shi-ve Sar-vaar-tha Saa-dhi-ke", mantraMeaning: "O auspicious one, who fulfills all desires", timerDurationSeconds: 120),
                DIYPoojaStep(id: "diy_003_s3", stepNumber: 3, title: "Offer Lotus Flowers", description: "Place lotus flowers or rose petals at the feet of the Goddess.", mantraSanskrit: "Padmaasane Padmakare Sarvalokahite Sadaa", mantraTransliteration: "Pad-maa-sa-ne Pad-ma-ka-re Sar-va-lo-ka-hi-te Sa-daa", mantraMeaning: "She who sits on a lotus, holds a lotus, and always benefits all worlds", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_003_s4", stepNumber: 4, title: "Kumkum and Haldi", description: "Apply kumkum and turmeric to the image or idol of Lakshmi.", mantraSanskrit: "Chandram Hiranmayeem Lakshmeem Jaatavedo Ma Aavaha", mantraTransliteration: "Chan-dram Hi-ran-ma-yeem Lak-shmeem Jaa-ta-ve-do Ma Aa-va-ha", mantraMeaning: "O fire god, bring to me the golden Lakshmi", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_003_s5", stepNumber: 5, title: "Lakshmi Aarti", description: "Light ghee lamps and perform aarti while singing the Lakshmi aarti.", mantraSanskrit: "Om Jai Lakshmi Maata Maiyaa Jai Lakshmi Maata", mantraTransliteration: "Om Jai Lak-shmi Maa-ta Mai-yaa Jai Lak-shmi Maa-ta", mantraMeaning: "Victory to Mother Lakshmi", timerDurationSeconds: 180),
                DIYPoojaStep(id: "diy_003_s6", stepNumber: 6, title: "Mantra Japa", description: "Chant the Lakshmi Gayatri mantra 108 times.", mantraSanskrit: "Om Mahalakshmyai Cha Vidmahe Vishnu Patnyai Cha Dheemahi Tanno Lakshmihi Prachodayaat", mantraTransliteration: "Om Ma-ha-lak-shm-yai Cha Vid-ma-he Vish-nu Pat-nyai Cha Dhee-ma-hi Tan-no Lak-shmi-hi Pra-cho-da-yaat", mantraMeaning: "We meditate on Mahalakshmi, wife of Vishnu. May Lakshmi illuminate our minds.", timerDurationSeconds: 600)
            ],
            ingredients: [
                DIYPoojaIngredient(id: "diy_003_i1", name: "Lotus or Rose Flowers", quantity: "11 flowers", category: .flowers, isOptional: false),
                DIYPoojaIngredient(id: "diy_003_i2", name: "Kumkum", quantity: "1 packet", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_003_i3", name: "Turmeric Powder", quantity: "50g", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_003_i4", name: "Rice (Akshat)", quantity: "250g", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_003_i5", name: "Ghee Lamp", quantity: "2 diyas", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_003_i6", name: "Coins", quantity: "Few pieces", category: .special, isOptional: true)
            ]
        ),
        DIYPooja(
            id: "diy_004",
            name: "Hanuman Pooja",
            description: "Worship of Lord Hanuman for strength, courage, and protection",
            deity: "Lord Hanuman",
            deityDescription: "Devotee of Lord Rama, symbol of strength, devotion, and selfless service",
            significance: "Hanuman Pooja grants strength and courage. Tuesday and Saturday are especially sacred. It protects against evil forces.",
            iconName: "bolt.fill",
            durationMinutes: 35,
            steps: [
                DIYPoojaStep(id: "diy_004_s1", stepNumber: 1, title: "Dhyana (Meditation)", description: "Meditate on Hanuman's mighty form, flying across the ocean.", mantraSanskrit: "Manojavam Maarutatulyavegam Jitendriyam Buddhimataam Varishtham", mantraTransliteration: "Ma-no-ja-vam Maa-ru-ta-tul-ya-ve-gam Ji-ten-dri-yam Bud-dhi-ma-taam Va-rish-tham", mantraMeaning: "Swift as the mind, fast as the wind, master of senses, wisest among the wise", timerDurationSeconds: 120),
                DIYPoojaStep(id: "diy_004_s2", stepNumber: 2, title: "Apply Sindoor", description: "Apply sindoor (vermillion) to the Hanuman idol. This is his favorite offering.", mantraSanskrit: "Sinduuram Raktavarnaanam Icchaashakti Samanvitam", mantraTransliteration: "Sin-duu-ram Rak-ta-var-naa-nam Ic-chaa-shak-ti Sa-man-vi-tam", mantraMeaning: "I offer vermillion endowed with the power of will", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_004_s3", stepNumber: 3, title: "Offer Jasmine Oil", description: "Pour jasmine oil on the idol and apply it gently.", mantraSanskrit: "Aanjaneya Namastubhyam Hanumaan Pavanasuta", mantraTransliteration: "Aan-ja-ne-ya Na-mas-tub-hyam Ha-nu-maan Pa-va-na-su-ta", mantraMeaning: "Salutations to Anjaneya, son of the wind god", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_004_s4", stepNumber: 4, title: "Offer Jaggery and Chana", description: "Place jaggery and roasted chana (chickpeas) as prasad.", mantraSanskrit: "Naivedyam Gruhyataam Deva Bhaktim Me Achalam Kuru", mantraTransliteration: "Nai-ved-yam Gruh-ya-taam De-va Bhak-tim Me A-cha-lam Ku-ru", mantraMeaning: "Accept this offering, O Lord, and make my devotion unwavering", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_004_s5", stepNumber: 5, title: "Hanuman Chalisa", description: "Recite the Hanuman Chalisa with devotion. This is the most powerful Hanuman prayer.", mantraSanskrit: "Shri Guru Charan Saroj Raj Nij Manu Mukuru Sudhaari", mantraTransliteration: "Shri Gu-ru Cha-ran Sa-roj Raj Nij Ma-nu Mu-ku-ru Su-dhaa-ri", mantraMeaning: "Cleansing the mirror of my mind with the dust of the guru's lotus feet", timerDurationSeconds: 600),
                DIYPoojaStep(id: "diy_004_s6", stepNumber: 6, title: "Aarti", description: "Light camphor and perform aarti to Lord Hanuman.", mantraSanskrit: "Aarti Keeje Hanuman Lala Ki", mantraTransliteration: "Aa-rti Kee-je Ha-nu-man La-la Ki", mantraMeaning: "Perform aarti for beloved Hanuman", timerDurationSeconds: 180)
            ],
            ingredients: [
                DIYPoojaIngredient(id: "diy_004_i1", name: "Sindoor (Vermillion)", quantity: "1 packet", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_004_i2", name: "Jasmine Oil", quantity: "50ml", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_004_i3", name: "Jaggery", quantity: "100g", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_004_i4", name: "Roasted Chana", quantity: "100g", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_004_i5", name: "Camphor", quantity: "5 pieces", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_004_i6", name: "Red Flowers", quantity: "11 flowers", category: .flowers, isOptional: true)
            ]
        ),
        DIYPooja(
            id: "diy_005",
            name: "Saraswati Pooja",
            description: "Worship of Goddess Saraswati for knowledge, wisdom, and arts",
            deity: "Goddess Saraswati",
            deityDescription: "Goddess of knowledge, music, arts, and learning",
            significance: "Saraswati Pooja enhances learning and creativity. It is performed during Vasant Panchami and before exams or creative endeavors.",
            iconName: "book.fill",
            durationMinutes: 35,
            steps: [
                DIYPoojaStep(id: "diy_005_s1", stepNumber: 1, title: "Dhyana (Meditation)", description: "Meditate on Goddess Saraswati in white, holding a veena and sacred texts.", mantraSanskrit: "Yaa Kundendu Tushaara Haara Dhavalaa Yaa Shubhra Vastravrita", mantraTransliteration: "Yaa Kun-den-du Tu-shaa-ra Haa-ra Dha-va-laa Yaa Shub-hra Vas-tra-vri-ta", mantraMeaning: "She who is white as jasmine, moon, and snow, clad in white garments", timerDurationSeconds: 120),
                DIYPoojaStep(id: "diy_005_s2", stepNumber: 2, title: "Place Books and Instruments", description: "Place your books, pens, or musical instruments near the altar for blessing.", mantraSanskrit: "Saraswati Namastubhyam Varade Kaamaroopini", mantraTransliteration: "Sa-ras-wa-ti Na-mas-tub-hyam Va-ra-de Kaa-ma-roo-pi-ni", mantraMeaning: "Salutations to Saraswati, the giver of boons", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_005_s3", stepNumber: 3, title: "Offer White Flowers", description: "Offer white flowers, especially jasmine, to the Goddess.", mantraSanskrit: "Pushpaanjali Samarppayaami Shri Saraswatyai Namaha", mantraTransliteration: "Push-paan-ja-li Sa-mar-ppa-yaa-mi Shri Sa-ras-wat-yai Na-ma-ha", mantraMeaning: "I offer these flowers to Goddess Saraswati", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_005_s4", stepNumber: 4, title: "Aksharabhyasam", description: "Write Om or the first letters of the alphabet on rice spread on a plate.", mantraSanskrit: "Om Aim Saraswatyai Namaha", mantraTransliteration: "Om Aim Sa-ras-wat-yai Na-ma-ha", mantraMeaning: "Salutations to Goddess Saraswati with the seed syllable Aim", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_005_s5", stepNumber: 5, title: "Saraswati Aarti", description: "Light the lamp and perform aarti to the Goddess.", mantraSanskrit: "Om Jai Saraswati Maata Maiyaa Jai Saraswati Maata", mantraTransliteration: "Om Jai Sa-ras-wa-ti Maa-ta Mai-yaa Jai Sa-ras-wa-ti Maa-ta", mantraMeaning: "Victory to Mother Saraswati", timerDurationSeconds: 180),
                DIYPoojaStep(id: "diy_005_s6", stepNumber: 6, title: "Gayatri Mantra", description: "Chant the Saraswati Gayatri mantra 108 times.", mantraSanskrit: "Om Saraswatyai Cha Vidmahe Brahmaputryai Cha Dheemahi Tanno Saraswati Prachodayaat", mantraTransliteration: "Om Sa-ras-wat-yai Cha Vid-ma-he Brah-ma-put-ryai Cha Dhee-ma-hi Tan-no Sa-ras-wa-ti Pra-cho-da-yaat", mantraMeaning: "We meditate on Saraswati, daughter of Brahma. May she illuminate our minds.", timerDurationSeconds: 600)
            ],
            ingredients: [
                DIYPoojaIngredient(id: "diy_005_i1", name: "White Flowers", quantity: "11 flowers", category: .flowers, isOptional: false),
                DIYPoojaIngredient(id: "diy_005_i2", name: "Honey", quantity: "2 tbsp", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_005_i3", name: "Fruits", quantity: "3 pieces", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_005_i4", name: "Rice", quantity: "250g", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_005_i5", name: "Ghee Lamp", quantity: "1 diya", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_005_i6", name: "Yellow Flowers", quantity: "5 flowers", category: .flowers, isOptional: true)
            ]
        ),
        DIYPooja(
            id: "diy_006",
            name: "Durga Pooja",
            description: "Worship of Goddess Durga for protection, power, and victory over evil",
            deity: "Goddess Durga",
            deityDescription: "The invincible warrior goddess who destroys evil and protects the righteous",
            significance: "Durga Pooja invokes the divine feminine power for protection and strength. Navaratri is the most sacred time for this worship.",
            iconName: "shield.fill",
            durationMinutes: 50,
            steps: [
                DIYPoojaStep(id: "diy_006_s1", stepNumber: 1, title: "Dhyana (Meditation)", description: "Meditate on Goddess Durga riding a lion, wielding divine weapons.", mantraSanskrit: "Yaa Devi Sarvabhooteshu Shakti Roopena Samsthitaa", mantraTransliteration: "Yaa De-vi Sar-va-bhoo-te-shu Shak-ti Roo-pe-na Sam-sthi-taa", mantraMeaning: "The Goddess who resides in all beings as power", timerDurationSeconds: 120),
                DIYPoojaStep(id: "diy_006_s2", stepNumber: 2, title: "Kalash Sthapana", description: "Set up a sacred water pot with mango leaves and a coconut on top.", mantraSanskrit: "Om Durgaayai Namaha Kalasham Sthaapayaami", mantraTransliteration: "Om Dur-gaa-yai Na-ma-ha Ka-la-sham Sthaa-pa-yaa-mi", mantraMeaning: "Salutations to Durga, I establish this sacred pot", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_006_s3", stepNumber: 3, title: "Offer Red Flowers", description: "Offer red hibiscus flowers and red cloth to the Goddess.", mantraSanskrit: "Pushpaanjali Samarppayaami Shri Durgaayai Namaha", mantraTransliteration: "Push-paan-ja-li Sa-mar-ppa-yaa-mi Shri Dur-gaa-yai Na-ma-ha", mantraMeaning: "I offer these flowers to Goddess Durga", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_006_s4", stepNumber: 4, title: "Apply Sindoor", description: "Apply sindoor to the deity image and offer kumkum.", mantraSanskrit: "Sinduuram Sowbhaagya Daayakam", mantraTransliteration: "Sin-duu-ram Sow-bhaag-ya Daa-ya-kam", mantraMeaning: "Sindoor, the giver of good fortune", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_006_s5", stepNumber: 5, title: "Durga Aarti", description: "Light the lamp and perform aarti to Goddess Durga.", mantraSanskrit: "Jai Ambe Gauri Maiyaa Jai Shyaamaa Gauri", mantraTransliteration: "Jai Am-be Gau-ri Mai-yaa Jai Shyaa-maa Gau-ri", mantraMeaning: "Victory to Mother Ambe Gauri", timerDurationSeconds: 180),
                DIYPoojaStep(id: "diy_006_s6", stepNumber: 6, title: "Durga Mantra Chanting", description: "Chant the Durga mantra 108 times.", mantraSanskrit: "Om Dum Durgaayai Namaha", mantraTransliteration: "Om Dum Dur-gaa-yai Na-ma-ha", mantraMeaning: "Salutations to Goddess Durga", timerDurationSeconds: 600),
                DIYPoojaStep(id: "diy_006_s7", stepNumber: 7, title: "Naivedyam (Offering)", description: "Offer fruits, sweets, and halwa as prasad to the Goddess.", mantraSanskrit: "Naivedyam Samarpayaami Om Shri Durgaayai Namaha", mantraTransliteration: "Nai-ved-yam Sa-mar-pa-yaa-mi Om Shri Dur-gaa-yai Na-ma-ha", mantraMeaning: "I offer this food to Goddess Durga", timerDurationSeconds: nil),
                DIYPoojaStep(id: "diy_006_s8", stepNumber: 8, title: "Prarthana (Prayer)", description: "Pray for protection and strength with folded hands.", mantraSanskrit: "Sarva Mangala Maangalye Shive Sarvaartha Saadhike Sharanye Tryambake Gauri Naaraayani Namostute", mantraTransliteration: "Sar-va Man-ga-la Maan-gal-ye Shi-ve Sar-vaar-tha Saa-dhi-ke Sha-ran-ye Try-am-ba-ke Gau-ri Naa-raa-ya-ni Na-mos-tu-te", mantraMeaning: "O auspicious Goddess who fulfills all desires, I bow to you", timerDurationSeconds: nil)
            ],
            ingredients: [
                DIYPoojaIngredient(id: "diy_006_i1", name: "Red Hibiscus Flowers", quantity: "21 flowers", category: .flowers, isOptional: false),
                DIYPoojaIngredient(id: "diy_006_i2", name: "Sindoor", quantity: "1 packet", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_006_i3", name: "Kumkum", quantity: "1 packet", category: .essential, isOptional: false),
                DIYPoojaIngredient(id: "diy_006_i4", name: "Coconut", quantity: "1 whole", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_006_i5", name: "Halwa or Sweets", quantity: "250g", category: .offering, isOptional: false),
                DIYPoojaIngredient(id: "diy_006_i6", name: "Red Cloth", quantity: "1 piece", category: .special, isOptional: true),
                DIYPoojaIngredient(id: "diy_006_i7", name: "Ghee Lamp", quantity: "1 diya", category: .essential, isOptional: false)
            ]
        )
    ]
}

struct DIYPoojaStep: Codable, Identifiable {
    let id: String
    let stepNumber: Int
    let title: String
    let description: String
    let mantraSanskrit: String?
    let mantraTransliteration: String?
    let mantraMeaning: String?
    let timerDurationSeconds: Int?
}

struct DIYPoojaIngredient: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: String
    let category: IngredientCategory
    let isOptional: Bool
}

// MARK: - Panchang Models

struct PanchangData: Codable {
    let tithi: String
    let nakshatra: String
    let yoga: String
    let karana: String
}

// MARK: - Vedic Library Models

struct VedicCategory: Codable, Identifiable {
    let id: String
    let name: String
    let iconName: String
    let entryCount: Int

    static let samples: [VedicCategory] = [
        VedicCategory(id: "vc_001", name: "Dharma", iconName: "scale.3d", entryCount: 10),
        VedicCategory(id: "vc_002", name: "Karma", iconName: "arrow.triangle.2.circlepath", entryCount: 8),
        VedicCategory(id: "vc_003", name: "Rituals", iconName: "flame.fill", entryCount: 8),
        VedicCategory(id: "vc_004", name: "Planets", iconName: "moon.stars.fill", entryCount: 9),
        VedicCategory(id: "vc_005", name: "Deities", iconName: "sparkles", entryCount: 9),
        VedicCategory(id: "vc_006", name: "Life Events", iconName: "calendar.badge.clock", entryCount: 6)
    ]
}

struct VedicEntry: Codable, Identifiable, Hashable {
    static func == (lhs: VedicEntry, rhs: VedicEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let category: String
    let title: String
    let sanskritText: String?
    let transliteration: String?
    let translation: String
    let source: String?
    let tags: [String]
}

// MARK: - API Response Wrappers

struct MuhuratResponse: Codable {
    let muhurats: [Muhurat]
    let panchang: PanchangData
}

struct VedicLibraryResponse: Codable {
    let categories: [VedicCategory]
    let entries: [VedicEntry]
}

struct DIYPoojasResponse: Codable {
    let poojas: [DIYPooja]
}
