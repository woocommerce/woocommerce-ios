import Foundation
import Yosemite

/// ViewModel for `OrderAddOnListI1View`
///
class OrderAddOnListI1ViewModel {
    /// AddOns to render
    ///
    let addOns: [OrderAddOnI1ViewModel]

    /// Navigation title
    ///
    let title = Localization.title

    /// Member-wise initializer, useful for `SwiftUI` previews
    ///
    init(addOns: [OrderAddOnI1ViewModel]) {
        self.addOns = addOns
    }

    /// Initializer: Converts order item attributes into add-on view models
    ///
    init(attributes: [OrderItemAttribute]) {
        self.addOns = []
    }
}

// MARK: Constants
private extension OrderAddOnListI1ViewModel {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "The title on the navigation bar when viewing an order item add-ons")
    }
}


/// ViewModel for `OrderAddOnI1View`
///
struct OrderAddOnI1ViewModel: Identifiable {
    /// Unique identifier, required by `SwiftUI`
    ///
    let id = UUID()

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
