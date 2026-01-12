import Foundation

final class LocaleFormatter {
    static let shared = LocaleFormatter()

    private init() {}

    lazy var shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter
    }()

    lazy var percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    func currency(for currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current
        return formatter
    }

    var localeCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    func birthTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "jjmm", options: 0, locale: Locale.current)
        return formatter.string(from: date)
    }

    func timezoneName(_ timezone: TimeZone) -> String {
        timezone.localizedName(for: .generic, locale: Locale.current) ?? timezone.identifier
    }
}
