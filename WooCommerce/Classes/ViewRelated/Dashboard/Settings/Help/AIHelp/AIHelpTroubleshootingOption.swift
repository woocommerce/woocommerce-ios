import Foundation

/// Options presented to the user for selecting what they need help with.
///
enum AIHelpTroubleshootingOption: CaseIterable, Identifiable {
    case analytics
    case loadingOrders
    case orderNotifications
    case orderDetailsShipping
    case cardReaderIPP
    case loadingProducts
    case productImages
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .analytics:
            return Localization.analytics
        case .loadingOrders:
            return Localization.loadingOrders
        case .orderNotifications:
            return Localization.orderNotifications
        case .orderDetailsShipping:
            return Localization.orderDetailsShipping
        case .cardReaderIPP:
            return Localization.cardReaderIPP
        case .loadingProducts:
            return Localization.loadingProducts
        case .productImages:
            return Localization.productImages
        case .other:
            return Localization.other
        }
    }

    /// Whether the topic requires free-text input from the user.
    ///
    var requiresFreeText: Bool {
        switch self {
        case .orderDetailsShipping, .cardReaderIPP, .productImages, .other:
            return true
        case .analytics, .loadingOrders, .orderNotifications, .loadingProducts:
            return false
        }
    }
}

// MARK: - Localization
//
private extension AIHelpTroubleshootingOption {
    enum Localization {
        static let analytics = NSLocalizedString(
            "aiHelp.option.analytics",
            value: "Analytics",
            comment: "Help topic option for analytics issues"
        )
        static let loadingOrders = NSLocalizedString(
            "aiHelp.option.loadingOrders",
            value: "Loading Orders",
            comment: "Help topic option for order loading issues"
        )
        static let orderNotifications = NSLocalizedString(
            "aiHelp.option.orderNotifications",
            value: "Order Notifications",
            comment: "Help topic option for notification issues"
        )
        static let orderDetailsShipping = NSLocalizedString(
            "aiHelp.option.orderDetailsShipping",
            value: "Order Details / Shipping",
            comment: "Help topic option for order details and shipping issues"
        )
        static let cardReaderIPP = NSLocalizedString(
            "aiHelp.option.cardReaderIPP",
            value: "Card Reader / In-Person Payments",
            comment: "Help topic option for card reader and in-person payment issues"
        )
        static let loadingProducts = NSLocalizedString(
            "aiHelp.option.loadingProducts",
            value: "Loading Products",
            comment: "Help topic option for product loading issues"
        )
        static let productImages = NSLocalizedString(
            "aiHelp.option.productImages",
            value: "Load / Upload Product Images",
            comment: "Help topic option for product image issues"
        )
        static let other = NSLocalizedString(
            "aiHelp.option.other",
            value: "Others",
            comment: "Help topic option for other issues not covered by specific categories"
        )
    }
}
