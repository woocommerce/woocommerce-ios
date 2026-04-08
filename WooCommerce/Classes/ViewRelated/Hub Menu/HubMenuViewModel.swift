import Foundation
import UIKit
import SwiftUI
import Combine
import Experiments
import Yosemite
import protocol WooFoundation.Analytics
import struct Storage.GeneralAppSettingsStorage

extension NSNotification.Name {
    /// Posted whenever the hub menu view did appear.
    ///
    public static let hubMenuViewDidAppear = Foundation.Notification.Name(rawValue: "com.woocommerce.ios.hubMenuViewDidAppear")
}

/// Destination views that the hub menu can navigate to.
enum HubMenuNavigationDestination: Hashable {
    case payments
    case settings
    case blaze
    case blazeCampaignDetails(campaignID: String)
    case blazeCampaignCreation
    case wooCommerceAdmin
    case viewStore
    case inbox
    case reviews
    case coupons
    case customers
    case bookings
    case reviewDetails(parcel: ProductReviewFromNoteParcel)
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

    @Published private(set) var viewAppeared = false

    @Published private(set) var shouldAuthenticateAdminPage = false

    @Published private(set) var hasGoogleAdsCampaigns = false
    @Published private var currentSite: Yosemite.Site?

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let generalAppSettings: GeneralAppSettingsStorage
    private let cardPresentPaymentsOnboarding: CardPresentPaymentsOnboardingUseCaseProtocol
    private let inboxEligibilityChecker: InboxEligibilityChecker
    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol
    private let googleAdsEligibilityChecker: GoogleAdsEligibilityChecker

    private let siteCIABEligibilityChecker: CIABEligibilityCheckerProtocol

    private var isIPPHiddenForCIAB: Bool {
        siteCIABEligibilityChecker.isIPPHiddenForCurrentSite
    }
    private let posEligibilityService: POSEligibilityServiceProtocol
    private let bookingsEligibilityCheckerFactory: (Site) -> BookingsTabEligibilityCheckerProtocol
    private let isPad: Bool

    private let appPasswordSupportState = ApplicationPasswordsExperimentState()

    private(set) lazy var inboxViewModel = InboxViewModel(siteID: siteID)

    @Published private(set) var shouldShowNewFeatureBadgeOnPayments: Bool = false

    @Published private var isSiteEligibleForBlaze = false
    @Published private var isSiteEligibleForGoogleAds = false
    @Published private var isSiteEligibleForInbox = false
    @Published private var isSiteEligibleForBookings = false
    @Published private var isPOSTabCachedVisible = false

    private var cancellables: Set<AnyCancellable> = []

    let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    lazy var inPersonPaymentsMenuViewModel: InPersonPaymentsMenuViewModel = {
        InPersonPaymentsMenuViewModel(
            siteID: siteID,
            dependencies: .init(
                cardPresentPaymentsConfiguration: CardPresentConfigurationLoader().configuration,
                onboardingUseCase: CardPresentPaymentsOnboardingUseCase(),
                cardReaderSupportDeterminer: CardReaderSupportDeterminer(siteID: siteID),
                wooPaymentsPayoutService: WooPaymentsPayoutService(
                    siteID: siteID,
                    credentials: credentials,
                    selectedSite: stores.sessionManager.defaultSitePublisher
                        .map { $0?.toJetpackSite() }
                        .eraseToAnyPublisher(),
                    appPasswordSupportState: appPasswordSupportState
                        .$isAvailableAndEnabled
                        .eraseToAnyPublisher()
                )
            )
        )
    }()

    private let analytics: Analytics

