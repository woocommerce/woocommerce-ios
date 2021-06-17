import Foundation
import Yosemite

/// ViewModel for `ProductAddOnsList`
///
final class ProductAddOnsListViewModel {

    /// View title
    ///
    let title = Localization.title

    /// View info notice
    ///
    let infoNotice = Localization.infoNotice

    /// Add-ons to render
    ///
    let addOns: [ProductAddOnViewModel]

    init(addOns: [ProductAddOnViewModel]) {
        self.addOns = addOns
    }
}

// MARK: Initializers
extension ProductAddOnsListViewModel {
    convenience init(addOns: [Yosemite.ProductAddOn]) {
        let viewModels = addOns.map { ProductAddOnViewModel(addOn: $0) }
        self.init(addOns: viewModels)
    }
}

// MARK: Constants
extension ProductAddOnsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "Title for the product add-ons screen")
        static let infoNotice = NSLocalizedString("You can edit product add-ons in the web dashboard.",
                                                  comment: "Info notice at the bottom of the product add-ons screen")
    }
}
