//
//  TempleModels.swift
//  AstronovaApp
//
//  Models for the Temple tab - Astrologers, Muhurat, Pooja, and Booking
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
            name: "Pandit Sharma",
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

struct Muhurat: Identifiable {
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

enum MuhuratQuality {
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

enum IngredientCategory {
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
