import Foundation

enum CurrencyManager {
    static func localeCurrency() -> String {
        if let savedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency") {
            return savedCurrency
        }

        return Locale.current.currency?.identifier ?? "USD"
    }

    static let marketCurrencies: [String: String] = [
        "IN": "INR",
        "US": "USD",
        "GB": "GBP",
        "EU": "EUR",
        "BR": "BRL",
        "MX": "MXN",
        "AE": "AED",
    ]

    static func formatPrice(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? "\(currencyCode) \(amount)"
    }
}
