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

/// Destination views that the hub menu can navigate to.
enum HubMenuNavigationDestination {
    case payments
}

/// View model for `HubMenu`.
///
@MainActor
final class HubMenuViewModel: ObservableObject {

    let siteID: Int64

    let credentials: Credentials?

    var avatarURL: URL? {
        guard let urlString = stores.sessionManager.defaultAccount?.gravatarUrl, let url = URL(string: urlString) else {
            return nil
        }
        return url
    }

    @Published var navigationPath = NavigationPath()

    @Published private(set) var storeTitle = Localization.myStore

    @Published private(set) var planName = ""

    @Published private(set) var storeURL = WooConstants.URLs.blog.asURL()

    @Published private(set) var woocommerceAdminURL = WooConstants.URLs.blog.asURL()

    /// POS Section Element
    ///
    @Published private(set) var posElement: HubMenuItem?

    /// Settings Elements
    ///
    @Published private(set) var settingsElements: [HubMenuItem] = []

    /// General items
    ///
    @Published private(set) var generalElements: [HubMenuItem] = []

    /// The switch store button should be hidden when logged in with site credentials only.
    ///
    @Published private(set) var switchStoreEnabled = false

    @Published var selectedMenuID: String?

    @Published var showingReviewDetail = false
    @Published var showingCoupons = false

    @Published var shouldAuthenticateAdminPage = false

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let generalAppSettings: GeneralAppSettingsStorage
    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol
    private let posEligibilityChecker: POSEligibilityCheckerProtocol
    private let inboxEligibilityChecker: InboxEligibilityChecker

    private(set) lazy var posItemProvider: POSItemProvider = {
        let storageManager = ServiceLocator.storageManager
        let currencySettings = ServiceLocator.currencySettings

        return POSProductProvider(storageManager: storageManager,
                                  siteID: siteID,
                                  currencySettings: currencySettings,
                                  credentials: credentials)
    }()

    private(set) var productReviewFromNoteParcel: ProductReviewFromNoteParcel?

    @Published private(set) var shouldShowNewFeatureBadgeOnPayments: Bool = false

    @Published private var isSiteEligibleForBlaze: Bool = false

    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol

    private var cancellables: Set<AnyCancellable> = []

    let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    lazy var inPersonPaymentsMenuViewModel: InPersonPaymentsMenuViewModel = {
        // There is no straightforward way to convert a @Published var to a Binding value because we cannot use $self.
        let navigationPathBinding = Binding(
            get: { [weak self] in
                self?.navigationPath ?? NavigationPath()
            },
            set: { [weak self] in
                self?.navigationPath = $0
            }
        )
        return InPersonPaymentsMenuViewModel(
            siteID: siteID,
            dependencies: .init(
                cardPresentPaymentsConfiguration: CardPresentConfigurationLoader().configuration,
                onboardingUseCase: CardPresentPaymentsOnboardingUseCase(),
                cardReaderSupportDeterminer: CardReaderSupportDeterminer(siteID: siteID),
                wooPaymentsDepositService: WooPaymentsDepositService(siteID: siteID,
                                                                     credentials: credentials)),
            navigationPath: navigationPathBinding)
    }()

    private(set) var cardPresentPaymentService: CardPresentPaymentFacade?

    init(siteID: Int64,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores,
         generalAppSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         inboxEligibilityChecker: InboxEligibilityChecker = InboxEligibilityUseCase(),
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker()) {
        self.siteID = siteID
        self.credentials = stores.sessionManager.defaultCredentials
        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.generalAppSettings = generalAppSettings
        self.switchStoreEnabled = stores.isAuthenticatedWithoutWPCom == false
        self.inboxEligibilityChecker = inboxEligibilityChecker
        self.blazeEligibilityChecker = blazeEligibilityChecker
        self.cardPresentPaymentsOnboarding = CardPresentPaymentsOnboardingUseCase()
        self.posEligibilityChecker = POSEligibilityChecker(cardPresentPaymentsOnboarding: cardPresentPaymentsOnboarding,
                                                           siteSettings: ServiceLocator.selectedSiteSettings,
                                                           currencySettings: ServiceLocator.currencySettings,
                                                           featureFlagService: featureFlagService)
        observeSiteForUIUpdates()
        observePlanName()
        tapToPayBadgePromotionChecker.$shouldShowTapToPayBadges.share().assign(to: &$shouldShowNewFeatureBadgeOnPayments)
        createCardPresentPaymentService()
    }

