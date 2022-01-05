import Foundation
import UIKit
import SwiftUI
import Combine
import Experiments
import Yosemite

/// View model for `HubMenu`.
///
final class HubMenuViewModel: ObservableObject {

    let siteID: Int64

    /// The view controller that will be used for presenting the `StorePickerViewController` via `StorePickerCoordinator`
    ///
    private(set) unowned var navigationController: UINavigationController?

    var avatarURL: URL? {
        guard let urlString = ServiceLocator.stores.sessionManager.defaultAccount?.gravatarUrl, let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    var storeTitle: String {
        ServiceLocator.stores.sessionManager.defaultSite?.name ?? Localization.myStore
    }
    var storeURL: URL {
        guard let urlString = ServiceLocator.stores.sessionManager.defaultSite?.url, let url = URL(string: urlString) else {
            return WooConstants.URLs.blog.asURL()
        }
        return url
    }
    var woocommerceAdminURL: URL {
        guard let urlString = ServiceLocator.stores.sessionManager.defaultSite?.adminURL, let url = URL(string: urlString) else {
            return WooConstants.URLs.blog.asURL()
        }
        return url
    }

    /// Child items
    ///
    @Published private(set) var menuElements: [Menu] = []

    @Published var showingReviewDetail = false

    private var productReviewFromNoteParcel: ProductReviewFromNoteParcel?

    private var storePickerCoordinator: StorePickerCoordinator?

    private var cancellables = Set<AnyCancellable>()

    init(siteID: Int64, navigationController: UINavigationController? = nil, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.navigationController = navigationController
        menuElements = [.woocommerceAdmin, .viewStore, .reviews]
        if featureFlagService.isFeatureFlagEnabled(.couponManagement) {
            menuElements.append(.coupons)
        }
        observeSiteForUIUpdates()
    }

    /// Present the `StorePickerViewController` using the `StorePickerCoordinator`, passing the navigation controller from the entry point.
    ///
    func presentSwitchStore() {
        //TODO-5509: add analytics events
        if let navigationController = navigationController {
            storePickerCoordinator = StorePickerCoordinator(navigationController, config: .switchingStores)
            storePickerCoordinator?.start()
        }
    }

    func setProductReviewFromNoteParcel(_ parcel: ProductReviewFromNoteParcel) {
        productReviewFromNoteParcel = parcel
    }

    func getReviewDetailDestination() -> ReviewDetailView? {
        guard let parcel = productReviewFromNoteParcel else {
            return nil
        }

        return ReviewDetailView(productReview: parcel.review, product: parcel.product, notification: parcel.note)
    }

    private func observeSiteForUIUpdates() {
        ServiceLocator.stores.site.sink { site in
            // This will be useful in the future for updating some info of the screen depending on the store site info
        }.store(in: &cancellables)
    }
}

extension HubMenuViewModel {
    enum Menu: CaseIterable {
        case woocommerceAdmin
        case viewStore
        case coupons
        case reviews

        var title: String {
            switch self {
            case .woocommerceAdmin:
                return Localization.woocommerceAdmin
            case .viewStore:
                return Localization.viewStore
            case .coupons:
                return Localization.coupon
            case .reviews:
                return Localization.reviews
            }
        }

        var icon: UIImage {
            switch self {
            case .woocommerceAdmin:
                return .wordPressLogoImage.imageWithTintColor(.blue) ?? .wordPressLogoImage
            case .viewStore:
                return .storeImage.imageWithTintColor(.accent) ?? .storeImage
            case .coupons:
                return .couponImage
            case .reviews:
                return .starImage(size: 24.0).imageWithTintColor(.primary) ?? .starImage(size: 24.0)
            }
        }
    }

    private enum Localization {
        static let myStore = NSLocalizedString("My Store",
                                               comment: "Title of the hub menu view in case there is no title for the store")
        static let woocommerceAdmin = NSLocalizedString("WooCommerce Admin",
                                                        comment: "Title of one of the hub menu options")
        static let viewStore = NSLocalizedString("View Store",
                                                 comment: "Title of one of the hub menu options")
        static let coupon = NSLocalizedString("Coupons", comment: "Title of the Coupons menu in the hub menu")
        static let reviews = NSLocalizedString("Reviews",
                                               comment: "Title of one of the hub menu options")
    }
}
