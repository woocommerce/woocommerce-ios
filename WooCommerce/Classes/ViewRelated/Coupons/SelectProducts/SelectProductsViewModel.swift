import Foundation

/// View Model for `SelectProducts`
///
final class SelectProductsViewModel: ObservableObject {
    /// Whether the view is for selecting or excluding products
    private var isExclusion: Bool

    @Published private(set) var selectedItemCount: Int = 0

    /// Title for the navigation bar of the Select Products screen
    ///
    var navigationTitle: String {
        isExclusion ? Localization.exclusionTitle : Localization.selectionTitle
    }

    /// Title for the action button on Select Products screen
    ///
    var actionTitle: String {
        let itemCount = String.pluralize(selectedItemCount, singular: Localization.singleProduct, plural: Localization.multipleProducts)

        let format = isExclusion ? Localization.exclusionActionTitle : Localization.selectionActionTitle
        return String.localizedStringWithFormat(format, itemCount)
    }

    init(isExclusion: Bool = false) {
        self.isExclusion = isExclusion
    }
}

private extension SelectProductsViewModel {
    enum Localization {
        static let selectionTitle = NSLocalizedString("Select products", comment: "Title for the Select Products screen")
        static let exclusionTitle = NSLocalizedString("Exclude products", comment: "Title of the Exclude Products screen")
        static let selectionActionTitle = NSLocalizedString(
            "Select %1$@",
            comment: "Title of the action button on the Select Products screen" +
            "Reads like: Select 1 Product"
        )
        static let exclusionActionTitle = NSLocalizedString(
            "Exclude %1$@",
            comment: "Title of the action button on the Exclude Products screen" +
            "Reads like: Exclude 1 Product"
        )
        static let singleProduct = NSLocalizedString("%1$d Product", comment: "Count of one product")
        static let multipleProducts = NSLocalizedString("%1$d Products", comment: "Count of several products, reads like: 2 Products")
    }
}
