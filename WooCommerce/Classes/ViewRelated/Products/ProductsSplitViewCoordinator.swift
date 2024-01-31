import UIKit

/// Coordinates the state of multiple columns (product list and secondary view) based on the secondary view.
final class ProductsSplitViewCoordinator {
    private let siteID: Int64
    private let splitViewController: UISplitViewController
    private lazy var productsViewController = ProductsViewController(siteID: siteID)

    init(siteID: Int64, splitViewController: UISplitViewController) {
        self.siteID = siteID
        self.splitViewController = splitViewController
    }

    /// Called when the split view is ready to be shown, like after the split view is added to the view hierarchy.
    func start() {
        configureSplitView()
    }
}

private extension ProductsSplitViewCoordinator {
    func configureSplitView() {
        let productsNavigationController = WooTabNavigationController()
        productsNavigationController.viewControllers = [productsViewController]
        splitViewController.setViewController(productsNavigationController, for: .primary)
    }
}
