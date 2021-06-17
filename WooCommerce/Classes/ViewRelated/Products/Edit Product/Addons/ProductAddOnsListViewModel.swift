import Foundation

/// ViewModel for `ProductAddOnsList`
///
final class ProductAddOnsListViewModel {

    /// View title
    ///
    let title = Localization.title

    /// View info notice
    ///
    let infoNotice = Localization.infoNotice
}

// MARK: Constants
extension ProductAddOnsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "Title for the product add-ons screen")
        static let infoNotice = NSLocalizedString("You can edit product add-ons in the web dashboard",
                                                  comment: "Info notice at the bottom of the product add-ons screen")
    }
}
