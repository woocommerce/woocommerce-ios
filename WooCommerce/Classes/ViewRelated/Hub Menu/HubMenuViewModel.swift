import Foundation
import UIKit
import SwiftUI
import Combine
import Experiments
import Yosemite
import Storage

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

    @Published private(set) var storeTitle = Localization.myStore

    @Published private(set) var storeURL = WooConstants.URLs.blog.asURL()

    @Published private(set) var woocommerceAdminURL = WooConstants.URLs.blog.asURL()

    /// Child items
    ///
    @Published private(set) var menuElements: [HubMenuItem] = []

    /// The switch store button should be hidden when logged in with site credentials only.
    ///
    @Published private(set) var switchStoreEnabled = false

    @Published var showingReviewDetail = false

    @Published var shouldAuthenticateAdminPage = false

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let generalAppSettings: GeneralAppSettingsStorage

    private var productReviewFromNoteParcel: ProductReviewFromNoteParcel?

    private var storePickerCoordinator: StorePickerCoordinator?

    init(siteID: Int64,
         navigationController: UINavigationController? = nil,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores,
         generalAppSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings) {
        self.siteID = siteID
        self.navigationController = navigationController
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.generalAppSettings = generalAppSettings
        self.switchStoreEnabled = stores.isAuthenticatedWithoutWPCom == false
        observeSiteForUIUpdates()
    }

    func viewDidAppear() {
        NotificationCenter.default.post(name: .hubMenuViewDidAppear, object: nil)
    }

    /// Resets the menu elements displayed on the menu.
    ///
    func setupMenuElements() {
        menuElements = [Payments(), WoocommerceAdmin(), ViewStore(), Reviews()]
        if generalAppSettings.betaFeatureEnabled(.inAppPurchases) {
            menuElements.append(InAppPurchases())
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
        stores.site
            .compactMap { site -> URL? in
                guard let urlString = site?.url, let url = URL(string: urlString) else {
                    return nil
                }
                return url
            }
            .assign(to: &$storeURL)

        stores.site
            .compactMap { $0?.name }
            .assign(to: &$storeTitle)

        stores.site
            .compactMap { site -> URL? in
                guard let urlString = site?.adminURL, let url = URL(string: urlString) else {
                    return site?.adminURLWithFallback()
                }
                return url
            }
            .assign(to: &$woocommerceAdminURL)

        stores.site
            .map { [weak self] site in
                guard let self, let site else {
                    return false
                }
                /// If the site is self-hosted and user is authenticated with WPCom,
                /// `AuthenticatedWebView` will attempt to authenticate and redirect to the admin page and fails.
                /// This should be prevented 💀⛔️
                guard site.isWordPressComStore || self.stores.isAuthenticatedWithoutWPCom else {
                    return false
                }
                return true
            }
            .assign(to: &$shouldAuthenticateAdminPage)
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
        let icon: UIImage = .walletImage
        let iconColor: UIColor = .withColorStudio(.orange)
        var badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-payments"
        let trackingOption: String = "payments"
    }

    struct WoocommerceAdmin: HubMenuItem {
        static var id = "woocommerceAdmin"

        let title: String = Localization.woocommerceAdmin
        let icon: UIImage = .wordPressLogoImage
        let iconColor: UIColor = .wooBlue
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

    struct InAppPurchases: HubMenuItem {
        static var id = "iap"

        let title: String = "[Debug] IAP"
        let icon: UIImage = UIImage(systemName: "ladybug.fill")!
        let iconColor: UIColor = .red
        let badge: HubMenuBadgeType = .number(number: 0)
        let accessibilityIdentifier: String = "menu-iap"
        let trackingOption: String = "debug-iap"
    }

    enum Localization {
        static let payments = NSLocalizedString("Payments",
                                                comment: "Title of the hub menu payments button")
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
