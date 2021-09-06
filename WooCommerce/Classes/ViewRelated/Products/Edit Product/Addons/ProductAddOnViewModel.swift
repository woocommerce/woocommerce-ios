import Foundation
import Yosemite

/// ViewModel for `ProductAddOn`
///
struct ProductAddOnViewModel: Identifiable, Equatable {

    /// Represents an Add-on option
    ///
    struct Option: Identifiable, Equatable {

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
    init(addOn: Yosemite.ProductAddOn,
         currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
        name = addOn.name
        description = addOn.description
        price = currencyFormatter.formatAmount(addOn.price) ?? ""

        // Convert options and filter empty ones.
        options = addOn.options.enumerated().compactMap { index, option in
            guard !option.label.isNilOrEmpty || !option.price.isNilOrEmpty else {
                return nil
            }
            return Option(name: option.label ?? "",
                          price: ProductAddOnViewModel.formatPrice(option: option, currencyFormatter: currencyFormatter),
                          offSetDivider: index < (addOn.options.count - 1))
        }
    }

    /// Returns the option price with specific format depending on its price type.
    ///
    private static func formatPrice(option: ProductAddOnOption, currencyFormatter: CurrencyFormatter) -> String {
        switch option.priceType {
        case .percentageBased:
            return "\(option.price ?? "")%"
        default:
            return currencyFormatter.formatAmount(option.price ?? "") ?? ""
        }
    }
}
