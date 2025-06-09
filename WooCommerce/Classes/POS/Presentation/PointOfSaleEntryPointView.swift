import Combine
import SwiftUI
import protocol Yosemite.POSSearchHistoryProviding

@available(iOS 17.0, *)
@Observable final class PointOfSaleEntryPointController {
    private let posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol
    private(set) var eligibilityState: POSEligibilityState?
    private var eligibilitySubscription: AnyCancellable?

    init(eligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
        self.posEligibilityChecker = eligibilityChecker

        eligibilitySubscription = posEligibilityChecker.isEligible
            .sink { [weak self] eligibilityState in
                self?.eligibilityState = eligibilityState
            }
    }

    func refreshEligibility() {
    }
}

@available(iOS 17.0, *)
struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var pointOfSaleEntryPointController: PointOfSaleEntryPointController

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let couponsController: PointOfSaleCouponsControllerProtocol
    private let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let searchHistoryService: POSSearchHistoryProviding
    private let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol

    init(itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularPurchasableItemsController: PointOfSaleItemsControllerProtocol,
         posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        self.itemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.pointOfSaleEntryPointController = PointOfSaleEntryPointController(eligibilityChecker: posEligibilityChecker)
    }

    var body: some View {
        Group {
            switch pointOfSaleEntryPointController.eligibilityState {
            case .none:
                PointOfSaleLoadingView()
            case .eligible:
                if let posModel = posModel {
                    PointOfSaleDashboardView()
                        .environment(posModel)
                } else {
                    PointOfSaleLoadingView()
                }
            case .ineligible(let reason):
                POSIneligibleView(reason: reason, onRefresh: {
                    pointOfSaleEntryPointController.refreshEligibility()
                })
            }
        }
        .task {
            // We create the posModel in a task, not init, to avoid creating multiple copies during the view's lifecycle.
            // Confusingly, init can be called more than once, but `task` matches the lifecycle.
            // See https://developer.apple.com/documentation/swiftui/state#Store-observable-objects for details.
            posModel = PointOfSaleAggregateModel(
                itemsController: itemsController,
                purchasableItemsSearchController: purchasableItemsSearchController,
                couponsController: couponsController,
                couponsSearchController: couponsSearchController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                searchHistoryService: searchHistoryService,
                popularPurchasableItemsController: popularPurchasableItemsController)
        }
        .environmentObject(posModalManager)
        .injectKeyboardObserver()
        .onAppear {
            onPointOfSaleModeActiveStateChange(true)
        }
        .onDisappear {
            onPointOfSaleModeActiveStateChange(false)
            posModalManager.onDisappear()
            posModel?.pointOfSaleClosed()
        }
    }
}

#if DEBUG
//@available(iOS 17.0, *)
//#Preview {
//    PointOfSaleEntryPointView(itemsController: PointOfSalePreviewItemsController(),
//                              purchasableItemsSearchController: PointOfSalePreviewItemsController(),
//                              couponsController: PointOfSalePreviewCouponsController(),
//                              couponsSearchController: PointOfSalePreviewCouponsController(),
//                              onPointOfSaleModeActiveStateChange: { _ in },
//                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
//                              orderController: PointOfSalePreviewOrderController(),
//                              collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics(),
//                              searchHistoryService: PointOfSalePreviewHistoryService(),
//                              popularPurchasableItemsController: PointOfSalePreviewItemsController())
//}

#endif
