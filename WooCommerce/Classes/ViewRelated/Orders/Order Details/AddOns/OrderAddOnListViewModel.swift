import Foundation
import Yosemite

/// ViewModel for `OrderAddOnListI1View`
///
final class OrderAddOnListI1ViewModel: ObservableObject {
    /// AddOns to render
    ///
    let addOns: [OrderAddOnI1ViewModel]

    /// Navigation title
    ///
    let title = Localization.title

    /// Update add-ons notice
    ///
    let updateNotice = Localization.updateNotice

    /// Indicates if the top banner should be shown or not.
    ///
    @Published var shouldShowBetaBanner: Bool = true

    /// Indicates if the survey flow should be shown or not.
    ///
    @Published var shouldShowSurvey: Bool = false

    /// Analytics service
    ///
    private let analytics: Analytics

    /// Member-wise initializer, useful for `SwiftUI` previews
    ///
    init(addOns: [OrderAddOnI1ViewModel], analytics: Analytics = ServiceLocator.analytics) {
        self.addOns = addOns
        self.analytics = analytics
    }

    /// Initializer: Converts order item attributes into add-on view models
    ///
    init(attributes: [OrderItemAttribute], analytics: Analytics = ServiceLocator.analytics) {
        self.addOns = attributes.map { attribute in
            let name = Self.addOnName(from: attribute)
            let price = Self.addOnPrice(from: attribute, withDecodedName: name)
            return OrderAddOnI1ViewModel(id: attribute.metaID, title: name, content: attribute.value, price: price)
        }
        self.analytics = analytics
    }

    /// Decodes the name of the add-on from the `attribute.name` property.
    /// The `attribute.name` comes in the form of "add-on-title (add-on-price)". EG: "Topping (Spicy) ($30.00)"
    ///
    private static func addOnName(from attribute: OrderItemAttribute) -> String {
        let components = attribute.name.components(separatedBy: " (") // "Topping (Spicy) ($30.00)" -> ["Topping", "Spicy)", "$30.00)"]

        // If name does not match our format assumptions, return the raw name.
        guard components.count > 1 else {
            return attribute.name
        }

        return components.dropLast() // ["Topping", "Spicy)", "$30.00)"] -> ["Topping", "Spicy)"]
            .joined(separator: " (") // ["Topping", "Spicy)"] -> "Topping (Spicy)"
    }

    /// Decodes the price of the add-on from the `attribute.name` property using an already decoded add-on name.
    /// The `attribute.name` comes in the form of "add-on-title (add-on-price)". EG: "Topping (Spicy) ($30.00)"
    ///
    private static func addOnPrice(from attribute: OrderItemAttribute, withDecodedName name: String) -> String {
        attribute.name.replacingOccurrences(of: name, with: "")     // "Topping (Spicy) ($30.00)" -> " ($30.00)"
            .trimmingCharacters(in: CharacterSet([" ", "(", ")"]))  // " ($30.00)" -> "$30.00"
    }
}

// MARK: Inputs
extension OrderAddOnListI1ViewModel {
    /// Sends a track report to the displayed add-ons to the analytics service.
    ///
    func trackAddOns() {
        let addOnNames = addOns.map { $0.title }
        analytics.track(event: WooAnalyticsEvent.OrderDetailAddOns.orderAddOnsViewed(addOnNames: addOnNames))
    }
}

// MARK: Constants
private extension OrderAddOnListI1ViewModel {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "The title on the navigation bar when viewing an order item add-ons")
        static let updateNotice = NSLocalizedString("If renaming an add-on in your web dashboard, " +
                                                    "please note that previous orders will no longer show that add-on within the app.",
                                                    comment: "The text below the order add-ons list indicating that the content could be stale.")
    }
}


/// ViewModel for `OrderAddOnI1View`
///
struct OrderAddOnI1ViewModel: Identifiable, Equatable {
    /// Unique identifier, required by `SwiftUI`
    /// Discussion: Not using `UUID()` to not having to write a custom equality function.
    ///
    let id: Int64

    /// Add-on title
    ///
    let title: String

    /// Add-on content
    ///
    let content: String

    /// Add-on price
    ///
    let price: String
}
