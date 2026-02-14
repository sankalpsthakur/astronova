//
//  TempleModels.swift
//  AstronovaApp
//
//  Models for the Temple tab - Astrologers, Muhurat, Pooja, Booking,
//  Temple Bell, DIY Pooja, Vedic Library, and Panchang
//

import Foundation

// MARK: - Guide Models (Local/Sample)

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

    /// When this `Astrologer` is sourced from a real guide profile, `id` is the API guide ID.
    /// Sample astrologers use `ast_...` IDs and should not be passed to booking endpoints.
    var apiGuideId: String? {
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
    static func fromGuideProfile(_ guide: GuideProfile) -> Astrologer {
        let pricePerMinute = max(1, guide.pricePerSession / 30)
        return Astrologer(
            id: guide.id,
            name: guide.name,
            specialization: guide.primarySpecialization,
            experience: guide.experienceString,
            rating: guide.rating,
            reviewCount: guide.reviewCount,
            pricePerMinute: pricePerMinute,
            avatarURL: guide.avatarUrl,
            isOnline: guide.isAvailable,
            languages: guide.languages,
            expertise: guide.specializations
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

/// Guide profile from API
struct GuideProfile: Codable, Identifiable {
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

    var guideId: String? {
        panditId
    }

    var guideName: String? {
        panditName
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

    var guideId: String? {
        panditId
    }

    var guideName: String? {
        panditName
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
        VedicCategory(id: "vc_001", name: "Dharma", iconName: "scale.3d", entryCount: 8),
        VedicCategory(id: "vc_002", name: "Karma", iconName: "arrow.triangle.2.circlepath", entryCount: 8),
        VedicCategory(id: "vc_003", name: "Rituals", iconName: "flame.fill", entryCount: 8),
        VedicCategory(id: "vc_004", name: "Planets", iconName: "moon.stars.fill", entryCount: 9),
        VedicCategory(id: "vc_005", name: "Deities", iconName: "sparkles", entryCount: 8),
        VedicCategory(id: "vc_006", name: "Life Events", iconName: "calendar.badge.clock", entryCount: 8)
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

    static let samples: [VedicEntry] = [
        // MARK: Dharma
        VedicEntry(
            id: "ve_001", category: "Dharma",
            title: "Right to Action, Not Fruits",
            sanskritText: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन । मा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि ॥",
            transliteration: "karmaṇy evādhikāras te mā phaleṣu kadācana | mā karma-phala-hetur bhūr mā te saṅgo 'stv akarmaṇi ||",
            translation: "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself the cause of the results, and never be attached to inaction.",
            source: "Bhagavad Gita 2.47",
            tags: ["dharma", "duty", "gita", "nishkama-karma"]
        ),
        VedicEntry(
            id: "ve_002", category: "Dharma",
            title: "Dharma Protects the Righteous",
            sanskritText: "धर्म एव हतो हन्ति धर्मो रक्षति रक्षितः । तस्माद्धर्मो न हन्तव्यो मा नो धर्मो हतोऽवधीत् ॥",
            transliteration: "dharma eva hato hanti dharmo rakṣati rakṣitaḥ | tasmād dharmo na hantavyo mā no dharmo hato 'vadhīt ||",
            translation: "Dharma destroys those who destroy it; dharma protects those who protect it. Therefore dharma should never be violated, lest violated dharma destroy us.",
            source: "Manusmriti 8.15",
            tags: ["dharma", "righteousness", "manu", "protection"]
        ),
        VedicEntry(
            id: "ve_003", category: "Dharma",
            title: "The Self Is Not the Slayer",
            sanskritText: "न जायते म्रियते वा कदाचिन्नायं भूत्वा भविता वा न भूयः । अजो नित्यः शाश्वतोऽयं पुराणो न हन्यते हन्यमाने शरीरे ॥",
            transliteration: "na jāyate mriyate vā kadācin nāyaṃ bhūtvā bhavitā vā na bhūyaḥ | ajo nityaḥ śāśvato 'yaṃ purāṇo na hanyate hanyamāne śarīre ||",
            translation: "The soul is never born nor does it die; nor having once existed, does it ever cease to be. Unborn, eternal, ever-existing, and primeval -- it is not slain when the body is slain.",
            source: "Bhagavad Gita 2.20",
            tags: ["dharma", "atman", "soul", "gita", "immortality"]
        ),
        VedicEntry(
            id: "ve_004", category: "Dharma",
            title: "Isha Upanishad -- The Lord Pervades All",
            sanskritText: "ईशा वास्यमिदं सर्वं यत्किञ्च जगत्यां जगत् । तेन त्यक्तेन भुञ्जीथा मा गृधः कस्यस्विद्धनम् ॥",
            transliteration: "īśā vāsyam idaṃ sarvaṃ yat kiñca jagatyāṃ jagat | tena tyaktena bhuñjīthā mā gṛdhaḥ kasya svid dhanam ||",
            translation: "All this -- whatever moves in this moving world -- is pervaded by the Lord. Enjoy through renunciation. Do not covet, for whose is wealth?",
            source: "Isha Upanishad 1",
            tags: ["dharma", "upanishad", "renunciation", "ishavasyam"]
        ),
        VedicEntry(
            id: "ve_024", category: "Dharma",
            title: "Speak Truth, Walk the Dharma",
            sanskritText: "सत्यं वद । धर्मं चर । स्वाध्यायान्मा प्रमदः ।",
            transliteration: "satyaṃ vada | dharmaṃ cara | svādhyāyān mā pramadaḥ |",
            translation: "Speak the truth. Practice dharma. Never neglect self-study of the scriptures.",
            source: "Taittiriya Upanishad 1.11.1",
            tags: ["dharma", "truth", "upanishad", "taittiriya", "study"]
        ),
        VedicEntry(
            id: "ve_025", category: "Dharma",
            title: "One's Own Dharma Is Supreme",
            sanskritText: "श्रेयान्स्वधर्मो विगुणः परधर्मात्स्वनुष्ठितात् । स्वधर्मे निधनं श्रेयः परधर्मो भयावहः ॥",
            transliteration: "śreyān sva-dharmo viguṇaḥ para-dharmāt sv-anuṣṭhitāt | sva-dharme nidhanaṃ śreyaḥ para-dharmo bhayāvahaḥ ||",
            translation: "Better is one's own dharma, though imperfectly performed, than the dharma of another well performed. Death in one's own dharma is preferable; the dharma of another invites danger.",
            source: "Bhagavad Gita 3.35",
            tags: ["dharma", "svadharma", "gita", "duty"]
        ),
        VedicEntry(
            id: "ve_026", category: "Dharma",
            title: "Surrender to the Supreme",
            sanskritText: "सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज । अहं त्वा सर्वपापेभ्यो मोक्षयिष्यामि मा शुचः ॥",
            transliteration: "sarva-dharmān parityajya mām ekaṃ śaraṇaṃ vraja | ahaṃ tvā sarva-pāpebhyo mokṣayiṣyāmi mā śucaḥ ||",
            translation: "Abandoning all varieties of dharma, surrender unto Me alone. I shall deliver you from all sinful reactions; do not grieve.",
            source: "Bhagavad Gita 18.66",
            tags: ["dharma", "surrender", "gita", "moksha", "sharanagati"]
        ),
        VedicEntry(
            id: "ve_027", category: "Dharma",
            title: "From Unreal to Real",
            sanskritText: "असतो मा सद्गमय । तमसो मा ज्योतिर्गमय । मृत्योर्मा अमृतं गमय ॥",
            transliteration: "asato mā sad gamaya | tamaso mā jyotir gamaya | mṛtyor mā amṛtaṃ gamaya ||",
            translation: "Lead me from the unreal to the real. Lead me from darkness to light. Lead me from death to immortality.",
            source: "Brihadaranyaka Upanishad 1.3.28",
            tags: ["dharma", "prayer", "upanishad", "brihadaranyaka", "light"]
        ),

        // MARK: Karma
        VedicEntry(
            id: "ve_005", category: "Karma",
            title: "Steadfast in Yoga, Perform Action",
            sanskritText: "योगस्थः कुरु कर्माणि सङ्गं त्यक्त्वा धनञ्जय । सिद्ध्यसिद्ध्योः समो भूत्वा समत्वं योग उच्यते ॥",
            transliteration: "yoga-sthaḥ kuru karmāṇi saṅgaṃ tyaktvā dhanañjaya | siddhy-asiddhyoḥ samo bhūtvā samatvaṃ yoga ucyate ||",
            translation: "Steadfast in yoga, O Arjuna, perform actions abandoning attachment, remaining even-minded in success and failure. Such equanimity is called yoga.",
            source: "Bhagavad Gita 2.48",
            tags: ["karma", "yoga", "equanimity", "gita", "detachment"]
        ),
        VedicEntry(
            id: "ve_006", category: "Karma",
            title: "Inaction in Action",
            sanskritText: "कर्मण्यकर्म यः पश्येदकर्मणि च कर्म यः । स बुद्धिमान्मनुष्येषु स युक्तः कृत्स्नकर्मकृत् ॥",
            transliteration: "karmaṇy akarma yaḥ paśyed akarmaṇi ca karma yaḥ | sa buddhimān manuṣyeṣu sa yuktaḥ kṛtsna-karma-kṛt ||",
            translation: "One who sees inaction in action, and action in inaction, is wise among all people; such a person is a yogi and has accomplished all action.",
            source: "Bhagavad Gita 4.18",
            tags: ["karma", "wisdom", "gita", "action", "jnana"]
        ),
        VedicEntry(
            id: "ve_007", category: "Karma",
            title: "The Three Gunas Drive All Action",
            sanskritText: "प्रकृतेः क्रियमाणानि गुणैः कर्माणि सर्वशः । अहङ्कारविमूढात्मा कर्ताहमिति मन्यते ॥",
            transliteration: "prakṛteḥ kriyamāṇāni guṇaiḥ karmāṇi sarvaśaḥ | ahaṅkāra-vimūḍhātmā kartāham iti manyate ||",
            translation: "All actions are performed by the three gunas of material nature. But one whose mind is deluded by egoism thinks: 'I am the doer.'",
            source: "Bhagavad Gita 3.27",
            tags: ["karma", "gunas", "prakriti", "ego", "gita"]
        ),
        VedicEntry(
            id: "ve_028", category: "Karma",
            title: "Work as Sacrifice",
            sanskritText: "यज्ञार्थात्कर्मणोऽन्यत्र लोकोऽयं कर्मबन्धनः । तदर्थं कर्म कौन्तेय मुक्तसङ्गः समाचर ॥",
            transliteration: "yajñārthāt karmaṇo 'nyatra loko 'yaṃ karma-bandhanaḥ | tad-arthaṃ karma kaunteya mukta-saṅgaḥ samācara ||",
            translation: "Work done as a sacrifice for the Supreme frees one from bondage. Otherwise, work binds one in this material world. O son of Kunti, perform your duties free from attachment.",
            source: "Bhagavad Gita 3.9",
            tags: ["karma", "yajna", "sacrifice", "gita", "nishkama"]
        ),
        VedicEntry(
            id: "ve_029", category: "Karma",
            title: "Untouched Like the Lotus Leaf",
            sanskritText: "ब्रह्मण्याधाय कर्माणि सङ्गं त्यक्त्वा करोति यः । लिप्यते न स पापेन पद्मपत्रमिवाम्भसा ॥",
            transliteration: "brahmaṇy ādhāya karmāṇi saṅgaṃ tyaktvā karoti yaḥ | lipyate na sa pāpena padma-patram ivāmbhasā ||",
            translation: "One who performs duty without attachment, surrendering results to the Supreme, is untouched by sin -- as a lotus leaf is untouched by water.",
            source: "Bhagavad Gita 5.10",
            tags: ["karma", "surrender", "lotus", "gita", "purity"]
        ),
        VedicEntry(
            id: "ve_030", category: "Karma",
            title: "The Storehouse of Karmic Impressions",
            sanskritText: "क्लेशमूलः कर्माशयो दृष्टादृष्टजन्मवेदनीयः ।",
            transliteration: "kleśa-mūlaḥ karma-āśayo dṛṣṭa-adṛṣṭa-janma-vedanīyaḥ |",
            translation: "The storehouse of karma has its root in the afflictions (kleshas) and is experienced in present and future births.",
            source: "Yoga Sutras of Patanjali 2.12",
            tags: ["karma", "yoga", "patanjali", "klesha", "samsara"]
        ),
        VedicEntry(
            id: "ve_049", category: "Karma",
            title: "As You Sow, So Shall You Reap",
            sanskritText: "यादृशं वपते बीजं तादृशं लभते फलम् ।",
            transliteration: "yādṛśaṃ vapate bījaṃ tādṛśaṃ labhate phalam |",
            translation: "As is the seed sown, so is the fruit reaped. Good actions yield good results; harmful actions yield suffering.",
            source: "Subhashita Ratna Bhandagara",
            tags: ["karma", "action", "consequence", "subhashita"]
        ),
        VedicEntry(
            id: "ve_031", category: "Karma",
            title: "The Deluded on the Path of Karma",
            sanskritText: "इष्टापूर्तं मन्यमानाः वरिष्ठं नान्यच्छ्रेयो वेदयन्ते प्रमूढाः ।",
            transliteration: "iṣṭā-pūrtaṃ manyamānāḥ variṣṭhaṃ nānyac chreyo vedayante pramūḍhāḥ |",
            translation: "The deluded, regarding ritual merit and charity as the highest good, do not know any higher truth. Having enjoyed their merit on the heights of heaven, they re-enter this world or a lower one.",
            source: "Mundaka Upanishad 1.2.10",
            tags: ["karma", "upanishad", "mundaka", "merit", "samsara"]
        ),

        // MARK: Rituals
        VedicEntry(
            id: "ve_008", category: "Rituals",
            title: "Gayatri Mantra",
            sanskritText: "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥",
            transliteration: "oṃ bhūr bhuvaḥ svaḥ tat savitur vareṇyaṃ bhargo devasya dhīmahi dhiyo yo naḥ pracodayāt ||",
            translation: "We meditate upon the divine light of the radiant Sun (Savitri); may that supreme light illuminate our intellect and guide our understanding.",
            source: "Rigveda 3.62.10",
            tags: ["ritual", "gayatri", "sandhya", "savitri", "mantra"]
        ),
        VedicEntry(
            id: "ve_009", category: "Rituals",
            title: "Agnihotra -- Offering to Fire",
            sanskritText: "अग्नये स्वाहा । इदमग्नये इदं न मम । प्रजापतये स्वाहा । इदं प्रजापतये इदं न मम ॥",
            transliteration: "agnaye svāhā | idam agnaye idaṃ na mama | prajāpataye svāhā | idaṃ prajāpataye idaṃ na mama ||",
            translation: "Svaha to Agni! This offering is for Agni, not for me. Svaha to Prajapati! This offering is for Prajapati, not for me. (The daily fire-oblation at sunrise and sunset.)",
            source: "Shatapatha Brahmana 12.4.1",
            tags: ["ritual", "agnihotra", "fire", "homa", "svaha"]
        ),
        VedicEntry(
            id: "ve_010", category: "Rituals",
            title: "Shanti Mantra -- Peace Invocation",
            sanskritText: "ॐ सह नाववतु सह नौ भुनक्तु सह वीर्यं करवावहै । तेजस्वि नावधीतमस्तु मा विद्विषावहै ॥ ॐ शान्तिः शान्तिः शान्तिः ॥",
            transliteration: "oṃ saha nāv avatu saha nau bhunaktu saha vīryaṃ karavāvahai | tejasvi nāv adhītam astu mā vidviṣāvahai || oṃ śāntiḥ śāntiḥ śāntiḥ ||",
            translation: "Om, may the Lord protect us both (teacher and student). May He nourish us both. May we work together with great vigor. May our study be brilliant. May we never quarrel. Om, peace, peace, peace.",
            source: "Taittiriya Upanishad 2.2 / Katha Upanishad invocation",
            tags: ["ritual", "shanti", "peace", "upanishad", "invocation"]
        ),
        VedicEntry(
            id: "ve_011", category: "Rituals",
            title: "Purusha Sukta -- Cosmic Sacrifice",
            sanskritText: "सहस्रशीर्षा पुरुषः सहस्राक्षः सहस्रपात् । स भूमिं विश्वतो वृत्वात्यतिष्ठद्दशाङ्गुलम् ॥",
            transliteration: "sahasra-śīrṣā puruṣaḥ sahasrākṣaḥ sahasra-pāt | sa bhūmiṃ viśvato vṛtvāty atiṣṭhad daśāṅgulam ||",
            translation: "The cosmic being (Purusha) has a thousand heads, a thousand eyes, and a thousand feet. He pervades the entire earth and extends beyond it by ten fingers' breadth.",
            source: "Rigveda 10.90.1",
            tags: ["ritual", "purusha-sukta", "creation", "cosmic", "rigveda"]
        ),
        VedicEntry(
            id: "ve_032", category: "Rituals",
            title: "Sri Suktam -- Hymn to Lakshmi",
            sanskritText: "हिरण्यवर्णां हरिणीं सुवर्णरजतस्रजाम् । चन्द्रां हिरण्मयीं लक्ष्मीं जातवेदो म आवह ॥",
            transliteration: "hiraṇya-varṇāṃ hariṇīṃ suvarṇa-rajata-srajām | candrāṃ hiraṇmayīṃ lakṣmīṃ jātavedo ma āvaha ||",
            translation: "O Jatavedas (Agni), bring to me Lakshmi who is of golden complexion, radiant as a deer, adorned with gold and silver garlands, lustrous as the moon, resplendent as gold.",
            source: "Sri Suktam 1 (Rigveda Khilani)",
            tags: ["ritual", "lakshmi", "suktam", "prosperity", "agni"]
        ),
        VedicEntry(
            id: "ve_033", category: "Rituals",
            title: "Rudram -- Homage to Rudra-Shiva",
            sanskritText: "ॐ नमस्ते रुद्र मन्यव उतो त इषवे नमः । नमस्ते अस्तु धन्वने बाहुभ्यामुत ते नमः ॥",
            transliteration: "oṃ namaste rudra manyava uto ta iṣave namaḥ | namaste astu dhanvane bāhubhyām uta te namaḥ ||",
            translation: "Salutations to you, O Rudra, to your wrath and to your arrow. Salutations to your bow and to your two arms.",
            source: "Krishna Yajurveda, Taittiriya Samhita 4.5.1",
            tags: ["ritual", "rudra", "shiva", "yajurveda", "namakam"]
        ),
        VedicEntry(
            id: "ve_034", category: "Rituals",
            title: "Aarti -- Waving of the Sacred Light",
            sanskritText: "ॐ जय जगदीश हरे स्वामी जय जगदीश हरे । भक्तजनों के संकट दास जनों के संकट क्षण में दूर करे ॥",
            transliteration: "oṃ jaya jagadīśa hare svāmī jaya jagadīśa hare | bhakta-janon ke saṅkaṭ dāsa-janon ke saṅkaṭ kṣaṇa men dūra kare ||",
            translation: "Victory to the Lord of the universe! O Master, you remove the sorrows of your devotees and servants in an instant.",
            source: "Om Jai Jagdish Hare (Shraddha Ram Phillauri, 1870)",
            tags: ["ritual", "aarti", "devotion", "lamp", "bhajan"]
        ),
        VedicEntry(
            id: "ve_035", category: "Rituals",
            title: "Shodasopachara Puja -- Sixteen-Step Worship",
            sanskritText: nil,
            transliteration: nil,
            translation: "The sixteen-step worship of a deity: avahana (invocation), asana (offering seat), padya (washing feet), arghya (water to hands), snana (bathing), vastra (clothing), yajnopavita (sacred thread), gandha (sandalwood paste), pushpa (flowers), dhupa (incense), dipa (lamp), naivedya (food), tambula (betel), namaskara (prostration), pradakshina (circumambulation), and visarjana (farewell).",
            source: "Agama Shastra / Puja Paddhati",
            tags: ["ritual", "puja", "worship", "sixteen", "upachara"]
        ),

        // MARK: Planets
        VedicEntry(
            id: "ve_012", category: "Planets",
            title: "Surya -- Aditya Hridayam",
            sanskritText: "ॐ मित्राय नमः । ॐ रवये नमः । ॐ सूर्याय नमः । ॐ भानवे नमः । ॐ खगाय नमः । ॐ पूष्णे नमः ।",
            transliteration: "oṃ mitrāya namaḥ | oṃ ravaye namaḥ | oṃ sūryāya namaḥ | oṃ bhānave namaḥ | oṃ khagāya namaḥ | oṃ pūṣṇe namaḥ |",
            translation: "Salutations to the Friend of all (Mitra). Salutations to the Shining One (Ravi). Salutations to the Impeller (Surya). Salutations to the Luminous (Bhanu). Salutations to the Sky-Mover (Khaga). Salutations to the Nourisher (Pushan). (The first six of the twelve Surya Namaskar mantras.)",
            source: "Surya Namaskar Mantras / Aditya Hridayam",
            tags: ["planets", "surya", "sun", "namaskar", "aditya"]
        ),
        VedicEntry(
            id: "ve_013", category: "Planets",
            title: "Chandra -- Moon Beeja Mantra",
            sanskritText: "ॐ श्रां श्रीं श्रौं सः चन्द्रमसे नमः ॥ दधिशङ्खतुषाराभं क्षीरोदार्णवसम्भवम् । नमामि शशिनं सोमं शम्भोर्मुकुटभूषणम् ॥",
            transliteration: "oṃ śrāṃ śrīṃ śrauṃ saḥ candramase namaḥ || dadhi-śaṅkha-tuṣārābhaṃ kṣīrodārṇava-sambhavam | namāmi śaśinaṃ somaṃ śambhor mukuṭa-bhūṣaṇam ||",
            translation: "Om, salutations to the Moon (beeja mantra). I bow to the Moon (Soma) who is white as curd, conch-shell, and snow, who rose from the ocean of milk, and who is the crest-jewel adorning Lord Shiva's crown.",
            source: "Navagraha Stotram 2",
            tags: ["planets", "chandra", "moon", "beeja", "navagraha"]
        ),
        VedicEntry(
            id: "ve_014", category: "Planets",
            title: "Mangala -- Mars Dhyana Shloka",
            sanskritText: "धरणीगर्भसम्भूतं विद्युत्कान्तिसमप्रभम् । कुमारं शक्तिहस्तं तं मङ्गलं प्रणमाम्यहम् ॥",
            transliteration: "dharaṇī-garbha-sambhūtaṃ vidyut-kānti-samaprabham | kumāraṃ śakti-hastaṃ taṃ maṅgalaṃ praṇamāmy aham ||",
            translation: "I bow to Mars (Mangala), born from the womb of the Earth, whose radiance equals that of lightning, who is youthful and holds a spear in his hand.",
            source: "Navagraha Stotram 3",
            tags: ["planets", "mangala", "mars", "navagraha", "stotram"]
        ),
        VedicEntry(
            id: "ve_015", category: "Planets",
            title: "Shani -- Saturn Dhyana Shloka",
            sanskritText: "नीलाञ्जनसमाभासं रविपुत्रं यमाग्रजम् । छायामार्तण्डसम्भूतं तं नमामि शनैश्चरम् ॥",
            transliteration: "nīlāñjana-samābhāsaṃ ravi-putraṃ yamāgrajam | chāyā-mārtāṇḍa-sambhūtaṃ taṃ namāmi śanaiścaram ||",
            translation: "I bow to Saturn (Shani), who is dark as blue collyrium, the son of the Sun and elder brother of Yama, born of Chaya and the Sun god -- the slow-moving one.",
            source: "Navagraha Stotram 7",
            tags: ["planets", "shani", "saturn", "navagraha", "stotram"]
        ),
        VedicEntry(
            id: "ve_036", category: "Planets",
            title: "Budha -- Mercury Dhyana Shloka",
            sanskritText: "प्रियङ्गुकल्पकश्यामं रूपेणाप्रतिमं बुधम् । सौम्यं सौम्यगुणोपेतं तं बुधं प्रणमाम्यहम् ॥",
            transliteration: "priyaṅgu-kalpa-kśyāmaṃ rūpeṇāpratimaṃ budham | saumyaṃ saumya-guṇopetaṃ taṃ budhaṃ praṇamāmy aham ||",
            translation: "I bow to Mercury (Budha), who is dark like the priyangu plant, of matchless beauty, gentle and endowed with gentle qualities -- the son of Soma (Moon).",
            source: "Navagraha Stotram 4",
            tags: ["planets", "budha", "mercury", "navagraha", "stotram"]
        ),
        VedicEntry(
            id: "ve_037", category: "Planets",
            title: "Guru -- Jupiter Dhyana Shloka",
            sanskritText: "देवानां च ऋषीणां च गुरुं काञ्चनसन्निभम् । बुद्धिभूतं त्रिलोकेशं तं नमामि बृहस्पतिम् ॥",
            transliteration: "devānāṃ ca ṛṣīṇāṃ ca guruṃ kāñcana-sannibham | buddhi-bhūtaṃ tri-lokeśaṃ taṃ namāmi bṛhaspatim ||",
            translation: "I bow to Jupiter (Brihaspati), the guru of gods and sages, who shines like gold, the embodiment of wisdom and lord of the three worlds.",
            source: "Navagraha Stotram 5",
            tags: ["planets", "guru", "jupiter", "brihaspati", "navagraha"]
        ),
        VedicEntry(
            id: "ve_038", category: "Planets",
            title: "Shukra -- Venus Dhyana Shloka",
            sanskritText: "हिमकुन्दमृणालाभं दैत्यानां परमं गुरुम् । सर्वशास्त्रप्रवक्तारं भार्गवं प्रणमाम्यहम् ॥",
            transliteration: "hima-kunda-mṛṇālābhaṃ daityānāṃ paramaṃ gurum | sarva-śāstra-pravaktāraṃ bhārgavaṃ praṇamāmy aham ||",
            translation: "I bow to Venus (Shukra), who shines like snow, jasmine, and the lotus stem, the supreme guru of the demons (asuras), and the expounder of all scriptures.",
            source: "Navagraha Stotram 6",
            tags: ["planets", "shukra", "venus", "bhargava", "navagraha"]
        ),
        VedicEntry(
            id: "ve_039", category: "Planets",
            title: "Rahu -- Shadow Planet Dhyana Shloka",
            sanskritText: "अर्धकायं महावीर्यं चन्द्रादित्यविमर्दनम् । सिंहिकागर्भसम्भूतं तं राहुं प्रणमाम्यहम् ॥",
            transliteration: "ardha-kāyaṃ mahā-vīryaṃ candrāditya-vimardanam | siṃhikā-garbha-sambhūtaṃ taṃ rāhuṃ praṇamāmy aham ||",
            translation: "I bow to Rahu, the half-bodied one of immense power who eclipses the Sun and Moon, born from the womb of Simhika.",
            source: "Navagraha Stotram 8",
            tags: ["planets", "rahu", "eclipse", "shadow", "navagraha"]
        ),
        VedicEntry(
            id: "ve_040", category: "Planets",
            title: "Ketu -- The Comet's Blessing",
            sanskritText: "पलाशपुष्पसंकाशं तारकाग्रहमस्तकम् । रौद्रं रौद्रात्मकं घोरं तं केतुं प्रणमाम्यहम् ॥",
            transliteration: "palāśa-puṣpa-saṃkāśaṃ tārakā-graha-mastakam | raudraṃ raudrātmakaṃ ghoraṃ taṃ ketuṃ praṇamāmy aham ||",
            translation: "I bow to Ketu, who resembles the palasha flower, who is the head of stars and planets, fierce, of fierce nature, and terrifying -- the south lunar node that grants moksha.",
            source: "Navagraha Stotram 9",
            tags: ["planets", "ketu", "moksha", "shadow", "navagraha"]
        ),

        // MARK: Deities
        VedicEntry(
            id: "ve_016", category: "Deities",
            title: "Ganesha Vandana",
            sanskritText: "वक्रतुण्ड महाकाय सूर्यकोटिसमप्रभ । निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा ॥",
            transliteration: "vakratuṇḍa mahākāya sūryakoṭi-samaprabha | nirvighnaṃ kuru me deva sarva-kāryeṣu sarvadā ||",
            translation: "O Lord of the curved trunk and massive body, whose splendor equals a million suns -- grant me freedom from obstacles in all my undertakings, always.",
            source: "Mudgala Purana / Ganesha Stotram",
            tags: ["deity", "ganesha", "vandana", "obstacles", "invocation"]
        ),
        VedicEntry(
            id: "ve_017", category: "Deities",
            title: "Shiva Panchakshari Stotram",
            sanskritText: "नागेन्द्रहाराय त्रिलोचनाय भस्माङ्गरागाय महेश्वराय । नित्याय शुद्धाय दिगम्बराय तस्मै नकाराय नमः शिवाय ॥",
            transliteration: "nāgendra-hārāya trilocanāya bhasmāṅga-rāgāya maheśvarāya | nityāya śuddhāya digambarāya tasmai na-kārāya namaḥ śivāya ||",
            translation: "Salutations to Shiva -- who wears the king of serpents as a garland, who has three eyes, whose body is adorned with sacred ash, the great Lord, eternal, pure, and sky-clad. To Him, represented by the syllable 'na', I bow.",
            source: "Shiva Panchakshari Stotram (Adi Shankaracharya) v.1",
            tags: ["deity", "shiva", "panchakshari", "shankaracharya", "stotram"]
        ),
        VedicEntry(
            id: "ve_018", category: "Deities",
            title: "Vishnu Dvadasakshari Mantra",
            sanskritText: "ॐ नमो भगवते वासुदेवाय ॥ शान्ताकारं भुजगशयनं पद्मनाभं सुरेशं विश्वाधारं गगनसदृशं मेघवर्णं शुभाङ्गम् ।",
            transliteration: "oṃ namo bhagavate vāsudevāya || śāntākāraṃ bhujaga-śayanaṃ padma-nābhaṃ sureśaṃ viśvādhāraṃ gagana-sadṛśaṃ megha-varṇaṃ śubhāṅgam |",
            translation: "Om, salutations to Lord Vasudeva (the twelve-syllable liberation mantra). He whose form is peace, who reclines upon the serpent Shesha, from whose navel springs the lotus, Lord of the gods, support of the universe, vast as the sky, dark as a cloud, of auspicious body.",
            source: "Vishnu Dhyanam / Bhagavata Purana",
            tags: ["deity", "vishnu", "dvadasakshari", "vasudeva", "dhyanam"]
        ),
        VedicEntry(
            id: "ve_019", category: "Deities",
            title: "Devi Mahatmyam -- Salutations to the Goddess",
            sanskritText: "सर्वमङ्गलमाङ्गल्ये शिवे सर्वार्थसाधिके । शरण्ये त्र्यम्बके गौरि नारायणि नमोऽस्तु ते ॥",
            transliteration: "sarva-maṅgala-māṅgalye śive sarvārtha-sādhike | śaraṇye tryambake gauri nārāyaṇi namo 'stu te ||",
            translation: "Salutations to you, O Narayani, who are the auspiciousness of all that is auspicious, the consort of Shiva, the accomplisher of every purpose, the refuge of all, the three-eyed Gauri.",
            source: "Devi Mahatmyam 11.10 (Durga Saptashati)",
            tags: ["deity", "devi", "durga", "narayani", "shakti"]
        ),
        VedicEntry(
            id: "ve_041", category: "Deities",
            title: "Mahalakshmi Beeja Mantra",
            sanskritText: "ॐ श्रीं महालक्ष्म्यै नमः ॥",
            transliteration: "oṃ śrīṃ mahālakṣmyai namaḥ ||",
            translation: "Salutation to the great goddess Lakshmi. 'Shreem' is her seed syllable (beeja) representing abundance, beauty, and divine grace. Chanting attracts prosperity, harmony, and spiritual wealth.",
            source: "Lakshmi Tantra / Sri Suktam tradition",
            tags: ["deity", "lakshmi", "prosperity", "beeja", "mantra"]
        ),
        VedicEntry(
            id: "ve_042", category: "Deities",
            title: "Saraswati Vandana",
            sanskritText: "या कुन्देन्दुतुषारहारधवला या शुभ्रवस्त्रावृता । या वीणावरदण्डमण्डितकरा या श्वेतपद्मासना ॥",
            transliteration: "yā kundendu-tuṣāra-hāra-dhavalā yā śubhra-vastrāvṛtā | yā vīṇā-vara-daṇḍa-maṇḍita-karā yā śveta-padmāsanā ||",
            translation: "She who is white as the jasmine, the moon, and snow garlands, who is adorned in pure white garments, whose hands are graced by the veena, who is seated on a white lotus -- may that goddess Saraswati protect me.",
            source: "Saraswati Vandana / Padma Purana",
            tags: ["deity", "saraswati", "knowledge", "prayer", "vidya"]
        ),
        VedicEntry(
            id: "ve_043", category: "Deities",
            title: "Hanuman Chalisa -- Opening Verse",
            sanskritText: "श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि । बरनउँ रघुबर बिमल जसु जो दायकु फल चारि ॥",
            transliteration: "śrī guru carana saroja raja nija manu mukuru sudhāri | baranauṃ raghubara bimala jasu jo dāyaku phala cāri ||",
            translation: "Cleansing the mirror of my mind with the dust of my Guru's lotus feet, I describe the pure glory of Sri Rama, the best of the Raghu dynasty, who bestows the four fruits of life (dharma, artha, kama, moksha).",
            source: "Hanuman Chalisa (Goswami Tulsidas, 16th century)",
            tags: ["deity", "hanuman", "chalisa", "rama", "tulsidas"]
        ),
        VedicEntry(
            id: "ve_044", category: "Deities",
            title: "Mahamrityunjaya Mantra",
            sanskritText: "ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् । उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात् ॥",
            transliteration: "oṃ tryambakaṃ yajāmahe sugandhiṃ puṣṭi-vardhanam | urvārukam iva bandhanān mṛtyor mukṣīya māmṛtāt ||",
            translation: "We worship the three-eyed Lord Shiva who is fragrant and nourishes all beings. As a ripe cucumber is released from its vine, may He liberate us from death and grant us immortality.",
            source: "Rigveda 7.59.12 / Yajurveda 3.60",
            tags: ["deity", "shiva", "healing", "mrityunjaya", "mantra"]
        ),

        // MARK: - Life Events (8 entries)
        VedicEntry(
            id: "ve_045", category: "Life Events",
            title: "Jatakarma -- Birth Rites",
            sanskritText: nil,
            transliteration: nil,
            translation: "The first samskara, performed immediately after birth. The father touches honey and ghee to the newborn's lips with a gold ring while reciting Vedic mantras, invoking intelligence (medha) and long life (ayush). This ritual symbolizes welcoming the child into the world with divine blessings and the protection of Agni.",
            source: "Ashvalayana Grihya Sutra 1.15",
            tags: ["samskara", "birth", "jatakarma", "newborn"]
        ),
        VedicEntry(
            id: "ve_020", category: "Life Events",
            title: "Namakarana -- Naming Ceremony Mantra",
            sanskritText: "ॐ आयुष्मान् भव सौम्य नामाङ्कितोऽसि बालक । दीर्घायुष्यमस्तु ते सर्वदा शान्तिरस्तु ते ॥",
            transliteration: "oṃ āyuṣmān bhava saumya nāmāṅkito 'si bālaka | dīrghāyuṣyam astu te sarvadā śāntir astu te ||",
            translation: "Om, may you be blessed with long life, gentle child; you are now marked with your name. May longevity be yours and may peace be with you always.",
            source: "Paraskara Grihya Sutra 1.17",
            tags: ["samskara", "namakarana", "naming", "birth", "ceremony"]
        ),
        VedicEntry(
            id: "ve_046", category: "Life Events",
            title: "Annaprashana -- First Solid Food",
            sanskritText: nil,
            transliteration: nil,
            translation: "The ceremony of first feeding solid food to the infant, performed in the sixth month. Cooked rice mixed with ghee, honey, and curd is offered to the child while mantras are recited for health and nourishment. This samskara marks the transition from mother's milk to earthly sustenance and is celebrated with family and community.",
            source: "Ashvalayana Grihya Sutra 1.16",
            tags: ["samskara", "feeding", "infant", "annaprashana"]
        ),
        VedicEntry(
            id: "ve_047", category: "Life Events",
            title: "Vidyarambha -- Commencement of Learning",
            sanskritText: "ॐ नमो गणेशाय । ॐ नमः सरस्वत्यै ।",
            transliteration: "oṃ namo gaṇeśāya | oṃ namaḥ sarasvatyai |",
            translation: "The ceremony marking the beginning of formal education, typically at age five. The child writes their first letters -- usually 'Om' and the alphabet -- on a plate of rice grains, invoking Ganesha to remove obstacles and Saraswati to bestow wisdom. This ceremony often coincides with Vijayadashami.",
            source: "Regional Grihya traditions / Dharmasutras",
            tags: ["samskara", "education", "vidyarambha", "learning"]
        ),
        VedicEntry(
            id: "ve_021", category: "Life Events",
            title: "Upanayana -- Gayatri Initiation",
            sanskritText: "यथेदं भूम्या अधि पवित्रं शतधारम् । एवा शतधारं ब्रह्म पवित्रमस्तु ते ॥",
            transliteration: "yathedam bhūmyā adhi pavitraṃ śata-dhāram | evā śata-dhāraṃ brahma pavitram astu te ||",
            translation: "Just as this purifying stream flows upon the earth in a hundred streams, so may the purifying knowledge of Brahman flow to you in a hundred streams. (Spoken by the guru during sacred thread investiture.)",
            source: "Ashvalayana Grihya Sutra 1.20 / Taittiriya Aranyaka",
            tags: ["samskara", "upanayana", "thread", "gayatri", "initiation"]
        ),
        VedicEntry(
            id: "ve_048", category: "Life Events",
            title: "Samavartana -- Graduation Ceremony",
            sanskritText: nil,
            transliteration: nil,
            translation: "The ceremony marking the end of the student's Vedic education and return home from the guru's ashram. The student takes a ritual bath (snana), signifying the completion of studies, and is given permission to enter the householder stage (grihastha). The guru offers final blessings and the student offers guru-dakshina (gift to the teacher).",
            source: "Paraskara Grihya Sutra 2.6",
            tags: ["samskara", "graduation", "student", "grihastha"]
        ),
        VedicEntry(
            id: "ve_022", category: "Life Events",
            title: "Vivaha -- The Seven Steps (Saptapadi)",
            sanskritText: "सखा सप्तपदा भव । सखायौ सप्तपदा बभूव । सख्यं ते गमेयम् । सख्यात् ते मायोषम् । सख्यान्मे मयोष्ठाः ॥",
            transliteration: "sakhā saptapadā bhava | sakhāyau saptapadā babhūva | sakhyaṃ te gameyam | sakhyāt te māyoṣam | sakhyān me mayoṣṭhāḥ ||",
            translation: "With these seven steps, become my friend. Having taken seven steps together, we have become companions. May I attain your friendship. May I never part from your friendship. May your friendship never part from me.",
            source: "Rigveda 10.85.36 / Ashvalayana Grihya Sutra 1.7",
            tags: ["samskara", "vivaha", "marriage", "saptapadi", "rigveda"]
        ),
        VedicEntry(
            id: "ve_023", category: "Life Events",
            title: "Antyeshti -- Final Farewell Prayer",
            sanskritText: "वायुरनिलममृतमथेदं भस्मान्तं शरीरम् । ॐ क्रतो स्मर कृतं स्मर क्रतो स्मर कृतं स्मर ॥",
            transliteration: "vāyur anilam amṛtam athedaṃ bhasmāntaṃ śarīram | oṃ krato smara kṛtaṃ smara krato smara kṛtaṃ smara ||",
            translation: "Let the life-breath merge with the immortal wind; let this body end in ashes. Om, O mind, remember your deeds, remember! O mind, remember your deeds, remember!",
            source: "Isha Upanishad 17",
            tags: ["samskara", "antyeshti", "funeral", "death", "upanishad"]
        )
    ]
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
