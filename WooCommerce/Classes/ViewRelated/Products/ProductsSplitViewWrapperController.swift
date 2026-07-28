import UIKit
import Yosemite

/// Controller to wrap the products split view
///
final class ProductsSplitViewWrapperController: UIViewController, UsesCompactLayoutInNarrowWindow {
    private let siteID: Int64
    private lazy var coordinator = ProductsSplitViewCoordinator(siteID: siteID,
                                                                                              splitViewController: productsSplitViewController)
    private lazy var productsSplitViewController = WooSplitViewController(columnForCollapsingHandler: handleCollapsingSplitView,
                                                                          didExpandHandler: handleDidExpand)

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
        configureTabBarItem()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startProductCreation() {
        coordinator.startProductCreation()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureChildViewController()
        coordinator.start()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        coordinator.refreshExpandedLayoutIfNeeded()
    }

    override var shouldShowOfflineBanner: Bool {
        return true
    }

    /// Returns the product form of the given product ID being displayed if available.
    func currentProductForm(for productID: Int64) -> ProductFormViewController<ProductFormViewModel>? {
        coordinator.currentProductForm(for: productID)
    }
}

private extension ProductsSplitViewWrapperController {
    func handleCollapsingSplitView(splitViewController: UISplitViewController) -> UISplitViewController.Column {
        coordinator.columnToShowWhenSplitViewIsCollapsing()
    }

    func handleDidExpand(splitViewController: UISplitViewController) {
        coordinator.didExpand()
    }
}

private extension ProductsSplitViewWrapperController {
    func configureTabBarItem() {
        title = Localization.tabTitle
        tabBarItem.title = Localization.tabTitle
        tabBarItem.image = .productImage
        tabBarItem.accessibilityIdentifier = "tab-bar-products-item"
    }

    func configureChildViewController() {
        guard let contentView = productsSplitViewController.view else {
            return assertionFailure("Split view not available")
        }
        addChild(productsSplitViewController)
        view.addSubview(contentView)
        productsSplitViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}

extension ProductsSplitViewWrapperController: TabReselectionHandling {
    /// Pops the products list (primary column) to its root, or scrolls it to the top when already at root.
    func handleTabReselection() {
        guard let primaryNavigationController = productsSplitViewController.viewController(for: .primary) as? UINavigationController else {
            return
        }
        if primaryNavigationController.viewControllers.count > 1 {
            primaryNavigationController.popToRootRespectingUnsavedChanges(animated: true)
        } else {
            (primaryNavigationController.topViewController as? ReselectionScrollable)?.scrollToTopOnReselection(animated: true)
        }
    }
}

extension ProductsSplitViewWrapperController {
    private enum Localization {
        static let tabTitle = NSLocalizedString("productsTab.tabTitle",
                                                value: "Products",
                                                comment: "Title of the Products tab — plural form of Product")
    }
}
