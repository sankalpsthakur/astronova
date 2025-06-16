import Foundation

// MARK: - Report Models

/// Report generation request
struct ReportRequest: Codable {
    let birthData: BirthData
    let reportType: String // "personality", "compatibility", "yearly"
    let options: ReportOptions?
}

/// Report generation options
struct ReportOptions: Codable {
    let includeTransits: Bool?
    let includeAspects: Bool?
    let language: String?
    let format: String? // "pdf", "text"
}

/// Report response
struct ReportResponse: Codable {
    let reportId: String
    let type: String
    let content: String
    let downloadUrl: String?
    let generatedAt: String
}

/// Detailed report request for premium insights
struct DetailedReportRequest: Codable {
    let birthData: BirthData
    let reportType: String // "love_forecast", "birth_chart", "career_forecast", "year_ahead"
    let options: [String: String]?
    let userId: String?
}

/// Detailed report response
struct DetailedReportResponse: Codable {
    let reportId: String
    let type: String
    let title: String
    let summary: String
    let keyInsights: [String]
    let downloadUrl: String
    let generatedAt: String
    let status: String
}

/// Complete detailed report data
struct DetailedReport: Codable {
    let reportId: String
    let type: String
    let title: String
    let content: String
    let summary: String
    let keyInsights: [String]
    let downloadUrl: String
    let generatedAt: String
    let userId: String?
    let status: String
}

/// User reports response
struct UserReportsResponse: Codable {
    let reports: [DetailedReport]
}

/// Report section structure
struct ReportSection: Codable {
    let title: String
    let content: String
    let category: String
}