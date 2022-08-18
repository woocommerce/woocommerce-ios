import UIKit
import Yosemite
import Combine
import SwiftUI
import WordPressUI

/// Manages the different navigation flows that start from the Orders main tab
///
final class AddOrderCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let siteID: Int64
    private let sourceBarButtonItem: UIBarButtonItem?
    private let sourceView: UIView?

    /// Keeps a reference to NewSimplePaymentsLocationNoticeViewController in order to use it as child of WordPressUI's BottomSheetViewController component
    ///
    private lazy var newSimplePaymentsNoticeViewController: NewSimplePaymentsLocationNoticeViewController = {
        NewSimplePaymentsLocationNoticeViewController()
    }()

    /// Assign this closure to be notified when a new order is created
    ///
    var onOrderCreated: (Order) -> Void = { _ in }

    init(siteID: Int64,
         sourceBarButtonItem: UIBarButtonItem,
         sourceNavigationController: UINavigationController) {
        self.siteID = siteID
        self.sourceBarButtonItem = sourceBarButtonItem
        self.sourceView = nil
        self.navigationController = sourceNavigationController
    }

    init(siteID: Int64,
         sourceView: UIView,
         sourceNavigationController: UINavigationController) {
        self.siteID = siteID
        self.sourceBarButtonItem = nil
        self.sourceView = sourceView
        self.navigationController = sourceNavigationController
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        presentOrderTypeBottomSheet()
    }
}

// MARK: Navigation
private extension AddOrderCoordinator {
    func presentOrderTypeBottomSheet() {
        let viewProperties = BottomSheetListSelectorViewProperties(title: nil)
        let command = OrderTypeBottomSheetListSelectorCommand() { selectedBottomSheetOrderType in
            self.navigationController.dismiss(animated: true)
            self.presentOrderCreationFlow(bottomSheetOrderType: selectedBottomSheetOrderType)
        }
        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        productTypesListPresenter.show(from: navigationController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem, arrowDirections: .any)
    }

    func presentOrderCreationFlow(bottomSheetOrderType: BottomSheetOrderType) {
        switch bottomSheetOrderType {
        case .simple:
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.paymentsHubMenuSection) {
                presentBottomAnnouncement()
            } else {
                presentSimplePaymentsAmountController()
            }
        case .full:
            presentNewOrderController()
            return
        }
    }

    /// Presents `SimplePaymentsAmountHostingController`.
    ///
    func presentSimplePaymentsAmountController() {
        SimplePaymentsAmountFlowOpener.openSimplePaymentsAmountFlow(from: navigationController, siteID: siteID)
    }

    /// Presents `BottomAnnouncementView`UIHostingController  modally.
    ///
    func presentBottomAnnouncement() {
        let bottomSheet = BottomSheetViewController(childViewController: newSimplePaymentsNoticeViewController)
        bottomSheet.show(from: navigationController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem, arrowDirections: .any)
    }

    /// Presents `OrderFormHostingController`.
    ///
    func presentNewOrderController() {
        let viewModel = EditableOrderViewModel(siteID: siteID)
        viewModel.onFinished = onOrderCreated

        let viewController = OrderFormHostingController(viewModel: viewModel)
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.splitViewInOrdersTab) {
            let newOrderNC = WooNavigationController(rootViewController: viewController)
            navigationController.present(newOrderNC, animated: true)
        } else {
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.orderAddNew())
    }
}
