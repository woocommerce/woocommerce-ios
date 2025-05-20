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
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    static var errorOnLoadingVariations: Self {
        PointOfSaleErrorState(
            errorType: .variationsLoadError,
            title: Constants.failedToLoadVariationsTitle,
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    static var errorOnLoadingProductsNextPage: Self {
        PointOfSaleErrorState(
            errorType: .productsNextPageError,
            title: Constants.failedToLoadProductsNextPageTitle,
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    static var errorOnLoadingVariationsNextPage: Self {
        PointOfSaleErrorState(
            errorType: .variationsNextPageError,
            title: Constants.failedToLoadVariationsNextPageTitle,
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    static var errorOnLoadingCoupons: Self {
        PointOfSaleErrorState(
            errorType: .couponsLoadError,
            title: Constants.loadingCouponsErrorTitle,
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    static var errorOnEnablingCoupons: Self {
        PointOfSaleErrorState(
            errorType: .couponsDisabled,
            title: Constants.enablingCouponsErrorTitle,
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
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
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    static var errorOnRefreshingCoupons: Self {
        PointOfSaleErrorState(
            errorType: .couponsRefreshError,
            title: Constants.failedToRefreshCouponsTitle,
            subtitle: Constants.genericErrorSubtitle,
            buttonText: Constants.retryButtonTitle)
    }

    enum Constants {
        static let genericErrorSubtitle = NSLocalizedString(
            "pos.itemList.genericErrorSubtitle",
            value: "Please try again.",
            comment: "Generic subtitle appearing on error screens when there's an error."
        )
        static let retryButtonTitle = NSLocalizedString(
            "pos.itemList.retryButtonTitle",
            value: "Retry",
            comment: "Generic text for retry buttons appearing on error screens."
        )
        static let loadingCouponsErrorTitle = NSLocalizedString(
            "pos.itemList.loadingCouponsErrorTitle2",
            value: "Unable to load coupons",
            comment: "Title appearing on the coupon list screen when there's an error loading coupons."
        )
        static let loadingCouponsDisabledTitle = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledTitle2",
            value: "Start accepting coupons",
            comment: "Title appearing on the coupon list screen when coupons are disabled."
        )
        static let loadingCouponsDisabledSubtitle = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledSubtitle2",
            value: "Enable coupon codes in your store to start creating them for your customers.",
            comment: "Subtitle appearing on the coupon list screen when coupons are disabled."
        )
        static let loadingCouponsDisabledAction = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledAction2",
            value: "Enable coupons",
            comment: "Text of the button appearing on the coupon list screen when coupons are disabled."
        )
        static let failedToLoadProductsTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsTitle2",
            value: "Unable to load products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadVariationsTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsTitle2",
            value: "Unable to load variations",
            comment: "Text appearing on the item list screen when there's an error loading variations."
        )
        static let failedToLoadProductsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsNextPageTitle2",
            value: "Unable to load more products",
            comment: "Text appearing on the item list screen when there's an error loading a page of products after " +
            "the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadVariationsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsNextPageTitle2",
            value: "Unable to load more variations",
            comment: "Text appearing on the item list screen when there's an error loading a page of variations after " +
            "the first. Shown inline with the previously loaded items above."
        )
        static let enablingCouponsErrorTitle = NSLocalizedString(
            "pos.itemList.enablingCouponsErrorTitle2",
            value: "Unable to enable coupons",
            comment: "Title appearing on the coupon list screen when there's an error enabling coupons setting in the store."
        )
        static let failedToLoadCouponsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadCouponsNextPageTitle2",
            value: "Unable to load more coupons",
            comment: "Text appearing on the coupon list screen when there's an error loading a page of coupons after the first. " +
            "Shown inline with the previously loaded coupons above."
        )
        static let failedToRefreshCouponsTitle = NSLocalizedString(
            "pos.itemList.failedToRefreshCouponsTitle2",
            value: "Unable to refresh coupons",
            comment: "Title appearing on the coupon list screen when there's an error refreshing coupons."
        )
    }
}
