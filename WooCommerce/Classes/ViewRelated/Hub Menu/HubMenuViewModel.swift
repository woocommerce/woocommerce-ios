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
        guard let urlString = stores.sessionManager.defaultAccount?.gravatarUrl, let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

    var storeTitle: String {
        stores.sessionManager.defaultSite?.name ?? Localization.myStore
    }

    var storeURL: URL {
        guard let urlString = stores.sessionManager.defaultSite?.url, let url = URL(string: urlString) else {
            return WooConstants.URLs.blog.asURL()
        }
        return url
    }

    var woocommerceAdminURL: URL {
        guard let urlString = stores.sessionManager.defaultSite?.adminURL, let url = URL(string: urlString) else {
            return WooConstants.URLs.blog.asURL()
        }
        return url
    }

    /// Child items
    ///
    @Published private(set) var menuElements: [Menu] = []

    @Published var showingReviewDetail = false

    private let stores: StoresManager

    private var productReviewFromNoteParcel: ProductReviewFromNoteParcel?

    private var storePickerCoordinator: StorePickerCoordinator?

    private var cancellables = Set<AnyCancellable>()

    init(siteID: Int64,
         navigationController: UINavigationController? = nil,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.navigationController = navigationController
        self.stores = stores
        menuElements = [.woocommerceAdmin, .viewStore]
        if featureFlagService.isFeatureFlagEnabled(.inbox) {
            menuElements.append(.inbox)
        }
        if featureFlagService.isFeatureFlagEnabled(.couponManagement) {
            menuElements.append(.coupons)
        }
        menuElements.append(.reviews)
        observeSiteForUIUpdates()
    }

    /// Present the `StorePickerViewController` using the `StorePickerCoordinator`, passing the navigation controller from the entry point.
    ///
    func presentSwitchStore() {
        ServiceLocator.analytics.track(.hubMenuSwitchStoreTapped)
        if let navigationController = navigationController {
            storePickerCoordinator = StorePickerCoordinator(navigationController, config: .switchingStores)
            storePickerCoordinator?.start()
        }
    }

    func showReviewDetails(using parcel: ProductReviewFromNoteParcel) {
        productReviewFromNoteParcel = parcel
        showingReviewDetail = true
    }

    func getReviewDetailDestination() -> ReviewDetailView? {
        guard let parcel = productReviewFromNoteParcel else {
            return nil
        }

        return ReviewDetailView(productReview: parcel.review, product: parcel.product, notification: parcel.note)
    }

    private func observeSiteForUIUpdates() {
        stores.site.sink { site in
            // This will be useful in the future for updating some info of the screen depending on the store site info
        }.store(in: &cancellables)
    }
}

extension HubMenuViewModel {
    enum Menu: CaseIterable {
        case woocommerceAdmin
        case viewStore
        case inbox
        case coupons
        case reviews

        var title: String {
            switch self {
            case .woocommerceAdmin:
                return Localization.woocommerceAdmin
            case .viewStore:
                return Localization.viewStore
            case .inbox:
                return Localization.inbox
            case .coupons:
                return Localization.coupon
            case .reviews:
                return Localization.reviews
            }
        }

        var icon: UIImage {
            switch self {
            case .woocommerceAdmin:
                return .wordPressLogoImage
            case .viewStore:
                return .storeImage
            case .inbox:
                return .mailboxImage
            case .coupons:
                return .couponImage
            case .reviews:
                return .starImage(size: 24.0)
            }
        }

        var iconColor: UIColor {
            switch self {
            case .woocommerceAdmin:
                return .blue
            case .viewStore:
                return .accent
            case .inbox:
                return .withColorStudio(.blue, shade: .shade40)
            case .coupons:
                return UIColor(light: .withColorStudio(.green, shade: .shade30),
                               dark: .withColorStudio(.green, shade: .shade50))
            case .reviews:
                return .primary
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
        static let inbox = NSLocalizedString("Inbox", comment: "Title of the Inbox menu in the hub menu")
        static let coupon = NSLocalizedString("Coupons", comment: "Title of the Coupons menu in the hub menu")
        static let reviews = NSLocalizedString("Reviews",
                                               comment: "Title of one of the hub menu options")
    }
}