    func viewDidAppear() {
        NotificationCenter.default.post(name: .hubMenuViewDidAppear, object: nil)
    }

    private func createCardPresentPaymentService() {
        Task {
            self.cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID)
        }
    }

    /// Resets the menu elements displayed on the menu.
    ///
    func setupMenuElements() {
        setupPOSElement()
        setupSettingsElements()
        setupGeneralElements()
    }

    /// Shows the payments menu from the hub menu root view.
    func showPayments() {
        navigationPath = .init()
        navigationPath.append(HubMenuNavigationDestination.payments)
    }

    private func setupPOSElement() {
        cardPresentPaymentsOnboarding.refreshIfNecessary()
        Publishers.CombineLatest(generalAppSettings.betaFeatureEnabledPublisher(.pointOfSale), posEligibilityChecker.isEligible)
            .map { isBetaFeatureEnabled, isEligibleForPOS in
                if isBetaFeatureEnabled && isEligibleForPOS {
                    return PointOfSaleEntryPoint()
                } else {
                    return nil
                }
            }
            .assign(to: &$posElement)
    }

    private func setupSettingsElements() {
        settingsElements = [Settings()]

        guard let site = stores.sessionManager.defaultSite,
              // Only show the upgrades menu on WPCom sites and non free trial sites
              site.isWordPressComStore,
              !site.isFreeTrialSite else {
            return
        }

        settingsElements.append(Subscriptions())
    }

    private func setupGeneralElements() {
        generalElements = [Payments(iconBadge: shouldShowNewFeatureBadgeOnPayments ? .dot : nil),
                           WoocommerceAdmin(),
                           ViewStore(),
                           Reviews()]
        if generalAppSettings.betaFeatureEnabled(.inAppPurchases) {
            generalElements.append(InAppPurchases())
        }

        inboxEligibilityChecker.isEligibleForInbox(siteID: siteID) { [weak self] isInboxMenuShown in
            guard let self = self else { return }
            if let index = self.generalElements.firstIndex(where: { item in
                type(of: item).id == Reviews.id
            }), isInboxMenuShown {
                self.generalElements.insert(Inbox(), at: index + 1)
            }
        }

        if let index = self.generalElements.firstIndex(where: { item in
            type(of: item).id == Reviews.id
        }) {
            self.generalElements.insert(Coupons(), at: index)
        } else {
            self.generalElements.append(Coupons())
        }


        // Blaze menu.
        if isSiteEligibleForBlaze {
            if let index = generalElements.firstIndex(where: { $0.id == Payments.id }) {
                generalElements.insert(Blaze(), at: index + 1)
            } else {
                generalElements.append(Blaze())
            }
        } else {
            generalElements.removeAll(where: { $0.id == Blaze.id })
        }

        generalElements.append(Customers())
    }

    func showReviewDetails(using parcel: ProductReviewFromNoteParcel) {
        productReviewFromNoteParcel = parcel
        showingReviewDetail = true
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

        // Blaze menu.
        stores.site
            .compactMap { $0 }
            .removeDuplicates()
            .asyncMap { [weak self] site -> Bool in
                guard let self else {
                    return false
                }
                return await self.blazeEligibilityChecker.isSiteEligible()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSiteEligibleForBlaze)
    }

    /// Observe the current site's plan name and assign it to the `planName` published property.
    ///
    private func observePlanName() {
        ServiceLocator.storePlanSynchronizer.planStatePublisher.map { [weak self] planState in
            guard let self else { return "" }
            switch planState {
            case .loaded(let plan):
                return WPComPlanNameSanitizer.getPlanName(from: plan).uppercased()
            case .loading, .failed:
                return self.planName // Do not override the plan name when loading or failed(most likely no connected to the internet)
            default:
                return ""
            }
        }
        .assign(to: &$planName)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .setUpTapToPayViewDidAppear, object: nil)
    }
}

