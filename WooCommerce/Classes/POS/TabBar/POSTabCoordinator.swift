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
    private(set) var siteID: Int64
    private let tabContainerController: TabContainerController
    private let viewControllerToPresent: UIViewController
    private let storesManager: StoresManager
    private let credentials: Credentials?
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    private let pushNotesManager: PushNotesManager
    private let eligibilityChecker: POSEntryPointEligibilityCheckerProtocol

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

    private lazy var barcodeScanService: PointOfSaleBarcodeScanService = {
        PointOfSaleBarcodeScanService(siteID: siteID,
                                      credentials: credentials,
                                      selectedSite: defaultSitePublisher,
                                      appPasswordSupportState: isAppPasswordSupported,
                                      currencySettings: currencySettings)
    }()

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
         eligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
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

        tabContainerController.wrappedController = POSTabViewController()
    }

    func onTabSelected() {
        presentPOSView(siteID: siteID)
    }

    func didSwitchStore(id: Int64) {
        self.siteID = id

        // Resets lazy properties so they get recreated with new siteID
        posItemFetchStrategyFactory = PointOfSaleItemFetchStrategyFactory(
            siteID: siteID,
            credentials: credentials,
            selectedSite: defaultSitePublisher,
            appPasswordSupportState: isAppPasswordSupported
        )

        posPopularItemFetchStrategyFactory =
        PointOfSaleFixedItemFetchStrategyFactory(
            fixedStrategy: posItemFetchStrategyFactory.popularStrategy()
        )

        posCouponFetchStrategyFactory = PointOfSaleCouponFetchStrategyFactory(
            siteID: siteID,
            currencySettings: currencySettings,
            credentials: credentials,
            selectedSite: defaultSitePublisher,
            appPasswordSupportState: isAppPasswordSupported,
            storage: storageManager
        )

        posCouponProvider = PointOfSaleCouponService(
            siteID: siteID,
            currencySettings: currencySettings,
            credentials: credentials,
            selectedSite: defaultSitePublisher,
            appPasswordSupportState: isAppPasswordSupported,
            storage: storageManager
        )

        barcodeScanService = PointOfSaleBarcodeScanService(
            siteID: siteID,
            credentials: credentials,
            selectedSite: defaultSitePublisher,
            appPasswordSupportState: isAppPasswordSupported,
            currencySettings: currencySettings
        )
    }
}

private extension POSTabCoordinator {
    func presentPOSView(siteID: Int64) {
        Task { @MainActor [weak self] in
            guard let self else { return }
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

            let grdbManager: GRDBManagerProtocol? = serviceAdaptor.featureFlags.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1) ? ServiceLocator.grdbManager : nil
            let catalogSyncCoordinator = ServiceLocator.posCatalogSyncCoordinator

            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials,
                                                      selectedSite: defaultSitePublisher,
                                                      appPasswordSupportState: isAppPasswordSupported),
               let orderService = POSOrderService(siteID: siteID,
                                                  credentials: credentials,
                                                  selectedSite: defaultSitePublisher,
                                                  appPasswordSupportState: isAppPasswordSupported),
               #available(iOS 17.0, *) {
                let receiptSender = POSReceiptSender(siteID: siteID,
                                                     orderService: orderService,
                                                     receiptService: receiptService,
                                                     analytics: serviceAdaptor.analytics,
                                                     pluginsService: pluginsService
                )
                let posView = PointOfSaleEntryPointView(
                    itemsController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(
                            currencySettings: currencySettings),
                        itemFetchStrategyFactory: posItemFetchStrategyFactory,
                        analyticsProvider: serviceAdaptor.analytics),
                    purchasableItemsSearchController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(
                            currencySettings: currencySettings),
                        itemFetchStrategyFactory: posItemFetchStrategyFactory,
                        initialState: .init(containerState: .content,
                                            itemsStack: .init(root: .loaded([], hasMoreItems: true), itemStates: [:])),
                        analyticsProvider: serviceAdaptor.analytics),
                    couponsController: PointOfSaleCouponsController(itemProvider: posCouponProvider,
                                                                    fetchStrategyFactory: posCouponFetchStrategyFactory,
                                                                    analyticsProvider: serviceAdaptor.analytics),
                    couponsSearchController: PointOfSaleCouponsController(itemProvider: posCouponProvider,
                                                                          fetchStrategyFactory: posCouponFetchStrategyFactory,
                                                                          analyticsProvider: serviceAdaptor.analytics),
                    ordersController: POSOrderListController(
                        orderListFetchStrategyFactory: POSOrderListFetchStrategyFactory(
                            siteID: siteID,
                            credentials: credentials,
                            selectedSite: defaultSitePublisher,
                            appPasswordSupportState: isAppPasswordSupported,
                            currencyFormatter: CurrencyFormatter(currencySettings: currencySettings)
                        )
                    ),

                    onPointOfSaleModeActiveStateChange: { [weak self] isEnabled in
                        self?.updateDefaultConfigurationForPointOfSale(isEnabled)
                    },
                    cardPresentPaymentService: cardPresentPaymentService,
                    orderController: PointOfSaleOrderController(orderService: orderService,
                                                                receiptSender: receiptSender,
                                                                currencySettingsProvider: serviceAdaptor.currency,
                                                                analytics: serviceAdaptor.analytics),
                    receiptSender: receiptSender,
                    settingsController: PointOfSaleSettingsController(siteID: siteID,
                                                                      settingsService: settingsService,
                                                                      cardPresentPaymentService: cardPresentPaymentService,
                                                                      pluginsService: pluginsService,
                                                                      defaultSiteName: storesManager.sessionManager.defaultSite?.name,
                                                                      siteSettings: ServiceLocator.selectedSiteSettings.siteSettings,
                                                                      grdbManager: grdbManager,
                                                                      catalogSyncCoordinator: catalogSyncCoordinator),
                    collectOrderPaymentAnalyticsTracker: collectPaymentAnalyticsAdaptor,
                    searchHistoryService: POSSearchHistoryService(siteID: siteID),
                    popularPurchasableItemsController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(currencySettings: currencySettings),
                        itemFetchStrategyFactory: posPopularItemFetchStrategyFactory,
                        analyticsProvider: serviceAdaptor.analytics
                    ),
                    barcodeScanService: barcodeScanService,
                    posEligibilityChecker: eligibilityChecker,
                    siteTimezone: siteTimezone,
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
