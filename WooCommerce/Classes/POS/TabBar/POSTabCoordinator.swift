import Foundation
import UIKit
import SwiftUI
import Yosemite
import Combine
import class WooFoundation.CurrencySettings
import WooFoundationCore
import protocol Storage.GRDBManagerProtocol
import protocol Storage.StorageManagerType
import class NetworkingCore.AlamofireNetwork
import protocol Networking.Network
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

    private lazy var posSyncDispatcher = ForegroundPOSCatalogSyncDispatcher()

    /// Local catalog eligibility service - created asynchronously during init
    private(set) var localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?

    /// Creates item fetch strategy factory using the shared POS network.
    private func createItemFetchStrategyFactory(isLocalCatalogEnabled: Bool, network: Network) -> PointOfSaleItemFetchStrategyFactory {
        let isFTSSearchEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleFTSSearch)
        return PointOfSaleItemFetchStrategyFactory(siteID: siteID,
                                                   network: network,
                                                   grdbManager: isLocalCatalogEnabled ? ServiceLocator.grdbManager : nil,
                                                   currencySettings: currencySettings,
                                                   isLocalCatalogEnabled: isLocalCatalogEnabled,
                                                   isFTSSearchEnabled: isFTSSearchEnabled)
    }

    /// Creates popular item fetch strategy factory using the shared POS network.
    private func createPopularItemFetchStrategyFactory(isLocalCatalogEnabled: Bool, network: Network) -> PointOfSaleFixedItemFetchStrategyFactory {
        let itemFactory = createItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEnabled, network: network)
        return PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: itemFactory.popularStrategy())
    }

    /// Creates the appropriate barcode scan service based on local catalog availability.
    private func createBarcodeScanService(isLocalCatalogEligible: Bool,
                                          grdbManager: GRDBManagerProtocol?,
                                          network: Network) -> any PointOfSaleBarcodeScanServiceProtocol {
        if isLocalCatalogEligible,
           let grdbManager {
            return PointOfSaleLocalBarcodeScanService(siteID: siteID,
                                                     grdbManager: grdbManager,
                                                     currencySettings: currencySettings)
        } else {
            return PointOfSaleBarcodeScanService(siteID: siteID,
                                                network: network,
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
        Task { @MainActor [weak self] in
            guard let self else { return }

            // Get local catalog eligibility as bool from service
            let isLocalCatalogEligible: Bool
            if let service = localCatalogEligibilityService {
                // Retry transient failures before using the value
                let state = try await service.catalogEligibility(for: siteID)
                if case .ineligible(reason: .catalogSizeCheckFailed) = state {
                    try await service.refreshEligibilityState(for: siteID)
                }
                isLocalCatalogEligible = try await service.catalogEligibility(for: siteID) == .eligible
            } else {
                // Service not ready yet (rare race condition), assume ineligible
                isLocalCatalogEligible = false
            }

            // Shared network for all POS services that make mutating API calls.
            // When a cashier authenticates via PIN, overridePOSCredentials() updates
            // this network so refunds, orders, receipts, etc. are attributed correctly.
            guard let credentials else {
                DDLogError("⛔️ POS cannot start without credentials")
                return
            }
            let posNetwork = AlamofireNetwork(credentials: credentials,
                                              selectedSite: defaultSitePublisher,
                                              appPasswordSupportState: isAppPasswordSupported)

            let sunsetWarningChecker = POSSunsetWarningChecker(
                systemStatusService: POSSystemStatusService(
                    network: posNetwork,
                    storageManager: storageManager
                )
            )

            let serviceAdaptor = POSServiceLocatorAdaptor(posNetwork: posNetwork)
            let collectPaymentAnalyticsAdaptor = POSCollectOrderPaymentAnalyticsAdaptor(analytics: serviceAdaptor.analytics)

            let cardPresentPaymentService: CardPresentPaymentFacade
            if ProcessConfiguration.shouldUseMockCardPresentPayment {
                cardPresentPaymentService = CardPresentPaymentServiceScreenshotMock()
            } else {
                cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID,
                                                                            stores: storesManager,
                                                                            collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor)
            }
            let settingsService = PointOfSaleSettingsService(siteID: siteID,
                                                             network: posNetwork,
                                                             storage: storageManager)
            let pluginsService = PluginsService(storageManager: storageManager)
            let siteTimezone = storesManager.sessionManager.defaultSite?.siteTimezone ?? .current

            // Only initialize local catalog infrastructure if eligible
            let grdbManager: GRDBManagerProtocol? = isLocalCatalogEligible ? ServiceLocator.grdbManager : nil
            let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = isLocalCatalogEligible ? ServiceLocator.posCatalogSyncCoordinator : nil

            // Create appropriate barcode scan service based on local catalog eligibility
            // Will use local GRDB-based scanning if eligible and infrastructure is available,
            // otherwise falls back to remote API-based scanning
            let barcodeScanService = createBarcodeScanService(isLocalCatalogEligible: isLocalCatalogEligible,
                                                              grdbManager: grdbManager,
                                                              network: posNetwork)

            let posCouponFetchStrategyFactory = PointOfSaleCouponFetchStrategyFactory(
                siteID: siteID,
                currencySettings: currencySettings,
                network: posNetwork,
                storage: storageManager
            )
            let posCouponProvider: PointOfSaleCouponServiceProtocol = PointOfSaleCouponService(
                siteID: siteID,
                currencySettings: currencySettings,
                network: posNetwork,
                storage: storageManager
            )
            let refundsService = POSRefundsService(siteID: siteID,
                                                   network: posNetwork,
                                                   currencySettings: currencySettings)
            let receiptService = POSReceiptService(siteID: siteID, network: posNetwork)

            let orderService: POSOrderServiceProtocol
            if ProcessConfiguration.shouldBypassPOSOrderSyncing {
                orderService = POSOrderServiceScreenshotMock(currency: currencySettings.currencyCode.rawValue)
            } else {
                orderService = POSOrderService(siteID: siteID, network: posNetwork)
            }

            var itemProvider: Yosemite.PointOfSaleItemServiceProtocol? = nil
            if ProcessConfiguration.shouldLoadMockedPOSProducts {
                itemProvider = PointOfSaleItemServiceScreenshotMock()
            }

            // Resolve TTP eligibility once, up front, so we can hand the right
            // preferred method down to POSPaymentModel.
            let tapToPayAvailabilityChecker = POSTapToPayAvailabilityChecker(
                siteID: siteID,
                eligibilityService: POSEligibilityService()
            )
            let preferredConnectionMethod: CardReaderConnectionMethod
            switch await tapToPayAvailabilityChecker.checkAvailability() {
            case .available:
                preferredConnectionMethod = .tapToPay
            case .unknown, .unavailable:
                preferredConnectionMethod = .bluetooth
            }

            var staffSettingsMode = self.createStaffSettingsMode(
                siteID: siteID,
                stores: storesManager
            )
            // Wire auto sign-in callback for local mode after the service adaptor is created
            if case .local(let pinService, _) = staffSettingsMode {
                let permissions = serviceAdaptor.permissions
                staffSettingsMode = .local(pinService: pinService, onAdminPINSet: { pin in
                    if let provider = permissions as? LocalPOSPermissionProvider {
                        try? provider.authenticatePIN(pin)
                    }
                })
            }

            let posView = PointOfSaleEntryPointView(
                siteID: siteID,
                itemFetchStrategyFactory: createItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEligible, network: posNetwork),
                popularItemFetchStrategyFactory: createPopularItemFetchStrategyFactory(isLocalCatalogEnabled: isLocalCatalogEligible, network: posNetwork),
                couponProvider: posCouponProvider,
                couponFetchStrategyFactory: posCouponFetchStrategyFactory,
                orderListFetchStrategyFactory: POSOrderListFetchStrategyFactory(
                    siteID: siteID,
                    network: posNetwork,
                    currencyFormatter: CurrencyFormatter(currencySettings: currencySettings),
                    analytics: POSOrderListFetchAnalytics(analytics: serviceAdaptor.analytics)
                ),
                orderService: orderService,
                refundsService: refundsService,
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
                sunsetWarningChecker: sunsetWarningChecker,
                tapToPayAvailabilityChecker: tapToPayAvailabilityChecker,
                preferredConnectionMethod: preferredConnectionMethod,
                services: serviceAdaptor,
                itemProvider: itemProvider,
                staffSettingsMode: staffSettingsMode
            )

            let hostingController = UIHostingController(rootView: posView)
            hostingController.modalPresentationStyle = .fullScreen
            viewControllerToPresent.present(hostingController, animated: true)
        }
    }
}