protocol HubMenuItem {
    static var id: String { get }
    var title: String { get }
    var description: String { get }
    var icon: UIImage { get }
    var iconColor: UIColor { get }
    var accessibilityIdentifier: String { get }
    var trackingOption: String { get }
    var iconBadge: HubMenuBadgeType? { get }
}

extension HubMenuItem {
    var id: String {
        type(of: self).id
    }
}

extension HubMenuViewModel {

    struct Settings: HubMenuItem {
        static var id = "settings"

        let title: String = Localization.settings
        let description: String = Localization.settingsDescription
        let icon: UIImage = .cogImage
        let iconColor: UIColor = .primary
        let accessibilityIdentifier: String = "dashboard-settings-button"
        let trackingOption: String = "settings"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct Payments: HubMenuItem {

        static var id = "payments"

        let title: String = Localization.payments
        let description: String = Localization.paymentsDescription
        let icon: UIImage = .walletImage
        let iconColor: UIColor = .withColorStudio(.orange)
        let accessibilityIdentifier: String = "menu-payments"
        let trackingOption: String = "payments"
        let iconBadge: HubMenuBadgeType?

        init(iconBadge: HubMenuBadgeType? = nil) {
            self.iconBadge = iconBadge
        }
    }

    struct Blaze: HubMenuItem {
        static var id = "blaze"

