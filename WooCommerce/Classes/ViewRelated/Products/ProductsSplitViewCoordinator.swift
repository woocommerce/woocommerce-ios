import Combine
import CocoaLumberjackSwift
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
    private lazy var swipeBackVetoPolicy = ProductsSwipeBackVetoPolicy { [weak self] in
        self?.secondaryNavigationController.shouldPopOnSwipeBack() == false
    }
    private lazy var swipeBackVetoGestureRecognizer = ProductsSwipeBackVetoGestureRecognizer(
        policy: swipeBackVetoPolicy,
        onVeto: { [weak self] gestureRecognizer in
            self?.handleVetoedSwipeBack(gestureRecognizer)
        }
    )
    private lazy var productsViewController = ProductsViewController(siteID: siteID,
                                                                     selectedProduct: selectedProduct,
                                                                     navigateToContent: showFromProductList)
    private let secondaryStackRestorationPolicy = ProductsSecondaryStackRestorationPolicy()

    private var addProductCoordinator: AddProductCoordinator?

    init(siteID: Int64, splitViewController: UISplitViewController) {
        self.siteID = siteID
        self.splitViewController = splitViewController
        self.primaryNavigationController = WooTabNavigationController()
        self.secondaryNavigationController = WooNavigationController()
    }

    /// Called when the split view is ready to be shown, like after the split view is added to the view hierarchy.
    func start() {
        autoSelectProductOnInitialDataLoad()
        configureSplitView()
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
        if shouldAutoSelectProductInExpandedLayout() {
            showEmptyViewOrFirstProduct()
        } else if contentTypes.isEmpty {
            showEmptyView()
        } else {
            refreshSelectedProductRow()
        }
    }

    func refreshExpandedLayoutIfNeeded() {
        refreshSwipeBackVetoRelationships(reason: "layout")

        guard !splitViewController.isCollapsed else {
            return
        }
        didExpand()
    }

    func prepareForLayoutTransition() {
        secondaryStackRestorationPolicy.prepareForTransition(currentStack: secondaryNavigationController.viewControllers)
    }

    func completeLayoutTransition() {
        guard let stackToRestore = secondaryStackRestorationPolicy.stackToRestore(
            currentStack: secondaryNavigationController.viewControllers
        ) else {
            return
        }

        secondaryNavigationController.setViewControllers(stackToRestore, animated: false)
        refreshSwipeBackVetoRelationships(reason: "layout transition completed")
    }

    func startProductCreation() {
        productsViewController.startProductCreation()
    }

    /// Returns the product form of the given product ID being displayed on the secondary column if available.
    func currentProductForm(for productID: Int64) -> ProductFormViewController<ProductFormViewModel>? {
        if let contentType = contentTypes.last,
            case let .productForm(product) = contentType,
            product?.productID == productID {
            return secondaryNavigationController.topViewController as? ProductFormViewController<ProductFormViewModel>
        }
        return nil
    }
}

private extension ProductsSplitViewCoordinator {
    func showFromProductList(content: ProductsViewController.NavigationContentType) {
        switch content {
            case let .productForm(product):
                showProductFormIfNoUnsavedChanges(product: product)
            case let .addProduct(sourceView, isFirstProduct):
                startProductCreationIfNoUnsavedChanges(sourceView: sourceView, isFirstProduct: isFirstProduct)
            case .search:
                let searchCommand = ProductSearchUICommand(siteID: siteID, onProductSelection: { [weak self] product in
                    self?.showProductFormIfNoUnsavedChanges(product: product)
                }, onCancel: { [weak self] in
                    guard let self else { return }
                    primaryNavigationController.viewControllers = [productsViewController]
                    primaryNavigationController.setNavigationBarHiddenIfNeeded(false, animated: false)
                })
                let searchViewController = SearchViewController(storeID: siteID,
                                                                command: searchCommand,
                                                                cellType: ProductsTabProductTableViewCell.self,
                                                                cellSeparator: .none,
                                                                selectedObject: selectedProduct,
                                                                isSelectedObject: {
                    $0.productID == $1?.productID
                })
                primaryNavigationController.viewControllers = [searchViewController]
        }
    }
}

private extension ProductsSplitViewCoordinator {
    func shouldAutoSelectProductInExpandedLayout() -> Bool {
        guard isShowingRegularExpandedLayout() else {
            return false
        }

        if contentTypes.isEmpty {
            return true
        }

        return contentTypes.last == .empty &&
            (primaryNavigationController.topViewController as? ProductsViewController)?.hasFirstProductAvailable() == true
    }

