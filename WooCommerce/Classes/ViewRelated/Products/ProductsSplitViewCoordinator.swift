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
    private var swipeBackVetoAllowedStartRegion: CGRect?
    private lazy var swipeBackVetoGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer(target: nil, action: nil)
        gestureRecognizer.delegate = self
        gestureRecognizer.maximumNumberOfTouches = 1
        gestureRecognizer.cancelsTouchesInView = true
        gestureRecognizer.delaysTouchesEnded = true
        return gestureRecognizer
    }()
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
        refreshSwipeBackVetoRelationships()

        guard !splitViewController.isCollapsed else {
            return
        }
        didExpand()
    }

    func prepareForLayoutTransition() -> UUID {
        secondaryStackRestorationPolicy.prepareForTransition(currentStack: secondaryNavigationController.viewControllers)
    }

    func completeLayoutTransition(_ transitionID: UUID) {
        guard let stackToRestore = secondaryStackRestorationPolicy.stackToRestore(
            for: transitionID,
            currentStack: secondaryNavigationController.viewControllers
        ) else {
            return
        }

        secondaryNavigationController.setViewControllers(stackToRestore, animated: false)
        refreshSwipeBackVetoRelationships()
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

        splitViewController.view.addGestureRecognizer(swipeBackVetoGestureRecognizer)
        refreshSwipeBackVetoRelationships()
    }

    func refreshSwipeBackVetoRelationships() {
        let usesExpandedRegularLayout = splitViewController.isCollapsed == false &&
            splitViewController.traitCollection.horizontalSizeClass == .regular
        // iPad content-pop gestures can begin throughout the visible detail, while its physical screen edge is reserved for
        // window resizing. In an expanded layout, limit the veto to the detail frame so product-list gestures remain untouched.
        if usesExpandedRegularLayout {
            swipeBackVetoAllowedStartRegion = secondaryNavigationController.view.convert(
                secondaryNavigationController.view.bounds,
                to: splitViewController.view
            )
        } else if splitViewController.traitCollection.userInterfaceIdiom == .pad {
            swipeBackVetoAllowedStartRegion = splitViewController.view.bounds
        } else {
            swipeBackVetoAllowedStartRegion = nil
        }
        let primaryGesture = primaryNavigationController.interactivePopGestureRecognizer
        let secondaryGesture = secondaryNavigationController.interactivePopGestureRecognizer
        primaryGesture?.delegate = primaryNavigationController
        secondaryGesture?.delegate = secondaryNavigationController
        primaryGesture?.require(toFail: swipeBackVetoGestureRecognizer)
        secondaryGesture?.require(toFail: swipeBackVetoGestureRecognizer)

        if #available(iOS 26.0, *) {
            primaryNavigationController.interactiveContentPopGestureRecognizer?.require(toFail: swipeBackVetoGestureRecognizer)
            secondaryNavigationController.interactiveContentPopGestureRecognizer?.require(toFail: swipeBackVetoGestureRecognizer)
        }
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

final class ProductsSecondaryStackRestorationPolicy {
    private var stacksBeforeTransition: [UUID: [UIViewController]] = [:]

    func prepareForTransition(currentStack: [UIViewController]) -> UUID {
        let transitionID = UUID()
        stacksBeforeTransition[transitionID] = currentStack
        return transitionID
    }

    func stackToRestore(for transitionID: UUID, currentStack: [UIViewController]) -> [UIViewController]? {
        guard let stackBeforeTransition = stacksBeforeTransition.removeValue(forKey: transitionID),
              currentStack.count < stackBeforeTransition.count,
              zip(currentStack, stackBeforeTransition).allSatisfy({ current, previous in current === previous }) else {
            return nil
        }
        return stackBeforeTransition
    }
}

extension ProductsSplitViewCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === swipeBackVetoGestureRecognizer,
              let view = gestureRecognizer.view else {
            return true
        }

        let translation = swipeBackVetoGestureRecognizer.translation(in: view)
        let velocity = swipeBackVetoGestureRecognizer.velocity(in: view)
        let direction = translation == .zero ? velocity : translation
        let backTranslation = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? -direction.x : direction.x
        guard backTranslation > abs(direction.y) else {
            return false
        }

        let location = swipeBackVetoGestureRecognizer.location(in: view)
        let startLocation = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
        guard canVetoSwipeBack(startingAt: startLocation, in: view) else {
            return false
        }

        return secondaryNavigationController.shouldPopOnSwipeBack() == false
    }

    private func canVetoSwipeBack(startingAt location: CGPoint, in view: UIView) -> Bool {
        if let swipeBackVetoAllowedStartRegion {
            return swipeBackVetoAllowedStartRegion.contains(location)
        }
        let distanceFromBackEdge = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ?
            view.bounds.maxX - location.x : location.x - view.bounds.minX
        return distanceFromBackEdge <= 44
    }
}

extension ProductsSplitViewCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Split-view stack updates can replace the native pop recognizers, so restore the dependency after navigation settles.
        DispatchQueue.main.async { [weak self] in
            self?.refreshSwipeBackVetoRelationships()
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