    init(siteID: Int64,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores,
         generalAppSettings: GeneralAppSettingsStorage = ServiceLocator.generalAppSettings,
         inboxEligibilityChecker: InboxEligibilityChecker = InboxEligibilityUseCase(),
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker(),
         googleAdsEligibilityChecker: GoogleAdsEligibilityChecker = DefaultGoogleAdsEligibilityChecker(),
         siteCIABEligibilityChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(),
         posEligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         bookingsEligibilityCheckerFactory: @escaping (Site) -> BookingsTabEligibilityCheckerProtocol = { site in
             BookingsTabEligibilityChecker(site: site)
         },
         // Injected for mocking in tests.
         isPad: Bool = UIDevice.isPad(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.credentials = stores.sessionManager.defaultCredentials
        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.generalAppSettings = generalAppSettings
        self.switchStoreEnabled = stores.isAuthenticatedWithoutWPCom == false
        self.inboxEligibilityChecker = inboxEligibilityChecker
        self.blazeEligibilityChecker = blazeEligibilityChecker
        self.googleAdsEligibilityChecker = googleAdsEligibilityChecker
        self.siteCIABEligibilityChecker = siteCIABEligibilityChecker
        self.posEligibilityService = posEligibilityService
        self.bookingsEligibilityCheckerFactory = bookingsEligibilityCheckerFactory
        self.isPad = isPad
        self.cardPresentPaymentsOnboarding = CardPresentPaymentsOnboardingUseCase()
        self.analytics = analytics
        observeSiteForUIUpdates()
        observePlanName()
        observeGoogleAdsEntryPointAvailability()
        tapToPayBadgePromotionChecker.$shouldShowTapToPayBadges.share().assign(to: &$shouldShowNewFeatureBadgeOnPayments)
    }

    func viewDidAppear() async {
        NotificationCenter.default.post(name: .hubMenuViewDidAppear, object: nil)
        viewAppeared = true

        await withTaskGroup(of: Void.self) { group in
            if !hasGoogleAdsCampaigns {
                group.addTask {
                    await self.refreshGoogleAdsCampaignCheck()
                }
            }

            if !isSiteEligibleForBlaze {
                group.addTask {
                    await self.refreshBlazeEligibilityCheck()
                }
            }
        }
    }

    /// Resets the menu elements displayed on the menu.
    ///
    func setupMenuElements() {
        setupSettingsElements()
        setupGeneralElements()
    }

    /// Shows the payments menu from the hub menu root view.
    func showPayments() {
        navigateToDestination(.payments)
    }

    func navigateToDestination(_ destination: HubMenuNavigationDestination?) {
        guard let destination else {
            return
        }
        navigationPath = .init()
        navigationPath.append(destination)
    }

    func showReviewDetails(using parcel: ProductReviewFromNoteParcel) {
        navigateToDestination(.reviewDetails(parcel: parcel))
    }

    func refreshGoogleAdsCampaignCheck() async {
        hasGoogleAdsCampaigns = await checkIfSiteHasGoogleAdsCampaigns()
    }

    func refreshBlazeEligibilityCheck() async {
        guard let site = currentSite else {
            return
        }

        isSiteEligibleForBlaze = await blazeEligibilityChecker.isSiteEligible(site)
    }

    func trackMenuItemTapEvent(menu: HubMenuItem) {
        analytics.track(.hubMenuOptionTapped, withProperties: [AnalyticsKeys.trackingOption: menu.trackingOption])
    }

    /// Whether the current site is a CIAB (Commerce in a Box) site.
    /// On CIAB sites, WC Admin opens in an SFSafariViewController (Safari sheet) instead of the
    /// in-app webview, because the in-app webview hides the Admin navigation sidebar which is
    /// needed for full WC Admin navigation.
    func isCIABSite() -> Bool {
        siteCIABEligibilityChecker.isCurrentSiteCIAB
    }

    func createGoogleAdsCampaignCoordinator(with navigationController: UINavigationController) -> GoogleAdsCampaignCoordinator {
        GoogleAdsCampaignCoordinator(
            siteID: siteID,
            siteAdminURL: woocommerceAdminURL.absoluteString,
            source: .moreMenu,
            shouldStartCampaignCreation: !hasGoogleAdsCampaigns,
            shouldAuthenticateAdminPage: shouldAuthenticateAdminPage,
            navigationController: navigationController,
            onCompletion: { [weak self] createdNewCampaign in
                guard createdNewCampaign else {
                    return
                }
                self?.refreshGoogleAdsCampaignCheck()
            }
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .setUpTapToPayViewDidAppear, object: nil)
    }
}

// MARK: - Helper methods
//
private extension HubMenuViewModel {
    func setupSettingsElements() {
        settingsElements = [Settings()]
    }

    func setupGeneralElements() {
        Publishers.CombineLatest(
            $shouldShowNewFeatureBadgeOnPayments,
            $isSiteEligibleForBookings
        )
        .combineLatest(
            Publishers.CombineLatest3(
                $isSiteEligibleForInbox,
                $isSiteEligibleForBlaze,
                $isSiteEligibleForGoogleAds
            )
        )
        .map { [weak self] combinedResults -> [HubMenuItem] in
            guard let self else { return [] }

            let ((shouldShowBadgeOnPayments, eligibleForBookings), (eligibleForInbox, eligibleForBlaze, eligibleForGoogleAds)) = combinedResults

            return createGeneralElements(
                shouldShowBadgeOnPayments: shouldShowBadgeOnPayments,
                eligibleForGoogleAds: eligibleForGoogleAds,
                eligibleForBlaze: eligibleForBlaze,
                eligibleForInbox: eligibleForInbox,
                eligibleForBookings: eligibleForBookings
            )
        }
        .assign(to: &$generalElements)
    }

