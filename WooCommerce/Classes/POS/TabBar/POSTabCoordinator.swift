import Foundation
import UIKit
import SwiftUI
import Yosemite
import Combine
import class WooFoundation.CurrencySettings
import enum WooFoundation.ConnectivityStatus
import protocol WooFoundation.ConnectivityObserver
import WooFoundationCore
import protocol Storage.GRDBManagerProtocol
import protocol Storage.StorageManagerType
import struct NetworkingCore.JetpackSite
import struct NetworkingCore.OrderItem
import PointOfSale

protocol POSTabVisibilityCheckerProtocol {
    /// Checks the initial visibility of the POS tab.
    func checkInitialVisibility() -> Bool
    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool
}

/// View controller that provides the tab bar item for the Point of Sale tab.
/// It is never visible on the screen, only used to provide the tab bar item as all POS UI is full-screen.
final class POSTabViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarItem.title = NSLocalizedString("pos.tab.title", value: "POS", comment: "Title for the Point of Sale tab.")
        tabBarItem.image = UIImage(systemName: "cart")
        tabBarItem.accessibilityIdentifier = "tab-bar-pos-item"
    }
}

/// Coordinator for the Point of Sale tab.
///
final class POSTabCoordinator {
    private let siteID: Int64
    private let tabContainerController: TabContainerController
    private let viewControllerToPresent: UIViewController
    private let storesManager: StoresManager
    private let credentials: Credentials?
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    private let pushNotesManager: PushNotesManager
    private let eligibilityChecker: POSEntryPointEligibilityCheckerProtocol
    private let eligibilityService: POSEligibilityServiceProtocol
    private let connectivityObserver: ConnectivityObserver
    private let userInterfaceIdiom: UIUserInterfaceIdiom

    private lazy var posSyncDispatcher = ForegroundPOSCatalogSyncDispatcher()

    /// Local catalog eligibility service - created asynchronously during init
    private(set) var localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?

