import Foundation

/// ViewModel for `ProductAddOnsList`
///
final class ProductAddOnsListViewModel {

    /// View title
    ///
    let title = Localization.title
}

// MARK: Constants
extension ProductAddOnsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "Title for the product add-ons screen")
    }
}
