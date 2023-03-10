enum AppIntentsTrackingType: String {
    case collectPayment = "collect_payment"
    case createOrder = "create_order"
}
extension WooAnalyticsEvent {
    enum AppIntents {
        private enum Key {
            static let type = "type"
        }

        static func shortcutWasOpened(with type: AppIntentsTrackingType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .appIntentShortcutOpened,
                              properties: [Key.type: type.rawValue])
        }
    }
}