    func isShowingRegularExpandedLayout() -> Bool {
        !splitViewController.isCollapsed &&
            splitViewController.view.bounds.width >= Constants.narrowWindowCompactLayoutThreshold
    }

    func showEmptyView() {
        let config = EmptyStateViewController.Config.simple(
            message: .init(string: Localization.emptyViewMessage),
            image: .productBlouseImage
        )
        let emptyStateViewController = EmptyStateViewController(style: .basic, configuration: config)
        showSecondaryView(contentType: .empty, viewController: emptyStateViewController, replacesNavigationStack: true)
    }

    func showProductFormIfNoUnsavedChanges(product: Product) {
        whenSecondaryViewProductHasNoUnsavedChanges { [weak self] in
            self?.showProductForm(product: product)
        }
    }

    func showProductForm(product: Product) {
        let viewController = ProductDetailNavigator.shared.makeDestination(
            product: product,
            isReadOnly: false,
            onDismissWeb: { [weak self] in
                self?.resyncProducts()
            },
            onDelete: { [weak self] in
                self?.onSecondaryProductFormDeletion()
            },
            onDuplicate: { [weak self] duplicate in
                // Opens the duplicate by replacing the secondary stack (not pushing), keeping the single-product-form
                // invariant and matching Android, where the copy opens and Back returns to the product list.
                self?.showProductForm(product: duplicate)
            })

        showSecondaryView(contentType: .productForm(product: product),
                          viewController: viewController,
                          replacesNavigationStack: true)
    }

    func startProductCreationIfNoUnsavedChanges(sourceView: AddProductCoordinator.SourceView, isFirstProduct: Bool) {
        whenSecondaryViewProductHasNoUnsavedChanges { [weak self] in
            self?.startProductCreation(sourceView: sourceView, isFirstProduct: isFirstProduct)
        }
    }

    func startProductCreation(sourceView: AddProductCoordinator.SourceView, isFirstProduct: Bool) {
        let addProductCoordinator = AddProductCoordinator(siteID: siteID,
                                                          source: .productsTab,
                                                          sourceView: sourceView,
                                                          sourceNavigationController: primaryNavigationController,
                                                          isFirstProduct: isFirstProduct,
                                                          navigateToProductForm: { [weak self] viewController in
            self?.showSecondaryView(contentType: .productForm(product: nil), viewController: viewController, replacesNavigationStack: true)
        }, onDeleteCompletion: { [weak self] in
            self?.onSecondaryProductFormDeletion()
        }, onDuplicateCompletion: { [weak self] duplicatedProduct in
            self?.showProductForm(product: duplicatedProduct)
        })
        addProductCoordinator.onProductCreated = { [weak self] product in
            guard let self, let lastContentType = contentTypes.last, lastContentType == .productForm(product: nil) else { return }
            contentTypes[contentTypes.count - 1] = .productForm(product: product)
        }
        addProductCoordinator.start()
        self.addProductCoordinator = addProductCoordinator
    }

    func whenSecondaryViewProductHasNoUnsavedChanges(then closure: @escaping () -> Void) {
        // Closes the product form in the secondary view only if there are no unsaved changes or if the user chooses to discard the changes.
        // This works based on the assumption that there is only one product form in the secondary navigation stack.
        if let lastProductFormViewController = secondaryNavigationController.viewControllers
            .compactMap({ $0 as? ProductFormViewController<ProductFormViewModel> }).last {
            return lastProductFormViewController.close(completion: {
                closure()
            }, onCancel: { [weak self] in
                guard let self else { return }
                // Reassigns the secondary content types to trigger product list row selection to re-select the product in the secondary view.
                // Otherwise, the most recently tapped row is selected in the table view.
                contentTypes = contentTypes
            })
        } else {
            closure()
        }
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

    func onSecondaryProductFormDeletion() {
        splitViewController.show(.primary)
        if !splitViewController.isCollapsed {
            showEmptyViewOrFirstProduct()
        }
    }

    func resyncProducts() {
        guard let productsViewController = primaryNavigationController.topViewController as? ProductsViewController else { return }
        productsViewController.resync()
    }

    func showEmptyViewOrFirstProduct() {
        showEmptyView()
        switch primaryNavigationController.topViewController {
            case let productsViewController as ProductsViewController:
                productsViewController.selectFirstProductIfAvailable()
            case let productSearchViewController as SearchViewController<ProductsTabProductTableViewCell, ProductSearchUICommand>:
                productSearchViewController.selectFirstObjectIfAvailable()
            case let .some(viewController):
                assertionFailure("Unexpected type for the products tab primary view controller: \(viewController)")
            case .none:
                break
        }
    }
}

private extension ProductsSplitViewCoordinator {
    enum Constants {
        static let narrowWindowCompactLayoutThreshold: CGFloat = 700
    }

