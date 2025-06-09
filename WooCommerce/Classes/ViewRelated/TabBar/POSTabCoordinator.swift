import Combine
import Foundation
import UIKit
import Yosemite
import SwiftUI

final class POSTabViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO-jc: localize
        title = "Point of Sale"
        tabBarItem.title = title
        tabBarItem.image = .creditCardImage
        tabBarItem.accessibilityIdentifier = "tab-bar-pos-item"
    }
}

/// Coordinator for the HubMenu tab.
///
final class POSTabCoordinator {
    private let siteID: Int64
    private let tabContainerController: TabContainerController
    private let viewControllerToPresent: UIViewController
    private let storesManager: StoresManager
    private let posEligibilityChecker: POSTabEligibilityCheckerProtocol & POSEntryPointEligibilityCheckerProtocol
    private let credentials: Credentials?

    private var posEligibilitySubscription: AnyCancellable?

    private func posItemFetchStrategyFactory(siteID: Int64) -> PointOfSaleItemFetchStrategyFactory {
        PointOfSaleItemFetchStrategyFactory(siteID: siteID, credentials: credentials)
    }

    private func posPopularItemFetchStrategyFactory(siteID: Int64,
                                                    posItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactory)
    -> PointOfSaleFixedItemFetchStrategyFactory {
        PointOfSaleFixedItemFetchStrategyFactory(fixedStrategy: posItemFetchStrategyFactory.popularStrategy())
    }

    private func posCouponFetchStrategyFactory(siteID: Int64) -> PointOfSaleCouponFetchStrategyFactory {
        PointOfSaleCouponFetchStrategyFactory(siteID: siteID,
                                              currencySettings: ServiceLocator.currencySettings,
                                              credentials: credentials,
                                              storage: ServiceLocator.storageManager)
    }

    private func posCouponProvider(siteID: Int64) -> PointOfSaleCouponServiceProtocol {
        let storage = ServiceLocator.storageManager
        let currencySettings = ServiceLocator.currencySettings

        return PointOfSaleCouponService(siteID: siteID,
                                        currencySettings: currencySettings,
                                        credentials: credentials,
                                        storage: storage)
    }

    init(siteID: Int64,
         tabContainerController: TabContainerController,
         viewControllerToPresent: UIViewController,
         storesManager: StoresManager = ServiceLocator.stores,
         posEligibilityChecker: POSTabEligibilityCheckerProtocol & POSEntryPointEligibilityCheckerProtocol) {
        self.siteID = siteID
        self.storesManager = storesManager
        self.posEligibilityChecker = posEligibilityChecker
        self.tabContainerController = tabContainerController
        self.viewControllerToPresent = viewControllerToPresent
        self.credentials = storesManager.sessionManager.defaultCredentials

        tabContainerController.wrappedController = POSTabViewController()
    }

    deinit {
        posEligibilitySubscription?.cancel()
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
                let posItemFetchStrategyFactory = posItemFetchStrategyFactory(siteID: siteID)
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
                    couponsController: PointOfSaleCouponsController(itemProvider: posCouponProvider(siteID: siteID),
                                                                    fetchStrategyFactory: posCouponFetchStrategyFactory(siteID: siteID)),
                    couponsSearchController: PointOfSaleCouponsController(itemProvider: posCouponProvider(siteID: siteID),
                                                                          fetchStrategyFactory: posCouponFetchStrategyFactory(siteID: siteID)),
                    onPointOfSaleModeActiveStateChange: { isEnabled in
                        //                                viewModel.updateDefaultConfigurationForPointOfSale(isEnabled)
                    },
                    cardPresentPaymentService: cardPresentPaymentService,
                    orderController: PointOfSaleOrderController(orderService: orderService,
                                                                receiptService: receiptService),
                    collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                    searchHistoryService: POSSearchHistoryService(siteID: siteID),
                    popularPurchasableItemsController: PointOfSaleItemsController(
                        itemProvider: PointOfSaleItemService(currencySettings: ServiceLocator.currencySettings),
                        itemFetchStrategyFactory: posPopularItemFetchStrategyFactory(
                            siteID: siteID,
                            posItemFetchStrategyFactory: posItemFetchStrategyFactory
                        )
                    ),
                    posEligibilityChecker: posEligibilityChecker
                )
                let hostingController = UIHostingController(rootView: posView)
                hostingController.modalPresentationStyle = .fullScreen
                viewControllerToPresent.present(hostingController, animated: true)
            }
        }
    }
}
