import UIKit
import Yosemite
import Combine
import SwiftUI

final class AddOrderCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let siteID: Int64
    private let sourceBarButtonItem: UIBarButtonItem?
    private let sourceView: UIView?

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
        let baseViewController = BaseViewController()
        baseViewController.completionHandler = redirectToHubMenu
        navigationController.present(baseViewController, animated: true)
    }

    /// Redirects to `HubMenu`tabBar
    ///
    func redirectToHubMenu() {
        guard let mainTabBarController = AppDelegate.shared.tabBarController else {
            return
        }
        mainTabBarController.navigateTo(.hubMenu)
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

class BaseViewController: UIViewController {
    /// Assign this closure for a callback method when the BottomAnnouncementView button is tapped
    ///
    var completionHandler: (() -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupAnnouncementView()
    }

    func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
    }

    func setupAnnouncementView() {
        let announcementView = BottomAnnouncementView(buttonTapped: completionHandler)
        let controller = UIHostingController(rootView: announcementView)
        addChild(controller)
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        setupConstraints(for: controller)
    }

    func setupConstraints(for controller: UIHostingController<BottomAnnouncementView>) {
        let extraBottomSpace: CGFloat = navigationController?.view.safeAreaInsets.bottom ?? CGFloat(Layout.bottomSpace)

        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        controller.view.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        controller.view.heightAnchor.constraint(equalToConstant: 100).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -extraBottomSpace).isActive = true
    }
}

private extension BaseViewController {
    enum Layout {
        static let bottomSpace: CGFloat = 100
    }
}