    func configureSplitView() {
        primaryNavigationController.viewControllers = [productsViewController]
        splitViewController.setViewController(primaryNavigationController, for: .primary)

        splitViewController.setViewController(secondaryNavigationController, for: .secondary)
        showEmptyView()

        primaryNavigationController.delegate = self
        secondaryNavigationController.delegate = self

        secondaryNavigationController.view.addGestureRecognizer(swipeBackVetoGestureRecognizer)
        refreshSwipeBackVetoRelationships(reason: "configuration")
    }

    func refreshSwipeBackVetoRelationships(reason: String) {
        let primaryGesture = primaryNavigationController.interactivePopGestureRecognizer
        let secondaryGesture = secondaryNavigationController.interactivePopGestureRecognizer
        primaryGesture?.require(toFail: swipeBackVetoGestureRecognizer)
        secondaryGesture?.require(toFail: swipeBackVetoGestureRecognizer)
        DDLogDebug("[WOOMOB-3789] veto refresh reason=\(reason) collapsed=\(splitViewController.isCollapsed) " +
                   "displayMode=\(splitViewController.displayMode.rawValue) " +
                   "primary=\(String(describing: primaryGesture.map(ObjectIdentifier.init))) " +
                   "secondary=\(String(describing: secondaryGesture.map(ObjectIdentifier.init))) " +
                   "vetoView=\(String(describing: swipeBackVetoGestureRecognizer.view.map(ObjectIdentifier.init)))")
    }

    func autoSelectProductOnInitialDataLoad() {
        Publishers.CombineLatest(selectedProduct, productsViewController.onDataReloaded)
            .first(where: { [weak self] selectedProduct, _ in
                guard let self else {
                    return false
                }
                return selectedProduct == nil &&
                    isShowingRegularExpandedLayout()
            })
            .sink { [weak self] _, _ in
                self?.productsViewController.selectFirstProductIfAvailable()
            }
            .store(in: &subscriptions)
    }
}

private extension ProductsSplitViewCoordinator {
    func handleVetoedSwipeBack(_ gestureRecognizer: ProductsSwipeBackVetoGestureRecognizer) {
        let competingPanGestures = splitViewController.view.allDescendantGestureRecognizers
            .compactMap { $0 as? UIPanGestureRecognizer }
            .filter { $0 !== gestureRecognizer }
        competingPanGestures.forEach { $0.isEnabled = false }
        gestureRecognizer.isEnabled = false

        // Presenting the discard sheet interrupts the touch sequence. Reset every recognizer explicitly so the
        // veto is ready for the next swipe and UIKit cannot complete the current pop while the alert is appearing.
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            gestureRecognizer.isEnabled = true
            competingPanGestures.forEach { $0.isEnabled = true }
            self.refreshSwipeBackVetoRelationships(reason: "veto reset")
        }
    }
}

private extension UIView {
    var allDescendantGestureRecognizers: [UIGestureRecognizer] {
        (gestureRecognizers ?? []) + subviews.flatMap(\.allDescendantGestureRecognizers)
    }
}

final class ProductsSwipeBackVetoPolicy {
    private let shouldVetoSwipeBack: () -> Bool

    init(shouldVetoSwipeBack: @escaping () -> Bool) {
        self.shouldVetoSwipeBack = shouldVetoSwipeBack
    }

    func shouldVeto() -> Bool {
        shouldVetoSwipeBack()
    }
}

final class ProductsSecondaryStackRestorationPolicy {
    private var stackBeforeTransition: [UIViewController]?

    func prepareForTransition(currentStack: [UIViewController]) {
        stackBeforeTransition = currentStack
    }

    func stackToRestore(currentStack: [UIViewController]) -> [UIViewController]? {
        defer {
            stackBeforeTransition = nil
        }
        guard let stackBeforeTransition,
              currentStack != stackBeforeTransition else {
            return nil
        }
        return stackBeforeTransition
    }
}

final class ProductsSwipeBackVetoGestureRecognizer: UIGestureRecognizer {
    private let edgeWidth: CGFloat
    private let policy: ProductsSwipeBackVetoPolicy
    private let onVeto: (ProductsSwipeBackVetoGestureRecognizer) -> Void