    enum PaymentsFeatureEligibility {
        case ineligible
        case eligible(shouldShowBadgeOnPayments: Bool)
    }

    func createGeneralElements(shouldShowBadgeOnPayments: Bool,
                               eligibleForGoogleAds: Bool,
                               eligibleForBlaze: Bool,
                               eligibleForInbox: Bool,
                               eligibleForBookings: Bool) -> [HubMenuItem] {
        var items: [HubMenuItem] = []

        if !isIPPHiddenForCIAB {
            items.append(Payments(iconBadge: shouldShowBadgeOnPayments ? .dot : nil))
        }

        if shouldShowBookingsInMenu, eligibleForBookings {
            items.append(Bookings())
        }

        if eligibleForGoogleAds {
            items.append(GoogleAds())
        }

        if eligibleForBlaze {
            items.append(Blaze())
        }

        items.append(WoocommerceAdmin())
        items.append(ViewStore())
        items.append(Coupons())
        items.append(Reviews())

        if eligibleForInbox {
            items.append(Inbox())
        }

        items.append(Customers())

        return items
    }

    func observeSiteForUIUpdates() {
        stores.site
            .filter { [weak self] site in
                /// When switching sites, `HubMenuViewModel` is created with a new site ID.
                /// However, the site info needs some time to be fetched and updated in stores manager.
                /// That's why this stream's first element would be the info of previous site.
                /// Adding this filter avoids redundantly checking eligibility of previous site.
                site?.siteID == self?.siteID
            }
            .removeDuplicates()
            .assign(to: &$currentSite)

        $currentSite
            .compactMap { site -> URL? in
                guard let urlString = site?.url, let url = URL(string: urlString) else {
                    return nil
                }
                return url
            }
            .assign(to: &$storeURL)

        $currentSite
            .compactMap { $0?.name }
            .assign(to: &$storeTitle)

        $currentSite
            .compactMap { site -> URL? in
                guard let urlString = site?.adminURL, let url = URL(string: urlString) else {
                    return site?.adminURLWithFallback()
                }
                return url
            }
            .assign(to: &$woocommerceAdminURL)

        $currentSite
            .map { [weak self] site in
                guard let self, let site else {
                    return false
                }
                return stores.shouldAuthenticateAdminPage(for: site)
            }
            .assign(to: &$shouldAuthenticateAdminPage)

        $currentSite
            .compactMap { $0 }
            .sink { [weak self] site in
                self?.updateMenuItemEligibility(with: site)
            }
            .store(in: &cancellables)
    }

    func updateMenuItemEligibility(with site: Yosemite.Site) {
        isSiteEligibleForInbox = inboxEligibilityChecker.isEligibleForInbox(siteID: site.siteID)
        isPOSTabCachedVisible = posEligibilityService.loadCachedPOSTabVisibility(siteID: site.siteID) ?? false

        if shouldShowBookingsInMenu {
            let bookingsEligibilityChecker = bookingsEligibilityCheckerFactory(site)
            Task { @MainActor in
                isSiteEligibleForBookings = await bookingsEligibilityChecker.checkVisibility()
            }
        } else {
            isSiteEligibleForBookings = false
        }

        Task { @MainActor in
            isSiteEligibleForGoogleAds = await googleAdsEligibilityChecker.isSiteEligible(siteID: site.siteID)
            hasGoogleAdsCampaigns = await checkIfSiteHasGoogleAdsCampaigns()
        }

        Task { @MainActor in
            isSiteEligibleForBlaze = await blazeEligibilityChecker.isSiteEligible(site)
        }
    }

    @MainActor
    func checkIfSiteHasGoogleAdsCampaigns() async -> Bool {
        guard isSiteEligibleForGoogleAds else {
            return false
        }
        do {
            let campaigns = try await fetchGoogleAdsCampaigns()
            return campaigns.isNotEmpty
        } catch {
            DDLogError("⛔️ Error fetching Google Ads campaigns: \(error)")
            return false
        }
    }

