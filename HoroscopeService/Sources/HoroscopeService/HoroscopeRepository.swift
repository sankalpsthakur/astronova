import Foundation
import Combine
import CloudKitKit
import DataModels
import AstroEngine

/// Repository for fetching and caching daily horoscopes.
public final class HoroscopeRepository: ObservableObject {
    @Published public private(set) var today: Horoscope?

    public init() {}

    /// Fetch today's horoscope for the given sign and language.
    public func fetchToday(sign: String, language: String) async throws {
        // TODO: implement core data cache lookup and CloudKit query
    }
}