import Foundation
import UIKit
import SwiftUI
import Combine
import Experiments
import Yosemite

extension NSNotification.Name {
    /// Posted whenever the hub menu view did appear.
    ///
    public static let hubMenuViewDidAppear = Foundation.Notification.Name(rawValue: "com.woocommerce.ios.hubMenuViewDidAppear")
}

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
            return stores.sessionManager.defaultSite?.adminURLWithFallback() ??
            WooConstants.URLs.blog.asURL()
        }
        return url
    }

    /// Child items
    ///
    @Published private(set) var menuElements: [HubMenuItem] = []

    @Published var showingReviewDetail = false

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

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
        self.featureFlagService = featureFlagService
        observeSiteForUIUpdates()
    }

    func viewDidAppear() {
        NotificationCenter.default.post(name: .hubMenuViewDidAppear, object: nil)
    }

    /// Resets the menu elements displayed on the menu.
    ///
    func setupMenuElements() {
        menuElements = [WoocommerceAdmin(), ViewStore(), Reviews()]

        if featureFlagService.isFeatureFlagEnabled(.paymentsHubMenuSection) {
            menuElements.insert(Payments(badge: .number(number: 0)), at: 0)
        }

        let inboxUseCase = InboxEligibilityUseCase(stores: stores, featureFlagService: featureFlagService)
        inboxUseCase.isEligibleForInbox(siteID: siteID) { [weak self] isInboxMenuShown in
            guard let self = self else { return }
            if let index = self.menuElements.firstIndex(where: { item in
                type(of: item).id == ViewStore.id
            }), isInboxMenuShown {
                self.menuElements.insert(Inbox(), at: index + 1)
            }
        }

        let action = AppSettingsAction.loadCouponManagementFeatureSwitchState { [weak self] result in
            guard let self = self else { return }
            guard case let .success(enabled) = result, enabled else {
                return
            }
            if let index = self.menuElements.firstIndex(where: { item in
                type(of: item).id == Reviews.id
            }) {
                self.menuElements.insert(Coupons(), at: index)
            } else {
                self.menuElements.append(Coupons())
            }
        }

        stores.dispatch(action)

        let featureAnnouncementVisibilityAction = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .paymentsInHubMenuButton) {
            [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let visible):
                    if visible {
                        if let paymentsMenuItemIndex = self.menuElements.firstIndex(where: { item in
                            type(of: item).id == Payments.id
                        }) {
                            self.menuElements[paymentsMenuItemIndex] = Payments(badge: .newFeature)
                        }
                    }
                default:
                    break
                }
        }

        stores.dispatch(featureAnnouncementVisibilityAction)

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

protocol HubMenuItem {
    static var id: String { get }
    var title: String { get }
    var icon: UIImage { get }
    var iconColor: UIColor { get }
    var badge: HubMenuBadgeType { get }
    var accessibilityIdentifier: String { get }
    var trackingOption: String { get }
}

extension HubMenuItem {
    var id: String {
        type(of: self).id
    }
}

extension HubMenuViewModel {
    struct Payments: HubMenuItem {

        static var id = "payments"

        let title: String = Localization.payments
        let icon: UIImage = .cardPresentImage
        let iconColor: UIColor = .primary
        var badge: HubMenuBadgeType
        let accessibilityIdentifier: String = "menu-payments"
        let trackingOption: String = "payments_menu"
    }

    struct WoocommerceAdmin: HubMenuItem {
        static var id = "woocommerceAdmin"

        let title: String = Localization.woocommerceAdmin
        let icon: UIImage = .wordPressLogoImage
        let iconColor: UIColor = .blue
        let badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-woocommerce-admin"
        let trackingOption: String = "admin_menu"
    }

    struct ViewStore: HubMenuItem {
        static var id = "viewStore"

        let title: String = Localization.viewStore
        let icon: UIImage = .storeImage
        let iconColor: UIColor = .accent
        let badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-view-store"
        let trackingOption: String = "view_store"
    }

    struct Inbox: HubMenuItem {
        static var id = "inbox"

        let title: String = Localization.inbox
        let icon: UIImage = .mailboxImage
        let iconColor: UIColor = .withColorStudio(.blue, shade: .shade40)
        let badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-inbox"
        let trackingOption: String = "inbox"
    }

    struct Coupons: HubMenuItem {
        static var id = "coupons"

        let title: String = Localization.coupon
        let icon: UIImage = .couponImage
        let iconColor: UIColor = UIColor(light: .withColorStudio(.green, shade: .shade30),
                                         dark: .withColorStudio(.green, shade: .shade50))
        let badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-coupons"
        let trackingOption: String = "coupons"
    }

    struct Reviews: HubMenuItem {
        static var id = "reviews"

        let title: String = Localization.reviews
        let icon: UIImage = .starImage(size: 24.0)
        let iconColor: UIColor = .primary
        let badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-reviews"
        let trackingOption: String = "reviews"
    }

    private enum Localization {
        static let payments = NSLocalizedString("Payments",
                                                        comment: "Title of one of the hub menu options")
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
