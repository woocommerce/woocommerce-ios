import UIKit
import Yosemite

/// Coordinates the state of multiple columns (product list and secondary view) based on the secondary view.
final class ProductsSplitViewCoordinator {
    private let siteID: Int64
    private let splitViewController: UISplitViewController
    private let primaryNavigationController: UINavigationController
    private let secondaryNavigationController: UINavigationController
    private lazy var productsViewController = ProductsViewController(siteID: siteID,
                                                                     navigateToContent: showFromProductList)

    private var addProductCoordinator: AddProductCoordinator?

    init(siteID: Int64, splitViewController: UISplitViewController) {
        self.siteID = siteID
        self.splitViewController = splitViewController
        self.primaryNavigationController = WooTabNavigationController()
        self.secondaryNavigationController = WooNavigationController()
    }

    /// Called when the split view is ready to be shown, like after the split view is added to the view hierarchy.
    func start() {
        configureSplitView()
    }
}

private extension ProductsSplitViewCoordinator {
    func showFromProductList(content: ProductsViewController.NavigationContentType) {
        switch content {
            case let .productForm(product):
                showProductForm(product: product)
            case let .addProduct(sourceView, isFirstProduct):
                startProductCreation(sourceView: sourceView, isFirstProduct: isFirstProduct)
        }
    }
}

private extension ProductsSplitViewCoordinator {
    func showEmptyView() {
        let config = EmptyStateViewController.Config.simple(
            message: .init(string: Localization.emptyViewMessage),
            image: .emptyProductsTabImage
        )
        let emptyStateViewController = EmptyStateViewController(style: .basic, configuration: config)
        showSecondaryView(viewController: emptyStateViewController, replacesNavigationStack: true)
    }

    func showProductForm(product: Product) {
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { [weak self] viewController in
            self?.showSecondaryView(viewController: viewController, replacesNavigationStack: true)
        }
    }

    func startProductCreation(sourceView: AddProductCoordinator.SourceView, isFirstProduct: Bool) {
        let addProductCoordinator = AddProductCoordinator(siteID: siteID,
                                                           source: .productsTab,
                                                           sourceView: sourceView,
                                                           sourceNavigationController: primaryNavigationController,
                                                           isFirstProduct: isFirstProduct,
                                                           navigateToProductForm: { [weak self] viewController in
            self?.showSecondaryView(viewController: viewController, replacesNavigationStack: true)
        })
        addProductCoordinator.start()
        self.addProductCoordinator = addProductCoordinator
    }

    func showSecondaryView(viewController: UIViewController, replacesNavigationStack: Bool) {
        if replacesNavigationStack {
            secondaryNavigationController.setViewControllers([viewController], animated: false)
        } else {
            secondaryNavigationController.show(viewController, sender: self)
        }

        splitViewController.show(.secondary)
    }
}

private extension ProductsSplitViewCoordinator {
    func configureSplitView() {
        primaryNavigationController.viewControllers = [productsViewController]
        splitViewController.setViewController(primaryNavigationController, for: .primary)

        splitViewController.setViewController(secondaryNavigationController, for: .secondary)
        showEmptyView()
    }
}

private extension ProductsSplitViewCoordinator {
    private enum Localization {
        static let emptyViewMessage = NSLocalizedString(
            "productsTab.emptySecondaryView.message",
            value: "No product selected",
            comment: "Message on the secondary view of the products tab split view before any product is selected."
        )
    }
}
