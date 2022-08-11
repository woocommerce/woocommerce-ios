import UIKit
import Yosemite
import Combine
import SwiftUI
import WordPressUI

final class AddOrderCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let siteID: Int64
    private let sourceBarButtonItem: UIBarButtonItem?
    private let sourceView: UIView?
    private lazy var baseViewController: AnnouncementBottomSheetViewController = {
        AnnouncementBottomSheetViewController()
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
        baseViewController.completionHandler = redirectToHubMenu
        let bottomSheet = BottomSheetViewController(childViewController: baseViewController)
        bottomSheet.show(from: navigationController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem, arrowDirections: .any)
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

class AnnouncementBottomSheetViewController: UIViewController {
    /// Assign this closure for a callback method when the BottomAnnouncementView button is tapped
    ///
    var completionHandler: (() -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnnouncementView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    func setupAnnouncementView() {
        let announcementView = AnnouncementBottomSheetView(buttonTapped: completionHandler)
        let controller = UIHostingController(rootView: announcementView)
        addChild(controller)
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        setupConstraints(for: controller)
    }

    func setupConstraints(for controller: UIHostingController<AnnouncementBottomSheetView>) {
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        controller.view.heightAnchor.constraint(equalToConstant: self.view.intrinsicContentSize.width + Layout.bottomSpace).isActive = true
        controller.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
    }
}

extension AnnouncementBottomSheetViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .contentHeight(200)
    }

    var expandedHeight: DrawerHeight {
        return .contentHeight(200)
    }
}

private extension AnnouncementBottomSheetViewController {
    enum Layout {
        static let bottomSpace: CGFloat = 100
    }
}
