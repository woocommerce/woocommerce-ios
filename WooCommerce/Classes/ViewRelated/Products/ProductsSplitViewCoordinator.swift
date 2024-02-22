import Combine
import UIKit
import Yosemite

/// Coordinates the state of multiple columns (product list and secondary view) based on the secondary view.
final class ProductsSplitViewCoordinator: NSObject {
    /// Content type that is shown in the secondary view.
    enum SecondaryViewContentType: Equatable {
        case empty
        case productForm(product: Product?)
    }

    /// The source of truth of the content shown in the secondary view.
    @Published private var contentTypes: [SecondaryViewContentType] = []
    private var selectedProduct: AnyPublisher<Product?, Never> {
        $contentTypes.map { contentTypes -> Product? in
            guard let contentType = contentTypes.last, case let .productForm(product) = contentType else {
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
                                                                     selectedProduct: selectedProduct,
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
        autoSelectProductOnInitialDataLoad()
    }

    /// Called when the split view is collapsing from the expanded state to determine which column to show in the collapsed mode.
    /// - Returns: The column to show when the split view is collapsed.
    func columnToShowWhenSplitViewIsCollapsing() -> UISplitViewController.Column {
        guard let lastContentType = contentTypes.last else {
            return .primary
        }
        return lastContentType == .empty ? .primary : .secondary
    }

    /// Called when the split view transitions from collapsed to expanded mode.
    func didExpand() {
        // Auto-selects the first product if there is no content to be shown.
        if contentTypes.isEmpty {
            showEmptyView()
            productsViewController.selectFirstProductIfAvailable()
        }
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
                                             forceReadOnly: false,
                                             onDeleteCompletion: { [weak self] in
            self?.productsViewController.selectFirstProductIfAvailable()
        }) { [weak self] viewController in
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

        primaryNavigationController.delegate = self
        secondaryNavigationController.delegate = self
    }

    func autoSelectProductOnInitialDataLoad() {
        Publishers.CombineLatest(selectedProduct, productsViewController.onDataReloaded)
            .filter { [weak self] selectedProduct, onDataReloaded in
                guard let self else {
                    return false
                }
                return selectedProduct == nil && !splitViewController.isCollapsed
            }
            .first()
            .sink { [weak self] selectedProduct, onDataReloaded in
                self?.productsViewController.selectFirstProductIfAvailable()
            }
            .store(in: &subscriptions)
    }
}

extension ProductsSplitViewCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if willNavigateFromTheLastSecondaryViewControllerToProductListInCollapsedMode(navigationController, willShow: viewController) {
            contentTypes = []
            secondaryNavigationController.viewControllers = []
            return
        }

        // The goal here is to detect when the user pops a view controller in the secondary navigation stack like from tapping the back button,
        // so that the secondary content types state can be updated accordingly.
        // There is no proper way that I can find to detect this, as a workaround it checks whether the secondary navigation stack has fewer
        // view controllers than the latest content types state when a different view controller is about to show.
        guard navigationController == secondaryNavigationController else {
            return
        }
        if navigationController.viewControllers.count < contentTypes.count {
            contentTypes.removeLast()
        }
    }
}

private extension ProductsSplitViewCoordinator {
    /// In the collapsed mode, the secondary navigation controller is added to the primary navigation stack and the primary navigation stack is shown.
    /// When the user taps the back button to leave the last secondary view controller (e.g. product form), we want to reset `contentTypes`
    /// while there is no proper callback that I can find other than observing the primary navigation controller's `willShow`.
    /// As a workaround, it checks the following to empty out the secondary view content types:
    /// - Split view is collapsed
    /// - The navigation controller that will show a view controller is the primary one
    /// - The current content types state is still non-empty, i.e. some secondary content is currently shown
    /// - The view controller to show in the primary navigation stack is the product list
    func willNavigateFromTheLastSecondaryViewControllerToProductListInCollapsedMode(_ navigationController: UINavigationController,
                                                                                    willShow viewController: UIViewController) -> Bool {
        splitViewController.isCollapsed && navigationController == primaryNavigationController
            && contentTypes.isNotEmpty && viewController == productsViewController
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