    init(edgeWidth: CGFloat = 44,
         policy: ProductsSwipeBackVetoPolicy,
         onVeto: @escaping (ProductsSwipeBackVetoGestureRecognizer) -> Void) {
        self.edgeWidth = edgeWidth
        self.policy = policy
        self.onVeto = onVeto
        super.init(target: nil, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first,
              touch.location(in: view).x <= edgeWidth,
              policy.shouldVeto() else {
            state = .failed
            return
        }

        DDLogDebug("[WOOMOB-3789] vetoed at edge touch")
        state = .began
        onVeto(self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        // Once begun, recognizing the touch is sufficient to prevent the native pop gestures.
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed {
            state = .ended
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .began || state == .changed {
            state = .cancelled
        }
    }
}

extension ProductsSplitViewCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Collapsing the split view and updating its navigation stacks can replace or reconfigure the native pop recognizers.
        // Re-establish the dependency after UIKit has finished processing the navigation transition.
        DispatchQueue.main.async { [weak self] in
            self?.refreshSwipeBackVetoRelationships(reason: "didShow \(type(of: viewController))")
        }

        if didNavigateFromTheLastSecondaryViewControllerToProductListInCollapsedMode(navigationController, didShow: viewController, animated: animated) {
            let dismissedProduct = productShownInSecondaryContent()
            DispatchQueue.main.async { [weak self] in
                self?.clearSecondaryContentIfStillShowingProductListInCollapsedMode(dismissedProduct: dismissedProduct)
            }
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
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let tabNavigationController = navigationController as? WooTabNavigationController {
            tabNavigationController.navigationController(navigationController, willShow: viewController, animated: animated)
        }
    }
}

private extension ProductsSplitViewCoordinator {
    /// In the collapsed mode, the secondary navigation controller is added to the primary navigation stack and the primary navigation stack is shown.
    /// When the user taps the back button to leave the last secondary view controller (e.g. product form), we want to reset `contentTypes`
    /// while there is no proper callback that I can find other than observing the primary navigation controller's `didShow`.
    /// As a workaround, it checks the following to empty out the secondary view content types:
    /// - Split view is collapsed
    /// - The navigation controller that did show a view controller is the primary one
    /// - The current content types state is still non-empty, i.e. some secondary content is currently shown
    /// - The view controller to show in the primary navigation stack is the product list
    /// - The navigation is animated, which distinguishes a user navigation from split-view column changes during window resizing
    func didNavigateFromTheLastSecondaryViewControllerToProductListInCollapsedMode(_ navigationController: UINavigationController,
                                                                                    didShow viewController: UIViewController,
                                                                                    animated: Bool) -> Bool {
        let isNavigatingToProductList = viewController == productsViewController ||
        viewController is SearchViewController<ProductsTabProductTableViewCell, ProductSearchUICommand>
        return animated && splitViewController.isCollapsed && navigationController == primaryNavigationController
            && contentTypes.isNotEmpty && isNavigatingToProductList
    }

    func clearSecondaryContentIfStillShowingProductListInCollapsedMode(dismissedProduct: Product?) {
        guard splitViewController.isCollapsed,
              isShowingProductListInPrimaryNavigationController(),
              contentTypes.isNotEmpty else {
            return
        }

        if let dismissedProduct {
            didDismissProductForm(product: dismissedProduct)
        }
        contentTypes = []
        secondaryNavigationController.viewControllers = []
    }

    func isShowingProductListInPrimaryNavigationController() -> Bool {
        let viewController = primaryNavigationController.topViewController
        return viewController == productsViewController ||
            viewController is SearchViewController<ProductsTabProductTableViewCell, ProductSearchUICommand>
    }

    func productShownInSecondaryContent() -> Product? {
        guard let contentType = contentTypes.last,
              case let .productForm(product) = contentType else {
            return nil
        }
        return product
    }

    func refreshSelectedProductRow() {
        guard productShownInSecondaryContent() != nil else {
            return
        }
        contentTypes = contentTypes
    }

    func didDismissProductForm(product: Product) {
        let uploader = ServiceLocator.productImageUploader
        let key = ProductImageUploaderKey(siteID: product.siteID,
                                          productOrVariationID: .product(id: product.productID),
                                          isLocalID: false)
        uploader.startEmittingErrors(key: key)
        uploader.sendBackgroundUploadNoticeIfNeeded(key: key, using: ServiceLocator.noticePresenter)
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
