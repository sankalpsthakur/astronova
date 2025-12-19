import Foundation

/// Request payload for `/api/v1/astrology/dashas/complete`.
struct DashaCompleteRequest: Encodable {
    struct BirthDataPayload: Codable {
        let date: String
        let time: String
        let timezone: String
        let latitude: Double
        let longitude: Double
    }

    let birthData: BirthDataPayload
    let targetDate: String?
    let includeTransitions: Bool
    let includeEducation: Bool

    init(
        birthData: BirthDataPayload,
        targetDate: String? = nil,
        includeTransitions: Bool = true,
        includeEducation: Bool = true
    ) {
        self.birthData = birthData
        self.targetDate = targetDate
        self.includeTransitions = includeTransitions
        self.includeEducation = includeEducation
    }
}

/// Response payload returned by `/api/v1/astrology/dashas/complete`.
struct DashaCompleteResponse: Codable {
    let dasha: DashaDetails
    let currentPeriod: CurrentPeriod
    let impactAnalysis: ImpactAnalysis
    let planetaryKeywords: PlanetaryKeywords
    let transitions: TransitionInfo?
    let education: EducationContent?

    enum CodingKeys: String, CodingKey {
        case dasha
        case currentPeriod = "current_period"
        case impactAnalysis = "impact_analysis"
        case planetaryKeywords = "planetary_keywords"
        case transitions
        case education
    }

    struct DashaDetails: Codable {
        let birthDate: String
        let targetDate: String
        let startingDasha: StartingDasha
        let mahadasha: Period
        let antardasha: Period?
        let pratyantardasha: Period?
        let allAntardashas: [Period]?
        let allPratyantardashas: [Period]?
        let upcomingMahadashas: [Period]?

        enum CodingKeys: String, CodingKey {
            case birthDate = "birth_date"
            case targetDate = "target_date"
            case startingDasha = "starting_dasha"
            case mahadasha
            case antardasha
            case pratyantardasha
            case allAntardashas = "all_antardashas"
            case allPratyantardashas = "all_pratyantardashas"
            case upcomingMahadashas = "upcoming_mahadashas"
        }

        struct StartingDasha: Codable {
            let lord: String
            let balanceYears: Double

            enum CodingKeys: String, CodingKey {
                case lord
                case balanceYears = "balance_years"
            }
        }

        struct Period: Codable {
            let lord: String
            let start: String
            let end: String
            let durationYears: Double?
            let durationMonths: Double?
            let durationDays: Double?

            enum CodingKeys: String, CodingKey {
                case lord
                case start
                case end
                case durationYears = "duration_years"
                case durationMonths = "duration_months"
                case durationDays = "duration_days"
            }
        }
    }

    struct CurrentPeriod: Codable {
        let mahadasha: DashaDetails.Period
        let antardasha: DashaDetails.Period?
        let pratyantardasha: DashaDetails.Period?
        let narrative: String
    }

    struct ImpactAnalysis: Codable {
        let mahadashaImpact: PeriodImpact
        let antardashaImpact: PeriodImpact
        let combinedScores: ImpactScores

        enum CodingKeys: String, CodingKey {
            case mahadashaImpact = "mahadasha_impact"
            case antardashaImpact = "antardasha_impact"
            case combinedScores = "combined_scores"
        }

        struct PeriodImpact: Codable {
            let lord: String
            let scores: ImpactScores
            let tone: String
            let toneDescription: String
            let strength: StrengthData

            enum CodingKeys: String, CodingKey {
                case lord
                case scores
                case tone
                case toneDescription = "tone_description"
                case strength
            }
        }

        struct StrengthData: Codable {
            let planet: String
            let overallScore: Double
            let strengthLabel: String
            let dignity: String
            let components: Components?

            enum CodingKeys: String, CodingKey {
                case planet
                case overallScore = "overall_score"
                case strengthLabel = "strength_label"
                case dignity
                case components
            }

            struct Components: Codable {
                let directional: Double?
                let positional: Positional?
                let temporal: Temporal?

                struct Positional: Codable {
                    let dignity: String?
                    let score: Double?
                    let factors: Factors?

                    struct Factors: Codable {
                        let debilitationComponent: Double?
                        let exaltationComponent: Double?

                        enum CodingKeys: String, CodingKey {
                            case debilitationComponent = "debilitation_component"
                            case exaltationComponent = "exaltation_component"
                        }
                    }

                    enum CodingKeys: String, CodingKey {
                        case dignity
                        case score
                        case factors
                    }
                }

                struct Temporal: Codable {
                    let dayNight: Double?
                    let retrograde: Double?

                    enum CodingKeys: String, CodingKey {
                        case dayNight = "day_night"
                        case retrograde
                    }
                }

