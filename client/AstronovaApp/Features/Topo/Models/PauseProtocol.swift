import Foundation

struct PauseProtocolBundle: Decodable {
    let version: Int
    let protocols: [PauseProtocol]
}

struct PauseProtocol: Decodable, Identifiable {
    let id: String
    let emotion: String
    let emoji: String
    let planet: String
    let planetVedic: String
    let colorHint: String
    let vedicCorrespondence: String
    let energyIsFor: String
    let steps: [PauseStep]
    let doNot: [String]
    let doNotWindowMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id, emotion, emoji, planet, steps
        case planetVedic = "planet_vedic"
        case colorHint = "color_hint"
        case vedicCorrespondence = "vedic_correspondence"
        case energyIsFor = "energy_is_for"
        case doNot = "do_not"
        case doNotWindowMinutes = "do_not_window_minutes"
    }
}

struct PauseStep: Decodable, Identifiable {
    let index: Int
    let title: String
    let durationSeconds: Int
    let body: String
    let options: [PauseStepOption]?
    let breath: PauseBreath?

    var id: Int { index }

    enum CodingKeys: String, CodingKey {
        case index, title, body, options, breath
        case durationSeconds = "duration_seconds"
    }
}

struct PauseStepOption: Decodable, Identifiable {
    let condition: String?
    let action: String?
    let label: String?

    var id: String { (condition ?? "") + (label ?? "") }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self.label = str
            self.condition = nil
            self.action = nil
        } else {
            let keyed = try decoder.container(keyedBy: CodingKeys.self)
            self.condition = try keyed.decodeIfPresent(String.self, forKey: .condition)
            self.action = try keyed.decodeIfPresent(String.self, forKey: .action)
            self.label = nil
        }
    }

    enum CodingKeys: String, CodingKey { case condition, action }
}

struct PauseBreath: Decodable {
    let inhale: Int
    let hold: Int?
    let exhale: Int
    let rounds: Int
    let exhaleSound: String?

    enum CodingKeys: String, CodingKey {
        case inhale, hold, exhale, rounds
        case exhaleSound = "exhale_sound"
    }
}
