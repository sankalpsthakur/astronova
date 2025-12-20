//
//  TempleModels.swift
//  AstronovaApp
//
//  Models for the Temple tab - Astrologers, Muhurat, and Pooja
//

import Foundation

// MARK: - Astrologer Models

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
