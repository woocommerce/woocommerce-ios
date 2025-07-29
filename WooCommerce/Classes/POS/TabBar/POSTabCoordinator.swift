import Foundation
import UIKit
import SwiftUI
import Yosemite
import class WooFoundation.CurrencySettings
import protocol Storage.StorageManagerType

/// TODO: Remove @_exported after the refactoring
/// Global import of PointOfSale
/// Avoid importing PointOfSale into many different files while in the middle of refactoring
@_exported import PointOfSale

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

    private lazy var posItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory = {
        PointOfSaleItemFetchStrategyFactory(siteID: siteID, credentials: credentials)
    }()

    private lazy var posPopularItemFetchStrategyFactory: PointOfSaleFixedItemFetchStrategyFactory = {
        PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: posItemFetchStrategyFactory.popularStrategy())
    }()

    private lazy var posCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactory = {
        PointOfSaleCouponFetchStrategyFactory(siteID: siteID,
                                              currencySettings: currencySettings,
                                              credentials: credentials,
                                              storage: storageManager)
    }()

    private lazy var posCouponProvider: PointOfSaleCouponServiceProtocol = {
        return PointOfSaleCouponService(siteID: siteID,
                                        currencySettings: currencySettings,
                                        credentials: credentials,
                                        storage: storageManager)
    }()

    private lazy var barcodeScanService: PointOfSaleBarcodeScanService = {
        PointOfSaleBarcodeScanService(siteID: siteID,
                                      credentials: credentials,
                                      currencySettings: currencySettings)
    }()

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
        presentPOSView()
    }
}

private extension POSTabCoordinator {
    func presentPOSView() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let serviceAdaptor = POSServiceLocatorAdaptor()
            let collectOrderPaymentAnalyticsTracker = POSCollectOrderPaymentAnalytics(analytics: serviceAdaptor.analytics)
            let cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID,
                                                                            stores: storesManager,
                                                                            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                                                                            currencySettings: serviceAdaptor.currency)
            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials),
               let orderService = POSOrderService(siteID: siteID,
                                                  credentials: credentials),
               #available(iOS 17.0, *) {
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
                    onPointOfSaleModeActiveStateChange: { [weak self] isEnabled in
                        self?.updateDefaultConfigurationForPointOfSale(isEnabled)
                    },
                    cardPresentPaymentService: cardPresentPaymentService,
                    orderController: PointOfSaleOrderController(orderService: orderService,
                                                                receiptService: receiptService,
                                                                currencySettings: serviceAdaptor.currency,
                                                                analytics: serviceAdaptor.analytics,
                                                                featureFlagService: serviceAdaptor.featureFlags),
                    collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                    searchHistoryService: POSSearchHistoryService(siteID: siteID),
                    popularPurchasableItemsController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(currencySettings: currencySettings),
                        itemFetchStrategyFactory: posPopularItemFetchStrategyFactory,
                        analyticsProvider: serviceAdaptor.analytics
                    ),
                    barcodeScanService: barcodeScanService,
                    posEligibilityChecker: eligibilityChecker,
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
