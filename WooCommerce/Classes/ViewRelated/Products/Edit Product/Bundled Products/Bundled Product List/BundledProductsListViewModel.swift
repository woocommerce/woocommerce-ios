import Foundation

/// ViewModel for `BundledProductsList`
///
final class BundledProductsListViewModel {

    /// View title
    ///
    let title = Localization.title

    /// View info notice
    ///
    let infoNotice = Localization.infoNotice
}

// MARK: Constants
extension BundledProductsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Bundled Products", comment: "Title for the bundled products screen")
        static let infoNotice = NSLocalizedString("You can edit bundled products in the web dashboard.",
                                                  comment: "Info notice at the bottom of the bundled products screen")
    }
}
