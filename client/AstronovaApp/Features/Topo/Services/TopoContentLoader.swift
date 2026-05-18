import Foundation

enum TopoContentError: Error, CustomStringConvertible {
    case resourceMissing(String)
    case decodeFailed(String, Error)

    var description: String {
        switch self {
        case .resourceMissing(let name): return "Missing bundled resource: \(name).json"
        case .decodeFailed(let name, let error): return "Failed to decode \(name).json: \(error)"
        }
    }
}

/// Single source of truth for loading TopoSelf JSON content bundled with the app.
final class TopoContentLoader {
    static let shared = TopoContentLoader()

    private(set) lazy var patterns: [Pattern] = {
        (try? loadBundle(PatternBundle.self, named: "patterns").patterns) ?? []
    }()

    private(set) lazy var consciousnessPlanets: [ConsciousnessPlanet] = {
        (try? loadBundle(ConsciousnessBundle.self, named: "consciousness-levels").planets) ?? []
    }()

    private(set) lazy var terrain: TerrainBundle? = {
        try? loadBundle(TerrainBundle.self, named: "terrain-templates")
    }()

    private(set) lazy var domains: [DomainMapping] = {
        (try? loadBundle(DomainBundle.self, named: "domain-mappings").domains) ?? []
    }()

    func pattern(id: String) -> Pattern? { patterns.first { $0.id == id } }
    func planet(id: String) -> ConsciousnessPlanet? { consciousnessPlanets.first { $0.id == id } }
    func domain(id: String) -> DomainMapping? { domains.first { $0.id == id } }
    func driver(id: String) -> TerrainDriver? { terrain?.drivers.first { $0.id == id } }

    private func loadBundle<T: Decodable>(_ type: T.Type, named: String) throws -> T {
        guard let url = Bundle.main.url(forResource: named, withExtension: "json") else {
            throw TopoContentError.resourceMissing(named)
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TopoContentError.decodeFailed(named, error)
        }
    }
}
