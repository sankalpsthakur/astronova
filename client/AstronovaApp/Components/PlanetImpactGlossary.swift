import SwiftUI

struct PlanetImpact: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let summary: String
    let keywords: [String]
    let strengths: [String]
    let cautions: [String]
}

enum PlanetImpacts {
    static let all: [PlanetImpact] = [
        .init(
            name: "Sun",
            symbol: "☉",
            summary: "Identity, vitality, leadership, purpose.",
            keywords: ["identity","vitality","authority","ego","purpose"],
            strengths: ["Lead with clarity","Express purpose","Shine in visibility"],
            cautions: ["Avoid ego battles","Don’t overexert","Watch burnout"]
        ),
        .init(
            name: "Moon",
            symbol: "☽",
            summary: "Emotions, intuition, home, needs.",
            keywords: ["emotion","intuition","nurture","home","needs"],
            strengths: ["Listen to feelings","Create safety","Nurture bonds"],
            cautions: ["Mood reactivity","Overprotective","Clinginess"]
        ),
        .init(
            name: "Mars",
            symbol: "♂",
            summary: "Drive, action, courage, will.",
            keywords: ["action","assert","courage","desire","heat"],
            strengths: ["Start decisively","Train body","Defend boundaries"],
            cautions: ["Impulsiveness","Conflict-prone","Injury risk"]
        ),
        .init(
            name: "Mercury",
            symbol: "☿",
            summary: "Thinking, speech, learning, commerce.",
            keywords: ["mind","speech","learn","trade","logic"],
            strengths: ["Speak clearly","Study deeply","Refine systems"],
            cautions: ["Overthinking","Nitpicking","Scattered focus"]
        ),
        .init(
            name: "Jupiter",
            symbol: "♃",
            summary: "Growth, wisdom, generosity, faith.",
            keywords: ["growth","luck","wisdom","teaching","truth"],
            strengths: ["Share knowledge","Expand horizons","Trust abundance"],
            cautions: ["Overindulgence","Dogma","Overpromising"]
        ),
        .init(
            name: "Venus",
            symbol: "♀",
            summary: "Love, beauty, values, pleasure.",
            keywords: ["love","art","values","money","harmony"],
            strengths: ["Cultivate harmony","Invest in beauty","Value alignment"],
            cautions: ["People‑pleasing","Overspending","Complacency"]
        ),
        .init(
            name: "Saturn",
            symbol: "♄",
            summary: "Structure, mastery, patience, responsibility.",
            keywords: ["discipline","boundaries","time","work","karma"],
            strengths: ["Master the basics","Build durable systems","Own commitments"],
            cautions: ["Rigidness","Pessimism","Fear of failure"]
        ),
        .init(
            name: "Rahu",
            symbol: "☊",
            summary: "Ambition, innovation, obsession, disruption.",
            keywords: ["future","tech","hunger","risk","unconventional"],
            strengths: ["Embrace novelty","Hack constraints","Take bold bets"],
            cautions: ["Restlessness","Addiction","Cutting corners"]
        ),
        .init(
            name: "Ketu",
            symbol: "☋",
            summary: "Release, insight, spirituality, detachment.",
            keywords: ["past","insight","purify","minimal","soul"],
            strengths: ["Simplify","Meditate","Serve quietly"],
            cautions: ["Apathy","Isolation","Escapism"]
        )
    ]

    static func byName(_ name: String) -> PlanetImpact? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}

