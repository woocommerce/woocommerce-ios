import Foundation

struct PointOfSaleErrorState: Equatable {
    enum ErrorType: Equatable {
        case productsLoadError
        case variationsLoadError
        case productsNextPageError
        case variationsNextPageError
        case couponsNotFound
        case couponsLoadError
        case couponsDisabled
    }

    let errorType: ErrorType
    let title: String
    let subtitle: String
    let buttonText: String

    static func errorOnLoadingProducts() -> Self {
        PointOfSaleErrorState(
            errorType: .productsLoadError,
            title: Constants.failedToLoadProductsTitle,
            subtitle: Constants.failedToLoadProductsSubtitle,
            buttonText: Constants.failedToLoadProductsButtonTitle)
    }

    static func errorOnLoadingVariations() -> Self {
        PointOfSaleErrorState(
            errorType: .variationsLoadError,
            title: Constants.failedToLoadVariationsTitle,
            subtitle: Constants.failedToLoadVariationsSubtitle,
            buttonText: Constants.failedToLoadVariationsButtonTitle)
    }

    static func errorOnLoadingProductsNextPage() -> Self {
        PointOfSaleErrorState(
            errorType: .productsNextPageError,
            title: Constants.failedToLoadProductsNextPageTitle,
            subtitle: Constants.failedToLoadProductsNextPageSubtitle,
            buttonText: Constants.failedToLoadProductsNextPageButtonTitle)
    }

    static func errorOnLoadingVariationsNextPage() -> Self {
        PointOfSaleErrorState(
            errorType: .variationsNextPageError,
            title: Constants.failedToLoadVariationsNextPageTitle,
            subtitle: Constants.failedToLoadVariationsNextPageSubtitle,
            buttonText: Constants.failedToLoadVariationsNextPageButtonTitle)
    }

    static func errorCouponsNotFound() -> Self {
        PointOfSaleErrorState(
            errorType: .couponsNotFound,
            title: Constants.noCouponsFoundTitle,
            subtitle: Constants.noCouponsFoundSubtitle,
            buttonText: Constants.noCouponsFoundButtonTitle)
    }

    static func errorOnLoadingCoupons() -> Self {
        PointOfSaleErrorState(
            errorType: .couponsLoadError,
            title: "Error loading coupons",
            subtitle: "Error loading coupons",
            buttonText: "Retry")
    }

    static func errorCouponsDisabled() -> Self {
        PointOfSaleErrorState(
            errorType: .couponsDisabled,
            title: "Error loading coupons",
            subtitle: "Please enable the use of coupon codes in your store",
            buttonText: "Enable")
    }

    enum Constants {
        static let noCouponsFoundTitle = NSLocalizedString(
            "pos.itemList.noCouponsFoundTitle",
            value: "No coupons found",
            comment: "Text appearing on the coupon list screen when there's no coupons found."
        )
        static let noCouponsFoundSubtitle = NSLocalizedString(
            "pos.itemList.noCouponsFoundSubtitle",
            value: "Boost your business by sending customers special offers and discounts",
            comment: "Text appearing on the coupons list screen as subtitle when there's no coupons found."
        )
        static let noCouponsFoundButtonTitle = NSLocalizedString(
            "pos.itemList.noCouponsFoundButtonTitleButtonTitle",
            value: "Create coupon",
            comment: "Text for the button appearing on the coupons list screen when there's no coupons found."
        )
        static let failedToLoadProductsTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsTitle",
            value: "Error loading products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadProductsSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsSubtitle",
            value: "Give it another go?",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading products."
        )
        static let failedToLoadProductsButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadVariationsTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsTitle",
            value: "Error loading variations",
            comment: "Text appearing on the item list screen when there's an error loading variations."
        )
        static let failedToLoadVariationsSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsSubtitle",
            value: "Give it another go?",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading variations."
        )
        static let failedToLoadVariationsButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the item list screen when there's an error loading variations."
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
