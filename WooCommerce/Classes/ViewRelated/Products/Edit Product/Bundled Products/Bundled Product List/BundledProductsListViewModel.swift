import Foundation

/// ViewModel for `BundledProductsList`
///
final class BundledProductsListViewModel {

    /// View title
    ///
    let title = Localization.title
}

// MARK: Constants
extension BundledProductsListViewModel {
    enum Localization {
        static let title = NSLocalizedString("Bundled Products", comment: "Title for the bundled products screen")
    }
}
