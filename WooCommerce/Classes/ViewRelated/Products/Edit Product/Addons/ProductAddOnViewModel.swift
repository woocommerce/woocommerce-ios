import Foundation
import Yosemite

/// ViewModel for `ProductAddOn`
///
struct ProductAddOnViewModel: Identifiable {

    /// Represents an Add-on option
    ///
    struct Option: Identifiable {

        /// Option name
        ///
        let name: String

        /// Option optional price.
        ///
        let price: String

        /// Defines if the divider should be offset or not.
        ///
        let offSetDivider: Bool

        /// Identifiable conformance.
        ///
        var id: String {
            name
        }

        /// Determines the option price visibility
        ///
        var showPrice: Bool {
            price.isNotEmpty
        }
    }

    /// Add-on name
    ///
    let name: String

    /// Add-on optional description.
    ///
    let description: String

    /// Add-on optional price.
    ///
    let price: String

    /// Add-on options.
    ///
    let options: [Option]

    /// Identifiable conformance.
    ///
    var id: String {
        name
    }

    /// Determines the main description visibility
    ///
    var showDescription: Bool {
        price.isNotEmpty || description.isNotEmpty
    }

    /// Determines the main price visibility
    ///
    var showPrice: Bool {
        price.isNotEmpty
    }

    /// Determines the bottom divider visibility.
    ///
    var showBottomDivider: Bool {
        options.isEmpty
    }
}

// MARK: Initializers
extension ProductAddOnViewModel {

    /// Initializes properties using a `Yosemite.ProductAddOn` as  source.
    ///
    init(addOn: Yosemite.ProductAddOn) {
        name = addOn.name
        description = addOn.description
        price = addOn.price
        options = addOn.options.map { Option(name: $0.label ?? "", price: $0.price ?? "") }
    }
}
