import Foundation

extension Order {
    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: self.currency)
        guard let symbol = locale.displayName(forKey: .currencySymbol, value: self.currency) else {
            return ""
        }
        return symbol
    }
}
