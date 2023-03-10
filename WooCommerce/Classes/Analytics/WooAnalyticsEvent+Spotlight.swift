import Foundation

extension WooActivityType {
    var trackingValue: String {
        let screen: String
        switch self {
        case .products:
            screen = "products"
        case .dashboard:
            screen = "dashboard"
        case .orders:
            screen = "orders"
        case .payments:
            screen = "payments"
        }

        return screen + "_screen"
    }
}

extension WooAnalyticsEvent {
    enum Spotlight {
        private enum Key {
            static let type = "type"
        }

        static func activityWasOpened(with type: WooActivityType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .spotlightActivityOpened,
                              properties: [Key.type: type.trackingValue])
        }
    }
}
