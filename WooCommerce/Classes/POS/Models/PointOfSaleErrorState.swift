import Foundation

struct PointOfSaleErrorState: Equatable {
    let title: String
    let subtitle: String
    let buttonText: String

    static func errorOnLoadingProducts() -> Self {
        PointOfSaleErrorState(title: Constants.failedToLoadTitle,
                              subtitle: Constants.failedToLoadSubtitle,
                              buttonText: Constants.failedToLoadButtonTitle)
    }

    static func errorOnLoadingProductsNextPage() -> Self {
        PointOfSaleErrorState(title: Constants.failedToLoadProductsNextPageTitle,
                              subtitle: Constants.failedToLoadProductsNextPageSubtitle,
                              buttonText: Constants.failedToLoadProductsNextPageButtonTitle)
    }

    static func errorOnLoadingVariationsNextPage() -> Self {
        PointOfSaleErrorState(title: Constants.failedToLoadVariationsNextPageTitle,
                              subtitle: Constants.failedToLoadVariationsNextPageSubtitle,
                              buttonText: Constants.failedToLoadVariationsNextPageButtonTitle)
    }

    enum Constants {
        static let failedToLoadTitle = NSLocalizedString(
            "pos.itemList.failedToLoadTitle",
            value: "Error loading products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadSubtitle",
            value: "Give it another go?",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading products."
        )
        static let failedToLoadButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadProductsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsNextPageTitle",
            value: "Failed to load more items",
            comment: "Text appearing on the item list screen when there's an error loading a page of products after " +
            "the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadProductsNextPageSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsNextPageSubtitle",
            value: "An error occurred while loading products.",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading a page of " +
            "products after the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadProductsNextPageButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsNextPageButtonTitle",
            value: "Try again",
            comment: "Text for the button appearing on the item list screen when there's an error loading a page of " +
            "products after the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadVariationsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsNextPageTitle",
            value: "Failed to load more items",
            comment: "Text appearing on the item list screen when there's an error loading a page of variations after " +
            "the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadVariationsNextPageSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsNextPageSubtitle",
            value: "An error occurred while loading variations.",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading a page of " +
            "variations after the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadVariationsNextPageButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsNextPageButtonTitle",
            value: "Try again",
            comment: "Text for the button appearing on the item list screen when there's an error loading a page of " +
            "variations after the first. Shown inline with the previously loaded items above."
        )
    }
}
