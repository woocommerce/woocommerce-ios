import Foundation

/// ViewModel for `ProductAddOn`
///
struct ProductAddOnViewModel {

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