    /// Creates item fetch strategy factory with current local catalog eligibility
    private func createItemFetchStrategyFactory(isLocalCatalogEnabled: Bool) -> PointOfSaleItemFetchStrategyFactory {
        let isFTSSearchEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleFTSSearch)
        return PointOfSaleItemFetchStrategyFactory(siteID: siteID,
                                                   credentials: credentials,
                                                   selectedSite: defaultSitePublisher,
                                                   appPasswordSupportState: isAppPasswordSupported,
                                                   grdbManager: isLocalCatalogEnabled ? ServiceLocator.grdbManager : nil,
                                                   currencySettings: currencySettings,
                                                   isLocalCatalogEnabled: isLocalCatalogEnabled,
                                                   isFTSSearchEnabled: isFTSSearchEnabled)
    }

    /// Creates popular item fetch strategy factory with current local catalog eligibility
    private func createPopularItemFetchStrategyFactory(isLocalCatalogEnabled: Bool) -> PointOfSaleFixedItemFetchStrategyFactory {
        let itemFactory = createItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEnabled)
        return PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: itemFactory.popularStrategy())
    }

    private lazy var posCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactory = {
        PointOfSaleCouponFetchStrategyFactory(siteID: siteID,
                                              currencySettings: currencySettings,
                                              credentials: credentials,
                                              selectedSite: defaultSitePublisher,
                                              appPasswordSupportState: isAppPasswordSupported,
                                              storage: storageManager)
    }()

    private lazy var posCouponProvider: PointOfSaleCouponServiceProtocol = {
        return PointOfSaleCouponService(siteID: siteID,
                                        currencySettings: currencySettings,
                                        credentials: credentials,
                                        selectedSite: defaultSitePublisher,
                                        appPasswordSupportState: isAppPasswordSupported,
                                        storage: storageManager)
    }()

    /// Creates the appropriate barcode scan service based on local catalog availability
    private func createBarcodeScanService(isLocalCatalogEligible: Bool,
                                          grdbManager: GRDBManagerProtocol?) -> any PointOfSaleBarcodeScanServiceProtocol {
        if isLocalCatalogEligible,
           let grdbManager {
            return PointOfSaleLocalBarcodeScanService(siteID: siteID,
                                                     grdbManager: grdbManager,
                                                     currencySettings: currencySettings)
        } else {
            // Fall back to remote barcode scanning
            return PointOfSaleBarcodeScanService(siteID: siteID,
                                                credentials: credentials,
                                                selectedSite: defaultSitePublisher,
                                                appPasswordSupportState: isAppPasswordSupported,
                                                currencySettings: currencySettings)
        }
    }

    /// Publisher to send to `AlamofireNetwork` for request authentication mode switching.
    private let defaultSitePublisher: AnyPublisher<JetpackSite?, Never>

    private let appPasswordSupportState: ApplicationPasswordsExperimentState

    /// Publisher to send to `AlamofireNetwork` the state of app password support for JP sites
    private let isAppPasswordSupported: AnyPublisher<Bool, Never>

    init(siteID: Int64,
         tabContainerController: TabContainerController,
         viewControllerToPresent: UIViewController,
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
         eligibilityChecker: POSEntryPointEligibilityCheckerProtocol,
         eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.defaultSitePublisher = storesManager.sessionManager.defaultSitePublisher
            .map { $0?.toJetpackSite() }
            .eraseToAnyPublisher()
        self.appPasswordSupportState = ApplicationPasswordsExperimentState()
        self.isAppPasswordSupported = appPasswordSupportState
            .$isAvailableAndEnabled
            .eraseToAnyPublisher()
        self.tabContainerController = tabContainerController
        self.viewControllerToPresent = viewControllerToPresent
        self.credentials = storesManager.sessionManager.defaultCredentials
        self.storageManager = storageManager
        self.currencySettings = currencySettings
        self.pushNotesManager = pushNotesManager
        self.eligibilityChecker = eligibilityChecker
        self.eligibilityService = eligibilityService
        self.connectivityObserver = connectivityObserver
        self.userInterfaceIdiom = userInterfaceIdiom
        self.localCatalogEligibilityService = localCatalogEligibilityService

        tabContainerController.wrappedController = POSTabViewController()
    }

    /// Check and update POS eligibility for local catalog
    /// Only checks eligibility if the POS tab is visible
    func updatePOSEligibility(isPOSTabVisible: Bool) {
        Task { @MainActor [weak self] in
            guard let self, let catalogEligibilityService = self.localCatalogEligibilityService else { return }

            // If POS tab is not visible, mark as ineligible
            guard isPOSTabVisible else {
                try await catalogEligibilityService.updatePOSEligibility(isEligible: false,
                                                                         for: siteID)
                await posSyncDispatcher.stop()
                return
            }

            guard connectivityObserver.currentStatus.isReachable else {
                await posSyncDispatcher.stop()
                return
            }

            // Check actual POS eligibility using the eligibility checker
            let eligibilityState = await eligibilityChecker.checkEligibility()
            let isPOSEligible = eligibilityState == .eligible
            do {
                try await catalogEligibilityService.updatePOSEligibility(isEligible: isPOSEligible,
                                                                         for: siteID)
                // Only start syncs after we've updated the catalog eligibility.
                await isPOSEligible ? posSyncDispatcher.start() : posSyncDispatcher.stop()
            } catch {
                await posSyncDispatcher.stop()
            }
        }
    }

    func onTabSelected() {
        setPOSHasBeenOpened()
        presentPOSView(siteID: siteID)
    }
}

private extension POSTabCoordinator {
    func setPOSHasBeenOpened() {
        Task { @MainActor in
            let action = AppSettingsAction.setHasPOSBeenOpenedAtLeastOnce { _ in }
            storesManager.dispatch(action)

            // Track last opened date for sync eligibility
            let lastOpenedAction = AppSettingsAction.setPOSLastOpenedDate(siteID: siteID, date: Date()) {}
            storesManager.dispatch(lastOpenedAction)
        }
    }

