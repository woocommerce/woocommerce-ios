import Foundation
import UIKit
import SwiftUI
import Yosemite
import class WooFoundation.CurrencySettings
import protocol Storage.GRDBManagerProtocol
import protocol Storage.StorageManagerType
import class WooFoundationCore.CurrencyFormatter
import struct NetworkingCore.JetpackSite
import struct Combine.AnyPublisher
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

    /// Local catalog eligibility service - created asynchronously during init
    private(set) var localCatalogEligibilityService: POSLocalCatalogEligibilityServiceProtocol?

    private lazy var posItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory = {
        PointOfSaleItemFetchStrategyFactory(siteID: siteID,
                                            credentials: credentials,
                                            selectedSite: defaultSitePublisher,
                                            appPasswordSupportState: isAppPasswordSupported)
    }()

    private lazy var posPopularItemFetchStrategyFactory: PointOfSaleFixedItemFetchStrategyFactory = {
        PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: posItemFetchStrategyFactory.popularStrategy())
    }()

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

    /// Update local catalog eligibility when POS tab visibility changes
    func updatePOSTabVisibility(_ isPOSTabVisible: Bool) {
        Task { @MainActor [weak self] in
            guard let self, let service = self.localCatalogEligibilityService else { return }
            await service.updateVisibility(isPOSTabVisible: isPOSTabVisible, for: siteID)
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
            let lastOpenedAction = AppSettingsAction.setPOSLastOpenedDate(siteID: siteID, date: Date()) { _ in }
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
                let state = await service.catalogEligibility(for: siteID)
                if case .ineligible(reason: .catalogSizeCheckFailed) = state {
                    await service.refreshEligibilityState(for: siteID)
                }
                isLocalCatalogEligible = await service.catalogEligibility(for: siteID) == .eligible
            } else {
                // Service not ready yet (rare race condition), assume ineligible
                isLocalCatalogEligible = false
            }

            let serviceAdaptor = POSServiceLocatorAdaptor()
            let collectPaymentAnalyticsAdaptor = POSCollectOrderPaymentAnalyticsAdaptor(analytics: serviceAdaptor.analytics)
            let cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID,
                                                                            stores: storesManager,
                                                                            collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor)
            let settingsService = PointOfSaleSettingsService(siteID: siteID,
                                                             credentials: credentials,
                                                             selectedSite: defaultSitePublisher,
                                                             appPasswordSupportState: isAppPasswordSupported,
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
                                                              grdbManager: grdbManager)

            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials,
                                                      selectedSite: defaultSitePublisher,
                                                      appPasswordSupportState: isAppPasswordSupported),
               let orderService = POSOrderService(siteID: siteID,
                                                  credentials: credentials,
                                                  selectedSite: defaultSitePublisher,
                                                  appPasswordSupportState: isAppPasswordSupported) {
                let posView = PointOfSaleEntryPointView(
                    siteID: siteID,
                    itemFetchStrategyFactory: posItemFetchStrategyFactory,
                    popularItemFetchStrategyFactory: posPopularItemFetchStrategyFactory,
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
                    services: serviceAdaptor
                )

                let hostingController = UIHostingController(rootView: posView)
                hostingController.modalPresentationStyle = .fullScreen
                viewControllerToPresent.present(hostingController, animated: true)
            }
        }
    }
}

private extension POSTabCoordinator {
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
