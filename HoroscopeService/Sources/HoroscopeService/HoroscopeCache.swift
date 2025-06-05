import Foundation
import DataModels

/// Simple file-based cache for daily horoscopes.
struct HoroscopeCache {
    private static let directory: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HoroscopeCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func fileURL(sign: String, date: Date, language: String) -> URL {
        let day = formatter.string(from: date)
        let name = "\(sign.lowercased())_\(day)_\(language).json"
        return directory.appendingPathComponent(name)
    }

    static func load(sign: String, date: Date, language: String) -> Horoscope? {
        let url = fileURL(sign: sign, date: date, language: language)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Horoscope.self, from: data)
    }

    static func save(_ horoscope: Horoscope) {
        let url = fileURL(sign: horoscope.sign, date: horoscope.date, language: horoscope.language)
        if let data = try? JSONEncoder().encode(horoscope) {
            try? data.write(to: url)
        }
    }
}