                enum CodingKeys: String, CodingKey {
                    case directional
                    case positional
                    case temporal
                }
            }
        }
    }

    struct ImpactScores: Codable, Equatable {
        let career: Double
        let relationships: Double
        let health: Double
        let spiritual: Double
    }

    struct PlanetaryKeywords: Codable {
        let mahadasha: [String]
        let antardasha: [String]
    }

    struct TransitionInfo: Codable {
        let timing: Timing?
        let insights: Insights?
        let impactComparison: ImpactComparison?
        let nextKeywords: [String]?
        let nextLord: String?
        let preparationTips: [String]?
        let summary: String?
        let timeRemaining: String?

        enum CodingKeys: String, CodingKey {
            case timing
            case insights
            case impactComparison = "impact_comparison"
            case nextKeywords = "next_keywords"
            case nextLord = "next_lord"
            case preparationTips = "preparation_tips"
            case summary
            case timeRemaining = "time_remaining"
        }

        struct Timing: Codable {
            let mahadasha: PeriodTiming?
            let antardasha: PeriodTiming?
            let pratyantardasha: PeriodTiming?

            struct PeriodTiming: Codable {
                let currentLord: String?
                let nextLord: String?
                let endsOn: String?
                let daysRemaining: Int?
                let monthsRemaining: Double?
                let yearsRemaining: Double?

                enum CodingKeys: String, CodingKey {
                    case currentLord = "current_lord"
                    case nextLord = "next_lord"
                    case endsOn = "ends_on"
                    case daysRemaining = "days_remaining"
                    case monthsRemaining = "months_remaining"
                    case yearsRemaining = "years_remaining"
                }
            }
        }

        struct Insights: Codable {
            let currentKeywords: [String]?
            let currentLord: String?
            let daysUntil: Int?
            let impactComparison: ImpactComparison?
            let nextKeywords: [String]?
            let nextLord: String?
            let preparationTips: [String]?
            let summary: String?
            let timeRemaining: String?

            enum CodingKeys: String, CodingKey {
                case currentKeywords = "current_keywords"
                case currentLord = "current_lord"
                case daysUntil = "days_until"
                case impactComparison = "impact_comparison"
                case nextKeywords = "next_keywords"
                case nextLord = "next_lord"
                case preparationTips = "preparation_tips"
                case summary
                case timeRemaining = "time_remaining"
            }
        }
    }

    struct ImpactComparison: Codable {
        let current: ComparisonEntry
        let next: ComparisonEntry
        let deltas: ImpactScores?
        let majorShifts: [String]?
        let transitionSummary: String?

        enum CodingKeys: String, CodingKey {
            case current
            case next
            case deltas
            case majorShifts = "major_shifts"
            case transitionSummary = "transition_summary"
        }

        struct ComparisonEntry: Codable {
            let dashaLord: String
            let impactScores: ImpactScores
            let keywords: [String]
            let strength: ImpactAnalysis.StrengthData
            let tone: String
            let toneDescription: String

            enum CodingKeys: String, CodingKey {
                case dashaLord = "dasha_lord"
                case impactScores = "impact_scores"
                case keywords
                case strength
                case tone
                case toneDescription = "tone_description"
            }
        }
    }

    struct EducationContent: Codable {
        let mahadashaGuide: Guide?
        let antardashaGuide: Guide?
        let calculationExplanation: CalculationExplanation?

        enum CodingKeys: String, CodingKey {
            case mahadashaGuide = "mahadasha_guide"
            case antardashaGuide = "antardasha_guide"
            case calculationExplanation = "calculation_explanation"
        }

        struct Guide: Codable {
            let title: String
            let level: String
            let lord: String
            let duration: String?
            let overview: String?
            let advice: String?
            let keywords: [String]?
            let opportunities: [String]?
            let challenges: [String]?
            let typicalExperiences: [String]?

            enum CodingKeys: String, CodingKey {
                case title
                case level
                case lord
                case duration
                case overview
                case advice
                case keywords
                case opportunities
                case challenges
                case typicalExperiences = "typical_experiences"
            }
        }

        struct CalculationExplanation: Codable {
            let title: String?
            let moonLongitude: Double?
            let nakshatra: String?
            let nakshatraLord: String?
            let balanceYears: Double?
            let steps: [Step]?

            enum CodingKeys: String, CodingKey {
                case title
                case moonLongitude = "moon_longitude"
                case nakshatra
                case nakshatraLord = "nakshatra_lord"
                case balanceYears = "balance_years"
                case steps
            }

            struct Step: Codable {
                let step: Int
                let title: String
                let description: String
            }
        }
    }
}
