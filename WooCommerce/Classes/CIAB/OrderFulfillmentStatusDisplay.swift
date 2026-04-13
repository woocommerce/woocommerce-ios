import UIKit
import SwiftUI
import NetworkingCore

/// Centralizes the display properties (text and color) for `OrderFulfillmentStatus` badges.
///
/// Used by order list, dashboard, order details, and search screens to render
/// a consistent fulfillment badge for CIAB orders.
extension OrderFulfillmentStatus {

    /// Localized badge text, or `nil` if the status should not be displayed.
    ///
    /// - Parameter dateFulfilled: When provided and the status is `.fulfilled`,
    ///   the text includes the date (e.g., "Fulfilled on Jan 28, 2025").
    ///   Used in order details; pass `nil` for list/dashboard contexts.
    func badgeText(dateFulfilled: Date? = nil) -> String? {
        switch self {
        case .fulfilled:
            if let dateFulfilled {
                let formatter = DateFormatter.mediumLengthLocalizedDateFormatter
                formatter.timeZone = .siteTimezone
                let dateString = formatter.string(from: dateFulfilled)
                return String(format: Localization.fulfilledWithDate, dateString)
            }
            return Localization.fulfilled
        case .unfulfilled:
            return Localization.unfulfilled
        case .partiallyFulfilled, .noFulfillments, .unknown:
            return nil
        }
    }

    /// Background color for the fulfillment badge (UIKit).
    var badgeBackgroundColor: UIColor {
        switch self {
        case .fulfilled:
            return .withColorStudio(.green, shade: .shade5)
        case .unfulfilled:
            return .withColorStudio(.orange, shade: .shade5)
        case .partiallyFulfilled, .noFulfillments, .unknown:
            return .clear
        }
    }

    /// Background color for the fulfillment badge (SwiftUI).
    var badgeBackgroundSwiftUIColor: Color {
        Color(uiColor: badgeBackgroundColor)
    }
}

// MARK: - Localization

private extension OrderFulfillmentStatus {
    enum Localization {
        static let fulfilled = NSLocalizedString(
            "orderFulfillmentStatus.badge.fulfilled",
            value: "Fulfilled",
            comment: "Fulfillment status badge text shown on CIAB order rows when the order has been fulfilled."
        )
        static let fulfilledWithDate = NSLocalizedString(
            "orderFulfillmentStatus.badge.fulfilledWithDate",
            value: "Fulfilled on %1$@",
            comment: "Fulfillment status badge text with date, shown on the CIAB order details screen. %1$@ is the formatted date."
        )
        static let unfulfilled = NSLocalizedString(
            "orderFulfillmentStatus.badge.unfulfilled",
            value: "Unfulfilled",
            comment: "Fulfillment status badge text shown on CIAB order rows when the order has not been fulfilled."
        )
    }
}
