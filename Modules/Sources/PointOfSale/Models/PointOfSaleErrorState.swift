import Foundation
import enum Alamofire.AFError

struct PointOfSaleErrorState: Equatable {
    enum ErrorType: Equatable {
        case initialCatalogSyncError
        case refreshCatalogSyncError
        case productsLoadError
        case variationsLoadError
        case productsNextPageError
        case variationsNextPageError
        case couponsLoadError
        case couponsDisabled
        case couponsNextPageError
        case couponsRefreshError
        case ordersLoadError
        case ordersNextPageError
        case bookingsLoadError
    }

    let errorType: ErrorType
    let title: String
    let subtitle: String
    let buttonText: String

    static func errorOnLoadingProducts(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .productsLoadError,
            title: Constants.failedToLoadProductsTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingVariations(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .variationsLoadError,
            title: Constants.failedToLoadVariationsTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingProductsNextPage(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .productsNextPageError,
            title: Constants.failedToLoadProductsNextPageTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingVariationsNextPage(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .variationsNextPageError,
            title: Constants.failedToLoadVariationsNextPageTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingCoupons(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .couponsLoadError,
            title: Constants.loadingCouponsErrorTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnEnablingCoupons(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .couponsDisabled,
            title: Constants.enablingCouponsErrorTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static var errorCouponsDisabled: Self {
        PointOfSaleErrorState(
            errorType: .couponsDisabled,
            title: Constants.loadingCouponsDisabledTitle,
            subtitle: Constants.loadingCouponsDisabledSubtitle,
            buttonText: Constants.loadingCouponsDisabledAction)
    }

    static func errorOnLoadingCouponsNextPage(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .couponsNextPageError,
            title: Constants.failedToLoadCouponsNextPageTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnRefreshingCoupons(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .couponsRefreshError,
            title: Constants.failedToRefreshCouponsTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingOrders(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .ordersLoadError,
            title: Constants.failedToLoadOrdersTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingOrdersNextPage(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .ordersNextPageError,
            title: Constants.failedToLoadOrdersNextPageTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnLoadingBookings(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .bookingsLoadError,
            title: Constants.failedToLoadBookingsTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnInitalCatalogSync(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .initialCatalogSyncError,
            title: Constants.failedToSyncCatalogTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    static func errorOnRefreshingCatalog(error: Error? = nil) -> Self {
        PointOfSaleErrorState(
            errorType: .refreshCatalogSyncError,
            title: Constants.failedToRefreshCatalogTitle,
            subtitle: subtitle(for: error),
            buttonText: Constants.retryButtonTitle)
    }

    private static func subtitle(for error: Error?) -> String {
        if let error, error.isConnectivityError {
            return Constants.connectivityErrorSubtitle
        }

        return Constants.genericErrorSubtitle
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
        static let failedToSyncCatalogTitle = NSLocalizedString(
            "pos.itemList.syncCatalogErrorTitle",
            value: "Unable to sync catalog",
            comment: "Title appearing on the item list screen when there's an error syncing the catalog for the first time."
        )
        static let failedToRefreshCatalogTitle = NSLocalizedString(
            "pos.catalog.refreshFailedTitle",
            value: "Unable to refresh catalog",
            comment: "Title appearing in a modal when there's an error refreshing the catalog."
        )
        static let loadingCouponsErrorTitle = NSLocalizedString(
            "pos.itemList.loadingCouponsErrorTitle.2",
            value: "Unable to load coupons",
            comment: "Title appearing on the coupon list screen when there's an error loading coupons."
        )
        static let loadingCouponsDisabledTitle = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledTitle.2",
            value: "Start accepting coupons",
            comment: "Title appearing on the coupon list screen when coupons are disabled."
        )
        static let loadingCouponsDisabledSubtitle = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledSubtitle.2",
            value: "Enable coupon codes in your store to start creating them for your customers.",
            comment: "Subtitle appearing on the coupon list screen when coupons are disabled."
        )
        static let loadingCouponsDisabledAction = NSLocalizedString(
            "pos.itemList.loadingCouponsDisabledAction.2",
            value: "Enable coupons",
            comment: "Text of the button appearing on the coupon list screen when coupons are disabled."
        )
        static let failedToLoadProductsTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsTitle.2",
            value: "Unable to load products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadVariationsTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsTitle.2",
            value: "Unable to load variations",
            comment: "Text appearing on the item list screen when there's an error loading variations."
        )
        static let failedToLoadProductsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadProductsNextPageTitle.2",
            value: "Unable to load more products",
            comment: "Text appearing on the item list screen when there's an error loading a page of products after " +
            "the first. Shown inline with the previously loaded items above."
        )
        static let failedToLoadVariationsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadVariationsNextPageTitle.2",
            value: "Unable to load more variations",
            comment: "Text appearing on the item list screen when there's an error loading a page of variations after " +
            "the first. Shown inline with the previously loaded items above."
        )
        static let enablingCouponsErrorTitle = NSLocalizedString(
            "pos.itemList.enablingCouponsErrorTitle.2",
            value: "Unable to enable coupons",
            comment: "Title appearing on the coupon list screen when there's an error enabling coupons setting in the store."
        )
        static let failedToLoadCouponsNextPageTitle = NSLocalizedString(
            "pos.itemList.failedToLoadCouponsNextPageTitle.2",
            value: "Unable to load more coupons",
            comment: "Text appearing on the coupon list screen when there's an error loading a page of coupons after the first. " +
            "Shown inline with the previously loaded coupons above."
        )
        static let failedToRefreshCouponsTitle = NSLocalizedString(
            "pos.itemList.failedToRefreshCouponsTitle.2",
            value: "Unable to refresh coupons",
            comment: "Title appearing on the coupon list screen when there's an error refreshing coupons."
        )
        static let connectivityErrorSubtitle = NSLocalizedString(
            "pos.itemList.connectivityErrorSubtitle",
            value: "Please check your internet connection and try again.",
            comment: "Subtitle appearing on error screens when there is a network connectivity error."
        )
        static let failedToLoadOrdersTitle = NSLocalizedString(
            "pos.orderList.failedToLoadOrdersTitle",
            value: "Unable to load orders",
            comment: "Text appearing on the order list screen when there's an error loading orders."
        )
        static let failedToLoadOrdersNextPageTitle = NSLocalizedString(
            "pos.orderList.failedToLoadOrdersNextPageTitle",
            value: "Unable to load more orders",
            comment: "Text appearing on the order list screen when there's an error loading a page of orders after " +
            "the first. Shown inline with the previously loaded orders above."
        )
        static let failedToLoadBookingsTitle = NSLocalizedString(
            "pos.bookingList.failedToLoadBookingsTitle",
            value: "Unable to load bookings",
            comment: "Text appearing on the booking list screen when there's an error loading bookings."
        )
    }
}