private extension POSTabCoordinator {
    func createStaffSettingsMode(siteID: Int64, stores: StoresManager) -> POSStaffSettingsMode? {
        let featureFlagService = ServiceLocator.featureFlagService
        if featureFlagService.isFeatureFlagEnabled(.pointOfSaleRemoteRoles) {
            let siteURL = stores.sessionManager.defaultSite?.url ?? ""
            let manageURL = URL(string: "\(siteURL)/wp-admin/admin.php?page=wc-settings&tab=point-of-sale&section=staff")
                ?? URL(string: "about:blank")!
            return .remote(
                loadStaff: {
                    try await withCheckedThrowingContinuation { continuation in
                        let action = POSAuthAction.fetchStaffStatus(siteID: siteID) { result in
                            switch result {
                            case .success(let users):
                                let members = users.map { user in
                                    StaffMemberInfo(
                                        id: user.userID,
                                        displayName: user.displayName,
                                        role: user.role,
                                        hasPIN: user.hasPIN
                                    )
                                }
                                continuation.resume(returning: members)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        }
                        Task { @MainActor in
                            stores.dispatch(action)
                        }
                    }
                },
                manageURL: manageURL
            )
        } else if featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalRoles) {
            return .local(pinService: POSPINService())
        } else {
            return nil
        }
    }

    func updateDefaultConfigurationForPointOfSale(_ isPointOfSaleActive: Bool) {
        updateInAppNotifications(isPointOfSaleActive)
        updateTrackEventPrefix(isPointOfSaleActive)

        // When POS exits, clear the lock state so it doesn't auto-reopen next launch.
        if !isPointOfSaleActive {
            UserDefaults.standard.set(false, forKey: POSLockStateKey.isLocked)
        }
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
