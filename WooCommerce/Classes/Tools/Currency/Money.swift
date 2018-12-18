import Foundation

struct Money {
    enum Currency: String {
        case USD, EUR, GBP, CHY
    }

    var amount: Decimal
    var currency: Currency

    var symbol: String {
        switch currency {
        case .USD:
            return "$" // look up unicode character values?
        case .EUR:
            return "€"
        case .GBP:
            return "£"
        default:
            return currency.rawValue
        }
    }
}
