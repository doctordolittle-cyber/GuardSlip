import Foundation

struct CurrencyOption: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String

    var id: String { code }

    static let all: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyOption(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyOption(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyOption(code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia"),
        CurrencyOption(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyOption(code: "CNY", symbol: "¥", name: "Chinese Yuan"),
        CurrencyOption(code: "KRW", symbol: "₩", name: "Korean Won"),
        CurrencyOption(code: "INR", symbol: "₹", name: "Indian Rupee"),
        CurrencyOption(code: "TRY", symbol: "₺", name: "Turkish Lira"),
        CurrencyOption(code: "BRL", symbol: "R$", name: "Brazilian Real"),
        CurrencyOption(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        CurrencyOption(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        CurrencyOption(code: "CHF", symbol: "Fr", name: "Swiss Franc"),
    ]

    static func find(by code: String) -> CurrencyOption {
        all.first { $0.code == code } ?? all[0]
    }
}
