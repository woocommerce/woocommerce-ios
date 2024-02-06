import Combine
import UIKit
import Yosemite

/// Coordinates the state of multiple columns (product list and secondary view) based on the secondary view.
final class ProductsSplitViewCoordinator {
    /// Content type that is shown in the secondary view.
    enum SecondaryViewContentType: Equatable {
        case empty
        case productForm(product: Product?)
    }

    @Published private var contentTypes: [SecondaryViewContentType] = []
    private var selectedProduct: AnyPublisher<Product?, Never> {
        $contentTypes.map { contentTypes -> Product? in
            guard let contentType = contentTypes.last else {
                return nil
            }
            guard case let .productForm(product) = contentType else {
                return nil
            }
            return product
        }.eraseToAnyPublisher()
    }
    private var subscriptions: Set<AnyCancellable> = []

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
        self.primaryNavigationController = WooNavigationController()
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
        showSecondaryView(contentType: .empty, viewController: emptyStateViewController, replacesNavigationStack: true)
    }

    func showProductForm(product: Product) {
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { [weak self] viewController in
            self?.showSecondaryView(contentType: .productForm(product: product), viewController: viewController, replacesNavigationStack: true)
        }
    }

    func startProductCreation(sourceView: AddProductCoordinator.SourceView, isFirstProduct: Bool) {
        let replacesNavigationStack = contentTypes.last == .empty
        let addProductCoordinator = AddProductCoordinator(siteID: siteID,
                                                           source: .productsTab,
                                                           sourceView: sourceView,
                                                           sourceNavigationController: primaryNavigationController,
                                                           isFirstProduct: isFirstProduct,
                                                           navigateToProductForm: { [weak self] viewController in
            self?.showSecondaryView(contentType: .productForm(product: nil), viewController: viewController, replacesNavigationStack: replacesNavigationStack)
        })
        addProductCoordinator.onProductCreated = { [weak self] product in
            guard let self, let lastContentType = contentTypes.last, lastContentType == .productForm(product: nil) else { return }
            contentTypes[contentTypes.count - 1] = .productForm(product: product)
        }
        addProductCoordinator.start()
        self.addProductCoordinator = addProductCoordinator
    }

    func showSecondaryView(contentType: SecondaryViewContentType, viewController: UIViewController, replacesNavigationStack: Bool) {
        if replacesNavigationStack {
            secondaryNavigationController.setViewControllers([viewController], animated: false)
            contentTypes = [contentType]
        } else {
            secondaryNavigationController.pushViewController(viewController, animated: false)
            contentTypes.append(contentType)
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
