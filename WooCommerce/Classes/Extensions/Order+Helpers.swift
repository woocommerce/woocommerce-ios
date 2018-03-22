import Foundation

extension Order {
    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: self.currency)
        return locale.displayName(forKey: .currencySymbol, value: self.currency) ?? String()
    }
}
