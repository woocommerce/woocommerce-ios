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
        case couponsNextPageError
        case couponsRefreshError
    }

    let errorType: ErrorType
    let title: String
    let subtitle: String
    let buttonText: String

    static var errorOnLoadingProducts: Self {
        PointOfSaleErrorState(
            errorType: .productsLoadError,
            title: Constants.failedToLoadProductsTitle,
            subtitle: Constants.failedToLoadProductsSubtitle,
            buttonText: Constants.failedToLoadProductsButtonTitle)
    }

    static var errorOnLoadingVariations: Self {
        PointOfSaleErrorState(
            errorType: .variationsLoadError,
            title: Constants.failedToLoadVariationsTitle,
            subtitle: Constants.failedToLoadVariationsSubtitle,
            buttonText: Constants.failedToLoadVariationsButtonTitle)
    }

    static var errorOnLoadingProductsNextPage: Self {
        PointOfSaleErrorState(
            errorType: .productsNextPageError,
            title: Constants.failedToLoadProductsNextPageTitle,
            subtitle: Constants.failedToLoadProductsNextPageSubtitle,
            buttonText: Constants.failedToLoadProductsNextPageButtonTitle)
    }

    static var errorOnLoadingVariationsNextPage: Self {
        PointOfSaleErrorState(
            errorType: .variationsNextPageError,
            title: Constants.failedToLoadVariationsNextPageTitle,
            subtitle: Constants.failedToLoadVariationsNextPageSubtitle,
            buttonText: Constants.failedToLoadVariationsNextPageButtonTitle)
    }

    static var errorOnLoadingCoupons: Self {
        PointOfSaleErrorState(
            errorType: .couponsLoadError,
            title: Constants.loadingCouponsErrorTitle,
            subtitle: Constants.loadingCouponsErrorSubtitle,
            buttonText: Constants.loadingCouponsErrorRetry)
    }

    static var errorOnEnablingCoupons: Self {
        PointOfSaleErrorState(
            errorType: .couponsDisabled,
            title: Constants.enablingCouponsErrorTitle,
            subtitle: Constants.enablingCouponsErrorSubtitle,
            buttonText: Constants.enablingCouponsErrorRetry)
    }

    static var errorCouponsDisabled: Self {
        PointOfSaleErrorState(
            errorType: .couponsDisabled,
            title: Constants.loadingCouponsDisabledTitle,
            subtitle: Constants.loadingCouponsDisabledSubtitle,
            buttonText: Constants.loadingCouponsDisabledAction)
    }

    static var errorOnLoadingCouponsNextPage: Self {
        PointOfSaleErrorState(
            errorType: .couponsNextPageError,
            title: Constants.failedToLoadCouponsNextPageTitle,
            subtitle: Constants.failedToLoadCouponsNextPageSubtitle,
            buttonText: Constants.failedToLoadCouponsNextPageButtonTitle)
    }

    static var errorOnRefreshingCoupons: Self {
        PointOfSaleErrorState(
            errorType: .couponsRefreshError,
            title: Constants.failedToRefreshCouponsTitle,
            subtitle: Constants.failedToRefreshCouponsSubtitle,
            buttonText: Constants.failedToRefreshCouponsButtonTitle)
    }

    enum Constants {
        static let loadingCouponsErrorTitle = NSLocalizedString(
            "pos.itemList.loadingCouponsErrorTitle",
            value: "Error loading coupons",
            comment: "Title appearing on the coupon list screen when there's an error loading coupons."
        )
        static let loadingCouponsErrorSubtitle = NSLocalizedString(
            "pos.itemList.loadingCouponsErrorSubtitle2",
            value: "Give it another go?",
            comment: "Subtitle appearing on the coupon list screen when there's an error loading coupons."
        )
        static let loadingCouponsErrorRetry = NSLocalizedString(
            "pos.itemList.loadingCouponsErrorRetry",
            value: "Retry",
            comment: "Text of the button appearing on the coupon list screen when there's an error loading coupons."
        )
        static let loadingCouponsDisabledTitle = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledTitle",
            value: "Error loading coupons",
            comment: "Title appearing on the coupon list screen when coupons are disabled."
        )
        static let loadingCouponsDisabledSubtitle = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledSubtitle",
            value: "Please enable the use of coupon codes in your store.",
            comment: "Subtitle appearing on the coupon list screen when coupons are disabled."
        )
        static let loadingCouponsDisabledAction = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledAction",
            value: "Enable",
            comment: "Text of the button appearing on the coupon list screen when coupons are disabled."
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

        static let enablingCouponsErrorTitle = NSLocalizedString(
            "pos.itemList.enablingCouponsErrorTitle",
            value: "Error enabling coupons",
            comment: "Title appearing on the coupon list screen when there's an error enabling coupons setting in the store."
        )
        static let enablingCouponsErrorSubtitle = NSLocalizedString(
            "pos.itemList.enablingCouponsErrorSubtitle",
            value: "Give it another go?",
            comment: "Subtitle appearing on the coupon list screen when there's an error enabling coupons setting in the store."
        )
        static let enablingCouponsErrorRetry = NSLocalizedString(
            "pos.itemList.enablingCouponsErrorRetry",
            value: "Retry",
            comment: "Text of the button appearing on the coupon list screen when there's an error enabling coupons setting in the store.."
        )
        static let failedToLoadCouponsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadCouponsNextPageTitle",
            value: "Failed to load more coupons",
            comment: "Text appearing on the coupon list screen when there's an error loading a page of coupons after the first. " +
            "Shown inline with the previously loaded coupons above."
        )
        static let failedToLoadCouponsNextPageSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadCouponsNextPageSubtitle",
            value: "An error occurred while loading coupons.",
            comment: "Text appearing on the coupon list screen as subtitle when there's an error loading a page of coupons " +
            "after the first. Shown inline with the previously loaded coupons above."
        )
        static let failedToLoadCouponsNextPageButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadCouponsNextPageButtonTitle",
            value: "Try again",
            comment: "Text for the button appearing on the coupon list screen when there's an error loading a page of coupons " +
            "after the first. Shown inline with the previously loaded coupons above."
        )
        static let failedToRefreshCouponsTitle = NSLocalizedString(
            "pos.itemList.failedToRefreshCouponsTitle",
            value: "Error refreshing coupons",
            comment: "Title appearing on the coupon list screen when there's an error refreshing coupons."
        )
        static let failedToRefreshCouponsSubtitle = NSLocalizedString(
            "pos.itemList.failedToRefreshCouponsSubtitle",
            value: "Give it another go?",
            comment: "Subtitle appearing on the coupon list screen when there's an error refreshing coupons."
        )
        static let failedToRefreshCouponsButtonTitle = NSLocalizedString(
            "pos.itemList.failedToRefreshCouponsButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the coupon list screen when there's an error refreshing coupons."
        )
    }
}