    func presentPOSView(siteID: Int64) {
        let hostingController = UIHostingController(
            rootView: POSPresentationRootView(posView: nil)
        )
        hostingController.modalPresentationStyle = .fullScreen
        viewControllerToPresent.present(hostingController, animated: true, completion: nil)

        Task { @MainActor [weak self, weak hostingController] in
            guard let self, let hostingController else { return }

            let isLocalCatalogEligible = await resolveLocalCatalogAvailabilityForPOSEntry(siteID: siteID)

            let sunsetWarningChecker = POSSunsetWarningChecker(
                systemStatusService: POSSystemStatusService(
                    credentials: credentials,
                    selectedSite: defaultSitePublisher,
                    appPasswordSupportState: isAppPasswordSupported,
                    storageManager: storageManager
                )
            )

            let serviceAdaptor = POSServiceLocatorAdaptor()
            let collectPaymentAnalyticsAdaptor = POSCollectOrderPaymentAnalyticsAdaptor(analytics: serviceAdaptor.analytics)

            let cardPresentPaymentService: CardPresentPaymentFacade
            if ProcessConfiguration.shouldUseMockCardPresentPayment {
                #if DEBUG
                if ProcessConfiguration.shouldUsePOSUITestMocks {
                    cardPresentPaymentService = CardPresentPaymentServiceUITestMock()
                } else {
                    cardPresentPaymentService = CardPresentPaymentServiceScreenshotMock()
                }
                #else
                cardPresentPaymentService = CardPresentPaymentServiceScreenshotMock()
                #endif
            } else {
                cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID,
                                                                            stores: storesManager,
                                                                            collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor)
            }
            let settingsService = PointOfSaleSettingsService(siteID: siteID,
                                                             credentials: credentials,
                                                             selectedSite: defaultSitePublisher,
                                                             appPasswordSupportState: isAppPasswordSupported,
                                                             storage: storageManager)
            let pluginsService = PluginsService(storageManager: storageManager)
            let siteTimezone = storesManager.sessionManager.defaultSite?.siteTimezone ?? .current

            // Only initialize local catalog infrastructure if eligible
            let grdbManager: GRDBManagerProtocol? = isLocalCatalogEligible ? ServiceLocator.grdbManager : nil
            let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = isLocalCatalogEligible ? storesManager.posCatalogSyncCoordinator : nil

            // Create appropriate barcode scan service based on local catalog eligibility
            // Will use local GRDB-based scanning if eligible and infrastructure is available,
            // otherwise falls back to remote API-based scanning
            let barcodeScanService = createBarcodeScanService(isLocalCatalogEligible: isLocalCatalogEligible,
                                                              grdbManager: grdbManager)
            let refundsService = POSRefundsService(siteID: siteID,
                                                   credentials: credentials,
                                                   selectedSite: defaultSitePublisher,
                                                   appPasswordSupportState: isAppPasswordSupported,
                                                   currencySettings: currencySettings)

            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials,
                                                      selectedSite: defaultSitePublisher,
                                                      appPasswordSupportState: isAppPasswordSupported) {

                let orderService: POSOrderServiceProtocol
                if let mockOrderService = makeMockPOSOrderService(currency: currencySettings.currencyCode.rawValue) {
                    orderService = mockOrderService
                } else if let posOrderService = POSOrderService(siteID: siteID,
                                                           credentials: credentials,
                                                           selectedSite: defaultSitePublisher,
                                                           appPasswordSupportState: isAppPasswordSupported) {
                    orderService = posOrderService
                } else {
                    DDLogError("POSOrderService not provided")
                    await hostingController.dismiss(animated: true)
                    return
                }

                let itemProvider = makeMockPOSItemProvider()

                let receiptSettingsAdminURL = storesManager.sessionManager.defaultSite?.receiptSettingsAdminURL ?? ""

                let tapToPayAvailabilityChecker = POSTapToPayAvailabilityChecker(
                    siteID: siteID,
                    eligibilityService: POSEligibilityService()
                )
                let preferredConnectionMethod = await preferredConnectionMethodForPOSEntry(
                    isLocalCatalogEligible: isLocalCatalogEligible,
                    tapToPayAvailabilityChecker: tapToPayAvailabilityChecker
                )

                let refundSubmissionProcessor = POSRefundSubmissionAdaptor(orderService: orderService,
                                                                           stores: storesManager,
                                                                           storageManager: storageManager,
                                                                           currencySettings: currencySettings)

                guard let staffFetcher = POSStaffAdaptor(credentials: credentials,
                                                         selectedSite: defaultSitePublisher,
                                                         appPasswordSupportState: isAppPasswordSupported) else {
                    DDLogError("⛔️ Could not start POS: POSStaffAdaptor unavailable (missing credentials)")
                    await hostingController.dismiss(animated: true)
                    return
                }

                let receiptPrinter: ReceiptPrinterServiceProtocol? = ServiceLocator.featureFlagService
                    .isFeatureFlagEnabled(.starReceiptPrinterSupport) ? ServiceLocator.posReceiptPrinterService : nil

                // Present staff settings only when POS roles are enabled (nil hides the Staff card).
                // The wp-admin URL is derived from the site, like `receiptSettingsAdminURL` above.
                let staffSettingsService: POSStaffSettingsService?
                if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleRoles) {
                    let manageStaffURL = storesManager.sessionManager.defaultSite?.posStaffManagementAdminURL ?? ""
                    staffSettingsService = DefaultPOSStaffSettingsService(staffFetcher: staffFetcher,
                                                                          siteID: siteID,
                                                                          manageStaffURL: manageStaffURL)
                } else {
                    staffSettingsService = nil
                }