        let title: String = Localization.blaze
        let description: String = Localization.blazeDescription
        let icon: UIImage = .blaze
        let iconColor: UIColor = .clear
        let accessibilityIdentifier: String = "menu-blaze"
        let trackingOption: String = "blaze"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct WoocommerceAdmin: HubMenuItem {
        static var id = "woocommerceAdmin"

        let title: String = Localization.woocommerceAdmin
        let description: String = Localization.woocommerceAdminDescription
        let icon: UIImage = .wordPressLogoImage
        let iconColor: UIColor = .wooBlue
        let accessibilityIdentifier: String = "menu-woocommerce-admin"
        let trackingOption: String = "admin_menu"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct ViewStore: HubMenuItem {
        static var id = "viewStore"

        let title: String = Localization.viewStore
        let description: String = Localization.viewStoreDescription
        let icon: UIImage = .storeImage
        let iconColor: UIColor = .accent
        let accessibilityIdentifier: String = "menu-view-store"
        let trackingOption: String = "view_store"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct Inbox: HubMenuItem {
        static var id = "inbox"

        let title: String = Localization.inbox
        let description: String = Localization.inboxDescription
        let icon: UIImage = .mailboxImage
        let iconColor: UIColor = .withColorStudio(.blue, shade: .shade40)
        let accessibilityIdentifier: String = "menu-inbox"
        let trackingOption: String = "inbox"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct Coupons: HubMenuItem {
        static var id = "coupons"

        let title: String = Localization.coupon
        let description: String = Localization.couponDescription
        let icon: UIImage = .couponImage
        let iconColor: UIColor = UIColor(light: .withColorStudio(.green, shade: .shade30),
                                         dark: .withColorStudio(.green, shade: .shade50))
        let accessibilityIdentifier: String = "menu-coupons"
        let trackingOption: String = "coupons"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct Reviews: HubMenuItem {
        static var id = "reviews"

        let title: String = Localization.reviews
        let description: String = Localization.reviewsDescription
        let icon: UIImage = .starImage(size: 24.0)
        let iconColor: UIColor = .primary
        let accessibilityIdentifier: String = "menu-reviews"
        let trackingOption: String = "reviews"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct InAppPurchases: HubMenuItem {
        static var id = "iap"

        let title: String = "[Debug] IAP"
        let description: String = "Debug your inApp Purchases"
        let icon: UIImage = UIImage(systemName: "ladybug.fill")!
        let iconColor: UIColor = .red
        let accessibilityIdentifier: String = "menu-iap"
        let trackingOption: String = "debug-iap"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct PointOfSaleEntryPoint: HubMenuItem {
        static var id = "pointOfSale"

        let title: String = Localization.pos
        let description: String = Localization.posDescription
        let icon: UIImage = .pointOfSaleImage
        let iconColor: UIColor = .withColorStudio(.green, shade: .shade30)
        let accessibilityIdentifier: String = "menu-pointOfSale"
        let trackingOption: String = "pointOfSale"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct Subscriptions: HubMenuItem {
        static var id = "subscriptions"

        let title: String = Localization.subscriptions
        let description: String = Localization.subscriptionsDescription
        let icon: UIImage = .shoppingCartPurpleIcon
        let iconColor: UIColor = .primary
        let accessibilityIdentifier: String = "menu-subscriptions"
        let trackingOption: String = "upgrades"
        let iconBadge: HubMenuBadgeType? = nil
    }

    struct Customers: HubMenuItem {
        static var id = "customers"

        let title: String = Localization.customers
        let description: String = Localization.customersDescription
        let icon: UIImage = .multipleUsersImage.withRenderingMode(.alwaysTemplate)
        let iconColor: UIColor = .primary
        let accessibilityIdentifier: String = "menu-customers"
        let trackingOption: String = "customers"
        let iconBadge: HubMenuBadgeType? = nil
    }

    enum Localization {
        static let settings = NSLocalizedString(
            "Settings",
            comment: "Title of the hub menu settings button")

        static let settingsDescription = NSLocalizedString(
            "Update your preferences",
            comment: "Description of the hub menu settings button")

        static let payments = NSLocalizedString(
            "Payments",
            comment: "Title of the hub menu payments button")

        static let paymentsDescription = NSLocalizedString(
            "Take payments on the go",
            comment: "Description of the hub menu payments button")

        static let blaze = NSLocalizedString(
            "Blaze",
            comment: "Title of the hub menu Blaze button")

        static let blazeDescription = NSLocalizedString(
            "Promote products with Blaze",
            comment: "Description of the hub menu Blaze button")

        static let myStore = NSLocalizedString(
            "My Store",
            comment: "Title of the hub menu view in case there is no title for the store")

        static let pos = NSLocalizedString(
            "Point of Sale Mode",
            comment: "Title of the POS menu in the hub menu")

        static let posDescription = NSLocalizedString(
            "Use the app as a cash register",
            comment: "Description of the POS menu in the hub menu")

        static let woocommerceAdmin = NSLocalizedString(
            "WooCommerce Admin",
            comment: "Title of one of the hub menu options")

        static let woocommerceAdminDescription = NSLocalizedString(
            "Manage more on admin",
            comment: "Description of one of the hub menu options")

        static let viewStore = NSLocalizedString(
            "View Store",
            comment: "Title of one of the hub menu options")

        static let viewStoreDescription = NSLocalizedString(
            "View your store",
            comment: "Description of one of the hub menu options")

        static let inbox = NSLocalizedString(
            "Inbox",
            comment: "Title of the Inbox menu in the hub menu")

        static let inboxDescription = NSLocalizedString(
            "Stay up-to-date",
            comment: "Description of the Inbox menu in the hub menu")

        static let coupon = NSLocalizedString(
            "Coupons",
            comment: "Title of the Coupons menu in the hub menu")

        static let couponDescription = NSLocalizedString(
            "Boost sales with special offers",
            comment: "Description of the Coupons menu in the hub menu")

        static let reviews = NSLocalizedString(
            "Reviews",
            comment: "Title of one of the hub menu options")

        static let reviewsDescription = NSLocalizedString(
            "Capture reviews for your store",
            comment: "Description of one of the hub menu options")

        static let subscriptions = NSLocalizedString(
            "Subscriptions",
            comment: "Title of one of the hub menu options")

        static let subscriptionsDescription = NSLocalizedString(
            "Manage your subscription",
            comment: "Description of one of the hub menu options")

        static let customers = NSLocalizedString(
            "hubMenu.customers",
            value: "Customers",
            comment: "Title of one of the hub menu options")

        static let customersDescription = NSLocalizedString(
            "hubMenu.customersDescription",
            value: "Get customer insights",
            comment: "Description of one of the hub menu options")
    }
}

enum HubMenuBadgeType {
    case dot
}