    /// Observe the current site's plan name and assign it to the `planName` published property.
    ///
    func observePlanName() {
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

    func observeGoogleAdsEntryPointAvailability() {
        $isSiteEligibleForGoogleAds.removeDuplicates()
            .combineLatest($viewAppeared)
            .filter { isEligible, viewAppeared in
                // only tracks the display if the view appeared
                return isEligible && viewAppeared
            }
            .sink { _ in
                ServiceLocator.analytics.track(event: .GoogleAds.entryPointDisplayed(source: .moreMenu))
            }
            .store(in: &cancellables)
    }

    @MainActor
    func fetchGoogleAdsCampaigns() async throws -> [GoogleAdsCampaign] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(GoogleAdsAction.fetchAdsCampaigns(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
    }

    var shouldShowBookingsInMenu: Bool {
        isPad && isPOSTabCachedVisible
    }
}

// MARK: - Helpers
extension HubMenuViewModel {
    func viewDidAppear() {
        Task { @MainActor in
            await viewDidAppear()
        }
    }

    func refreshBlazeEligibilityCheck() {
        Task { @MainActor in
            await refreshBlazeEligibilityCheck()
        }
    }

    func refreshGoogleAdsCampaignCheck() {
        Task { @MainActor in
            await refreshGoogleAdsCampaignCheck()
        }
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
    var navigationDestination: HubMenuNavigationDestination? { get }
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
        let navigationDestination: HubMenuNavigationDestination? = .settings
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
        let navigationDestination: HubMenuNavigationDestination? = .payments

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
        let navigationDestination: HubMenuNavigationDestination? = .blaze
    }

    struct GoogleAds: HubMenuItem {
        static var id = "google-ads"

        let title: String = Localization.googleAds
        let description: String = Localization.googleAdsDescription
        let icon: UIImage = .googleLogo
        let iconColor: UIColor = .clear
        let accessibilityIdentifier: String = "menu-google-ads"
        let trackingOption: String = "google-ads"
        let iconBadge: HubMenuBadgeType? = nil
        let navigationDestination: HubMenuNavigationDestination? = nil
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
        let navigationDestination: HubMenuNavigationDestination? = .wooCommerceAdmin
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
        let navigationDestination: HubMenuNavigationDestination? = .viewStore
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
        let navigationDestination: HubMenuNavigationDestination? = .inbox
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
        let navigationDestination: HubMenuNavigationDestination? = .coupons
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
        let navigationDestination: HubMenuNavigationDestination? = .reviews
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
        let navigationDestination: HubMenuNavigationDestination? = .customers
    }

    struct Bookings: HubMenuItem {
        static var id = "bookings"

        let title: String = Localization.bookings
        let description: String = Localization.bookingsDescription
        let icon: UIImage = (UIImage(systemName: "calendar") ?? .productImage)
            .withRenderingMode(.alwaysTemplate)
        let iconColor: UIColor = .accent
        let accessibilityIdentifier: String = "menu-bookings"
        let trackingOption: String = "bookings"
        let iconBadge: HubMenuBadgeType? = nil
        let navigationDestination: HubMenuNavigationDestination? = .bookings
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

        static let googleAds = NSLocalizedString(
            "hubMenuViewModel.googleAds",
            value: "Google for WooCommerce",
            comment: "Title of the hub menu Google Ads button"
        )

        static let googleAdsDescription = NSLocalizedString(
            "hubMenuViewModel.googleAdsDescription",
            value: "Drive sales and generate more traffic with Google Ads",
            comment: "Description of the hub menu Google Ads button"
        )

        static let myStore = NSLocalizedString(
            "My Store",
            comment: "Title of the hub menu view in case there is no title for the store")

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

        static let customers = NSLocalizedString(
            "hubMenu.customers",
            value: "Customers",
            comment: "Title of one of the hub menu options")

        static let customersDescription = NSLocalizedString(
            "hubMenu.customersDescription",
            value: "Get customer insights",
            comment: "Description of one of the hub menu options")

        static let bookings = NSLocalizedString(
            "hubMenu.bookings",
            value: "Bookings",
            comment: "Title of the Bookings menu in the hub menu"
        )

        static let bookingsDescription = NSLocalizedString(
            "hubMenu.bookingsDescription",
            value: "Manage your client appointments",
            comment: "Description of the Bookings menu in the hub menu"
        )
    }

    enum AnalyticsKeys {
        static let trackingOption = "option"
    }
}

enum HubMenuBadgeType {
    case dot
}