                let posView = PointOfSaleEntryPointView(
                    siteID: siteID,
                    itemFetchStrategyFactory: createItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEligible),
                    popularItemFetchStrategyFactory: createPopularItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEligible),
                    couponProvider: posCouponProvider,
                    couponFetchStrategyFactory: posCouponFetchStrategyFactory,
                    orderListFetchStrategyFactory: POSOrderListFetchStrategyFactory(
                        siteID: siteID,
                        credentials: credentials,
                        selectedSite: defaultSitePublisher,
                        appPasswordSupportState: isAppPasswordSupported,
                        currencyFormatter: CurrencyFormatter(currencySettings: currencySettings),
                        analytics: POSOrderListFetchAnalytics(analytics: serviceAdaptor.analytics)
                    ),
                    orderService: orderService,
                    refundsService: refundsService,
                    refundSubmissionProcessor: refundSubmissionProcessor,
                    onPointOfSaleModeActiveStateChange: { [weak self] isEnabled in
                        self?.updateDefaultConfigurationForPointOfSale(isEnabled)
                    },
                    cardPresentPaymentService: cardPresentPaymentService,
                    receiptService: receiptService,
                    pluginsService: pluginsService,
                    settingsService: settingsService,
                    collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor,
                    searchHistoryService: POSSearchHistoryService(siteID: siteID),
                    barcodeScanService: barcodeScanService,
                    posEligibilityChecker: eligibilityChecker,
                    siteTimezone: siteTimezone,
                    defaultSiteName: storesManager.sessionManager.defaultSite?.name,
                    siteSettings: ServiceLocator.selectedSiteSettings.siteSettings,
                    grdbManager: grdbManager,
                    catalogSyncCoordinator: catalogSyncCoordinator,
                    isLocalCatalogEligible: isLocalCatalogEligible,
                    receiptSettingsAdminURL: receiptSettingsAdminURL,
                    sunsetWarningChecker: sunsetWarningChecker,
                    tapToPayAvailabilityChecker: tapToPayAvailabilityChecker,
                    preferredConnectionMethod: preferredConnectionMethod,
                    staffFetcher: staffFetcher,
                    receiptPrinter: receiptPrinter,
                    staffSettingsService: staffSettingsService,
                    services: serviceAdaptor,
                    itemProvider: itemProvider
                )

                guard hostingController.presentingViewController != nil else {
                    return
                }
                hostingController.rootView = POSPresentationRootView(posView: posView)
            } else {
                await hostingController.dismiss(animated: true)
            }
        }
    }
}

extension POSTabCoordinator {
    func resolveLocalCatalogAvailabilityForPOSEntry(siteID: Int64) async -> Bool {
        if await cachedLocalCatalogPOSEntryIsAvailable(siteID: siteID) {
            return true
        }

        guard let service = localCatalogEligibilityService else {
            return false
        }

        guard connectivityObserver.currentStatus.isReachable else { return false }

        do {
            let posState = await eligibilityChecker.checkEligibility()
            guard case .eligible = posState else {
                return false
            }

            try await service.updatePOSEligibility(isEligible: true, for: siteID)

            let state = try await service.catalogEligibility(for: siteID)
            if state == .eligible {
                return true
            }

            if case .ineligible(reason: .catalogSizeCheckFailed) = state {
                if await cachedLocalCatalogPOSEntryIsAvailable(siteID: siteID) {
                    return true
                }
                _ = try await service.refreshEligibilityState(for: siteID)
                return try await service.catalogEligibility(for: siteID) == .eligible
            }

            return false
        } catch {
            return await cachedLocalCatalogPOSEntryIsAvailable(siteID: siteID)
        }
    }

