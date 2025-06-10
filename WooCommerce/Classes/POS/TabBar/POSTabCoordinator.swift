import Foundation
import UIKit
import SwiftUI
import Yosemite

final class POSTabViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: localize and move to SwiftUI if feasible
        title = "Point of Sale"
        tabBarItem.title = title
        tabBarItem.image = .creditCardImage
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
    private let posEligibilityChecker: POSEligibilityCheckerProtocol
    private let credentials: Credentials?

    private(set) lazy var posItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory = {
        PointOfSaleItemFetchStrategyFactory(siteID: siteID, credentials: credentials)
    }()

    private(set) lazy var posPopularItemFetchStrategyFactory: PointOfSaleFixedItemFetchStrategyFactory = {
        PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: posItemFetchStrategyFactory.popularStrategy())
    }()

    private(set) lazy var posCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactory = {
        PointOfSaleCouponFetchStrategyFactory(siteID: siteID,
                                              currencySettings: ServiceLocator.currencySettings,
                                              credentials: credentials,
                                              // TODO: DI
                                              storage: ServiceLocator.storageManager)
    }()

    private(set) lazy var posCouponProvider: PointOfSaleCouponServiceProtocol = {
        let storage = ServiceLocator.storageManager
        let currencySettings = ServiceLocator.currencySettings

        return PointOfSaleCouponService(siteID: siteID,
                                        currencySettings: currencySettings,
                                        credentials: credentials,
                                        storage: storage)
    }()

    private(set) lazy var barcodeScanService: PointOfSaleBarcodeScanService = {
        PointOfSaleBarcodeScanService(siteID: siteID,
                                      credentials: credentials,
                                      // TODO: DI
                                      currencySettings: ServiceLocator.currencySettings)
    }()

    init(siteID: Int64,
         tabContainerController: TabContainerController,
         viewControllerToPresent: UIViewController,
         storesManager: StoresManager = ServiceLocator.stores,
         posEligibilityChecker: POSEligibilityCheckerProtocol) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.posEligibilityChecker = posEligibilityChecker
        self.tabContainerController = tabContainerController
        self.viewControllerToPresent = viewControllerToPresent
        self.credentials = storesManager.sessionManager.defaultCredentials

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
            let collectOrderPaymentAnalyticsTracker = POSCollectOrderPaymentAnalytics()
            let cardPresentPaymentService = await CardPresentPaymentService(siteID: siteID,
                                                                            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker)
            if let receiptService = POSReceiptService(siteID: siteID,
                                                      credentials: credentials),
               let orderService = POSOrderService(siteID: siteID,
                                                  credentials: credentials),
               #available(iOS 17.0, *) {
                let posView = PointOfSaleEntryPointView(
                    itemsController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(
                            currencySettings: ServiceLocator.currencySettings),
                        itemFetchStrategyFactory: posItemFetchStrategyFactory),
                    purchasableItemsSearchController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(
                            currencySettings: ServiceLocator.currencySettings),
                        itemFetchStrategyFactory: posItemFetchStrategyFactory,
                        initialState: .init(containerState: .content,
                                            itemsStack: .init(root: .loaded([], hasMoreItems: true), itemStates: [:]))),
                    couponsController: PointOfSaleCouponsController(itemProvider: posCouponProvider,
                                                                    fetchStrategyFactory: posCouponFetchStrategyFactory),
                    couponsSearchController: PointOfSaleCouponsController(itemProvider: posCouponProvider,
                                                                          fetchStrategyFactory: posCouponFetchStrategyFactory),
                    onPointOfSaleModeActiveStateChange: { [weak self] isEnabled in
                        self?.updateDefaultConfigurationForPointOfSale(isEnabled)
                    },
                    cardPresentPaymentService: cardPresentPaymentService,
                    orderController: PointOfSaleOrderController(orderService: orderService,
                                                                receiptService: receiptService),
                    collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                    searchHistoryService: POSSearchHistoryService(siteID: siteID),
                    popularPurchasableItemsController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(currencySettings: ServiceLocator.currencySettings),
                        itemFetchStrategyFactory: posPopularItemFetchStrategyFactory
                    ),
                    barcodeScanService: barcodeScanService
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
            ServiceLocator.pushNotesManager.disableInAppNotifications()
        } else {
            ServiceLocator.pushNotesManager.enableInAppNotifications()
        }
    }

    /// Decorates track events with a different prefix when Point of Sale is active.
    func updateTrackEventPrefix(_ isPointOfSaleActive: Bool) {
        TracksProvider.setPOSMode(isPointOfSaleActive)
    }
}
