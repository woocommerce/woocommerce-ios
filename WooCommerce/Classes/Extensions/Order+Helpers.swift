import Foundation

extension Order {
    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: self.currency)
        guard let symbol = locale.displayName(forKey: NSLocale.Key.currencySymbol, value: self.currency) else {
            return ""
        }
        return symbol
    }

    func statusToString(_ status: OrderStatus) -> String {
        switch status {
        case .pending:
            return "pending"
        case .processing:
            return "processing"
        case .onHold:
            return "on hold"
        case .completed:
            return "completed"
        case .cancelled:
            return "cancelled"
        case .refunded:
            return "refunded"
        case .failed:
            return "failed"
        }
    }
}