    func cachedLocalCatalogPOSEntryIsAvailable(siteID: Int64) async -> Bool {
        guard storesManager.posCatalogSyncCoordinator != nil,
              eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) == true,
              await localCatalogHasPreviousFullSync(siteID: siteID) else {
            return false
        }

        return true
    }

    func preferredConnectionMethodForPOSEntry(isLocalCatalogEligible: Bool,
                                             tapToPayAvailabilityChecker: POSTapToPayAvailabilityChecking) async -> CardReaderConnectionMethod {
        guard !(isLocalCatalogEligible && !connectivityObserver.currentStatus.isReachable) else {
            return .bluetooth
        }

        guard userInterfaceIdiom == .phone else {
            return .bluetooth
        }

        switch await tapToPayAvailabilityChecker.checkAvailability() {
        case .available:
            return .tapToPay
        case .unknown, .unavailable:
            return .bluetooth
        }
    }

    private func localCatalogHasPreviousFullSync(siteID: Int64) async -> Bool {
        guard let posCatalogSyncCoordinator = storesManager.posCatalogSyncCoordinator else {
            return false
        }

        let syncState = await posCatalogSyncCoordinator.loadLastFullSyncState(for: siteID)
        if syncState.hasCompletedFullSync {
            return true
        }

        return await posCatalogSyncCoordinator.hoursSinceLastSync(for: siteID) != nil
    }
}

private extension ConnectivityStatus {
    var isReachable: Bool {
        switch self {
        case .reachable:
            return true
        case .unknown, .notReachable:
            return false
        }
    }
}

private extension POSCatalogSyncState {
    var hasCompletedFullSync: Bool {
        switch self {
        case .syncCompleted:
            return true
        case .initialSyncStarted,
                .syncStarted,
                .initialSyncProgress,
                .syncProgress,
                .initialSyncFailed,
                .syncFailed,
                .syncNeverDone:
            return false
        }
    }
}


struct POSPresentationRootView: View {
    let posView: PointOfSaleEntryPointView?

    var body: some View {
        if let posView {
            posView
        } else {
            PointOfSaleLoadingEntryPointView()
        }
    }
}


private extension POSTabCoordinator {
    func makeMockPOSOrderService(currency: String) -> POSOrderServiceProtocol? {
        #if DEBUG
        if ProcessConfiguration.shouldUsePOSUITestMocks {
            return POSOrderServiceUITestMock()
        }
        #endif

        if ProcessConfiguration.shouldBypassPOSOrderSyncing {
            return POSOrderServiceScreenshotMock(currency: currency)
        }

        return nil
    }

    func makeMockPOSItemProvider() -> Yosemite.PointOfSaleItemServiceProtocol? {
        #if DEBUG
        if ProcessConfiguration.shouldUsePOSUITestMocks {
            return PointOfSaleItemServiceUITestMock()
        }
        #endif

        if ProcessConfiguration.shouldLoadMockedPOSProducts {
            return PointOfSaleItemServiceScreenshotMock()
        }

        return nil
    }

    func updateDefaultConfigurationForPointOfSale(_ isPointOfSaleActive: Bool) {
        updateInAppNotifications(isPointOfSaleActive)
        updateTrackEventPrefix(isPointOfSaleActive)
    }

    /// Disables foreground in-app notifications when Point of Sale is active.
    func updateInAppNotifications(_ isPointOfSaleActive: Bool) {
        if isPointOfSaleActive {
            pushNotesManager.disableInAppNotifications()
        } else {
            pushNotesManager.enableInAppNotifications()
        }
    }

    /// Decorates track events with a different prefix when Point of Sale is active.
    func updateTrackEventPrefix(_ isPointOfSaleActive: Bool) {
        TracksProvider.setPOSMode(isPointOfSaleActive)
    }
}
