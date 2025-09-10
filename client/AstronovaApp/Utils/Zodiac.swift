import Foundation

enum Zodiac {
    static func sign(for date: Date) -> String? {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.month, .day], from: date)
        guard let m = comps.month, let d = comps.day else { return nil }
        // Western tropical zodiac date ranges
        switch (m, d) {
        case (3,21...31), (4,1...19): return "Aries"
        case (4,20...30), (5,1...20): return "Taurus"
        case (5,21...31), (6,1...20): return "Gemini"
        case (6,21...30), (7,1...22): return "Cancer"
        case (7,23...31), (8,1...22): return "Leo"
        case (8,23...31), (9,1...22): return "Virgo"
        case (9,23...30), (10,1...22): return "Libra"
        case (10,23...31), (11,1...21): return "Scorpio"
        case (11,22...30), (12,1...21): return "Sagittarius"
        case (12,22...31), (1,1...19): return "Capricorn"
        case (1,20...31), (2,1...18): return "Aquarius"
        case (2,19...29), (3,1...20): return "Pisces"
        default: return nil
        }
    }
}

