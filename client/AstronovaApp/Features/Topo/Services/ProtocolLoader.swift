import Foundation

enum ProtocolLoaderError: Error {
    case resourceMissing
    case decodeFailed(Error)
}

struct ProtocolLoader {
    static let shared = ProtocolLoader()

    func load() throws -> [PauseProtocol] {
        guard let url = Bundle.main.url(forResource: "protocols", withExtension: "json") else {
            throw ProtocolLoaderError.resourceMissing
        }
        let data = try Data(contentsOf: url)
        do {
            let bundle = try JSONDecoder().decode(PauseProtocolBundle.self, from: data)
            return bundle.protocols
        } catch {
            throw ProtocolLoaderError.decodeFailed(error)
        }
    }
}
