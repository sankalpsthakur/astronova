import Foundation
import DataModels

/// Compares two birth datasets and produces a KundaliMatch result.
public final class MatchService {
    public init() {}

    /// Compare two birth-date/location combos and return a match score struct.
    public func compare(_ me: Any, with them: Any) -> KundaliMatch {
        fatalError("compare(_:with:) not implemented")
    }
}