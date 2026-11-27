import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct ProductsSplitViewCoordinatorTests {
    @Test
    func test_navigationController_didShow_productSearch_then_hides_primary_navigation_bar() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        let command = ProductSearchUICommand(siteID: 123,
                                             onProductSelection: { _ in },
                                             onCancel: {})
        let searchViewController = SearchViewController(storeID: 123,
                                                        command: command,
                                                        cellType: ProductsTabProductTableViewCell.self,
                                                        cellSeparator: .none)
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.navigationController(primaryNavigationController, didShow: searchViewController, animated: false)

        // Then
        #expect(primaryNavigationController.navigationBar.isHidden)
    }

    @Test
    func test_navigationController_willShow_productSearch_in_collapsed_layout_then_hides_primary_navigation_bar_for_transition() throws {
        // Given
        let splitViewController = CollapsedSplitViewController(style: .doubleColumn)
        let (sut, primaryNavigationController, _) = try makeSUT(splitViewController: splitViewController)
        let command = ProductSearchUICommand(siteID: 123,
                                             onProductSelection: { _ in },
                                             onCancel: {})
        let searchViewController = SearchViewController(storeID: 123,
                                                        command: command,
                                                        cellType: ProductsTabProductTableViewCell.self,
                                                        cellSeparator: .none)
        primaryNavigationController.setViewControllers([searchViewController], animated: false)
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.navigationController(primaryNavigationController, willShow: searchViewController, animated: true)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden)
    }

    @Test
    func test_navigationController_willShow_secondary_content_in_collapsed_layout_then_shows_primary_navigation_bar_for_transition() throws {
        // Given
        let splitViewController = CollapsedSplitViewController(style: .doubleColumn)
        let (sut, primaryNavigationController, _) = try makeSUT(splitViewController: splitViewController)
        primaryNavigationController.setNavigationBarHidden(true, animated: false)

        // When
        sut.navigationController(primaryNavigationController, willShow: UIViewController(), animated: true)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden == false)
    }

    @Test
    func test_navigationController_didShow_productSearch_when_animated_bar_is_still_visible_then_hides_it_immediately() throws {
        // Given
        let splitViewController = CollapsedSplitViewController(style: .doubleColumn)
        let (sut, primaryNavigationController, _) = try makeSUT(splitViewController: splitViewController)
        let command = ProductSearchUICommand(siteID: 123,
                                             onProductSelection: { _ in },
                                             onCancel: {})
        let searchViewController = SearchViewController(storeID: 123,
                                                        command: command,
                                                        cellType: ProductsTabProductTableViewCell.self,
                                                        cellSeparator: .none)
        primaryNavigationController.setViewControllers([searchViewController], animated: false)
        primaryNavigationController.setNavigationBarHidden(false, animated: false)
        sut.navigationController(primaryNavigationController, willShow: searchViewController, animated: true)
        #expect(primaryNavigationController.isNavigationBarHidden)
        #expect(primaryNavigationController.navigationBar.isHidden == false)

        // When
        sut.navigationController(primaryNavigationController, didShow: searchViewController, animated: true)

        // Then
        #expect(primaryNavigationController.navigationBar.isHidden)
    }

    @Test
    func test_navigationController_didShow_productList_then_shows_primary_navigation_bar() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        let productListViewController = try #require(primaryNavigationController.topViewController)
        primaryNavigationController.setNavigationBarHidden(true, animated: false)

        // When
        sut.navigationController(primaryNavigationController, didShow: productListViewController, animated: false)

        // Then
        #expect(primaryNavigationController.navigationBar.isHidden == false)
    }

    @Test
    func test_hidePrimaryNavigationBarWhenTransitionCompletes_when_swipe_completes_then_hides_the_bar() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.hidePrimaryNavigationBarWhenTransitionCompletes(isCancelled: false)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden)
    }

    @Test
    func test_hidePrimaryNavigationBarWhenTransitionCompletes_when_swipe_is_cancelled_then_leaves_the_bar_visible() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.hidePrimaryNavigationBarWhenTransitionCompletes(isCancelled: true)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden == false)
    }

    @Test
    func test_schedulePrimaryNavigationBarHide_then_waits_until_the_interactive_transition_completes() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        let transitionCoordinator = MockInteractiveTransitionCoordinator()
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.schedulePrimaryNavigationBarHide(after: transitionCoordinator)
        transitionCoordinator.changeInteraction(isCancelled: false)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden == false)
        #expect(primaryNavigationController.navigationBar.isHidden == false)

        // When
        transitionCoordinator.completeTransition(isCancelled: false)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden)
        #expect(primaryNavigationController.navigationBar.isHidden)
    }

    @Test
    func test_cancelProductSearch_when_navigation_bar_is_hidden_then_restores_it() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        primaryNavigationController.setNavigationBarHidden(true, animated: false)

        // When
        sut.cancelProductSearch()

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden == false)
        #expect(primaryNavigationController.navigationBar.isHidden == false)
    }

    @Test
    func test_cancelProductSearch_when_navigation_bar_state_is_out_of_sync_then_shows_the_bar() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        primaryNavigationController.setNavigationBarHidden(false, animated: false)
        // Mimics an interrupted hide animation, where the bar view is still hidden while the navigation
        // controller already reports the bar as visible.
        primaryNavigationController.navigationBar.isHidden = true

        // When
        sut.cancelProductSearch()

        // Then
        #expect(primaryNavigationController.navigationBar.isHidden == false)
    }

    @Test
    func test_cancelProductSearch_then_shows_the_product_list_in_the_primary_column() throws {
        // Given
        let (sut, primaryNavigationController, _) = try makeSUT()
        let productListViewController = try #require(primaryNavigationController.topViewController)
        let command = ProductSearchUICommand(siteID: 123,
                                             onProductSelection: { _ in },
                                             onCancel: {})
        let searchViewController = SearchViewController(storeID: 123,
                                                        command: command,
                                                        cellType: ProductsTabProductTableViewCell.self,
                                                        cellSeparator: .none)
        primaryNavigationController.setViewControllers([searchViewController], animated: false)

        // When
        sut.cancelProductSearch()

        // Then
        #expect(primaryNavigationController.viewControllers.count == 1)
        #expect(primaryNavigationController.topViewController === productListViewController)
    }

    @Test
    func test_navigationController_didShow_secondary_content_then_does_not_change_primary_navigation_bar() throws {
        // Given
        let (sut, primaryNavigationController, secondaryNavigationController) = try makeSUT()
        primaryNavigationController.setNavigationBarHidden(true, animated: false)

        // When
        sut.navigationController(secondaryNavigationController, didShow: UIViewController(), animated: false)

        // Then
        #expect(primaryNavigationController.navigationBar.isHidden)
    }

    // MARK: - Layout transition restoration

    @Test
    func test_completeLayoutTransition_when_collapsing_moved_content_to_the_primary_stack_then_does_not_restore_it_to_the_secondary_one() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let productList = UIViewController()
        let productForm = UIViewController()
        let primaryNavigationController = UINavigationController(rootViewController: productList)
        let secondaryNavigationController = UINavigationController(rootViewController: productForm)
        let navigationStack = SplitViewNavigationStack(splitViewController: splitViewController,
                                                       primaryNavigationController: primaryNavigationController,
                                                       secondaryNavigationController: secondaryNavigationController)
        let policy = ProductsSecondaryStackRestorationPolicy()
        let transitionID = policy.prepareForTransition(currentStack: navigationStack.contentViewControllers)

        // When
        navigationStack.prepareForCollapsing(showsSecondaryContent: true)
        navigationStack.didCollapse()
        let stackToRestore = policy.stackToRestore(for: transitionID, currentStack: navigationStack.contentViewControllers)

        // Then
        #expect(stackToRestore == nil)
        #expect(secondaryNavigationController.viewControllers.isEmpty)
        #expect(navigationStack.navigationItemsHaveSingleOwners())
    }

    @Test
    func test_completeLayoutTransition_when_the_transition_dropped_a_pushed_screen_then_restores_it() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let productList = UIViewController()
        let productForm = UIViewController()
        let inventorySettings = UIViewController()
        let primaryNavigationController = UINavigationController(rootViewController: productList)
        let secondaryNavigationController = UINavigationController(rootViewController: productForm)
        secondaryNavigationController.pushViewController(inventorySettings, animated: false)
        let navigationStack = SplitViewNavigationStack(splitViewController: splitViewController,
                                                       primaryNavigationController: primaryNavigationController,
                                                       secondaryNavigationController: secondaryNavigationController)
        let policy = ProductsSecondaryStackRestorationPolicy()
        let transitionID = policy.prepareForTransition(currentStack: navigationStack.contentViewControllers)

        // When
        // Mimics UIKit dropping the pushed screen during the layout transition.
        secondaryNavigationController.setViewControllers([productForm], animated: false)
        let stackToRestore = policy.stackToRestore(for: transitionID, currentStack: navigationStack.contentViewControllers)

        // Then
        #expect(stackToRestore == [productForm, inventorySettings])
    }

    @Test
    func test_removeAllContent_when_primary_already_contains_only_root_then_does_not_replace_root_stack() {
        // Given: UIKit has completed the compact Back transition before the coordinator clears its content state.
        let splitViewController = CollapsedSplitViewController(style: .doubleColumn)
        let productList = UIViewController()
        let productForm = UIViewController()
        let primaryNavigationController = ViewControllersUpdateSpyNavigationController()
        let secondaryNavigationController = UINavigationController(rootViewController: productForm)
        primaryNavigationController.setViewControllers([productList], animated: false)
        let navigationStack = SplitViewNavigationStack(splitViewController: splitViewController,
                                                       primaryNavigationController: primaryNavigationController,
                                                       secondaryNavigationController: secondaryNavigationController)
        navigationStack.prepareForCollapsing(showsSecondaryContent: true)
        navigationStack.didCollapse()
        primaryNavigationController.setViewControllers([productList], animated: false)
        primaryNavigationController.resetViewControllerUpdates()

        // When
        navigationStack.removeAllContent()

        // Then: do not replace the identical root stack after UIKit has finished showing it.
        #expect(primaryNavigationController.viewControllerUpdates.isEmpty)
        #expect(primaryNavigationController.viewControllers == [productList])
        #expect(secondaryNavigationController.viewControllers.isEmpty)
    }

    // MARK: - Swipe back veto

    @Test
    func test_contentRefusesSwipeBack_when_the_content_is_in_the_secondary_stack_then_asks_the_content_screen() throws {
        // Given
        let (sut, _, secondaryNavigationController) = try makeSUT()
        secondaryNavigationController.setViewControllers([UnsavedChangesViewController()], animated: false)

        // When
        let refusesSwipeBack = sut.contentRefusesSwipeBack()

        // Then
        #expect(refusesSwipeBack)
    }

    @Test
    func test_topContentViewController_when_collapsing_moved_the_content_to_the_primary_stack_then_still_reports_the_content_screen() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let productList = UIViewController()
        let productForm = UnsavedChangesViewController()
        let primaryNavigationController = UINavigationController(rootViewController: productList)
        let secondaryNavigationController = UINavigationController(rootViewController: productForm)
        let navigationStack = SplitViewNavigationStack(splitViewController: splitViewController,
                                                       primaryNavigationController: primaryNavigationController,
                                                       secondaryNavigationController: secondaryNavigationController)

        // When
        navigationStack.prepareForCollapsing(showsSecondaryContent: true)
        navigationStack.didCollapse()

        // Then
        #expect(primaryNavigationController.topViewController === productForm)
        #expect(secondaryNavigationController.viewControllers.isEmpty)
        // The swipe back veto asks this screen. Reading the secondary navigation controller instead would find
        // no top view controller here, and the unsaved changes protection would silently stand down.
        #expect(navigationStack.topContentViewController?.shouldPopOnSwipeBack() == false)
    }

    @Test
    func test_contentRefusesSwipeBack_when_there_is_no_content_then_allows_the_swipe() throws {
        // Given
        let (sut, _, secondaryNavigationController) = try makeSUT()
        secondaryNavigationController.setViewControllers([], animated: false)

        // When
        let refusesSwipeBack = sut.contentRefusesSwipeBack()

        // Then
        #expect(refusesSwipeBack == false)
    }

    // MARK: - Store Design System

    @Test(arguments: [true, false])
    func test_start_then_creates_the_product_list_with_the_storeDesignSystem_flag(isFlagOn: Bool) throws {
        // Given
        let featureFlagService = makeFeatureFlagService(usesStoreDesignSystem: isFlagOn)

        // When
        let (_, primaryNavigationController, _) = try makeSUT(featureFlagService: featureFlagService)

        // Then
        let list = try #require(primaryNavigationController.topViewController as? ProductsViewController)
        #expect(list.usesStoreDesignSystem == isFlagOn)
    }

    @Test(arguments: [true, false])
    func test_search_then_shows_the_search_cell_that_matches_the_storeDesignSystem_flag(isFlagOn: Bool) throws {
        // Given: flag off must keep the shipped legacy search cell
        let featureFlagService = makeFeatureFlagService(usesStoreDesignSystem: isFlagOn)
        let (_, primaryNavigationController, _) = try makeSUT(featureFlagService: featureFlagService)
        let list = try #require(primaryNavigationController.topViewController)
        list.loadViewIfNeeded()
        let searchButton = try #require(list.navigationItem.rightBarButtonItems?.first { $0.accessibilityIdentifier == "product-search-button" })

        // When
        UIApplication.shared.sendAction(try #require(searchButton.action), to: searchButton.target, from: searchButton, for: nil)

        // Then
        let search = primaryNavigationController.topViewController
        #expect((search is SearchViewController<StoreProductListTableViewCell, ProductSearchUICommand>) == isFlagOn)
        #expect((search is SearchViewController<ProductsTabProductTableViewCell, ProductSearchUICommand>) == !isFlagOn)
    }

    @Test(arguments: [true, false])
    func test_navigationController_willShow_and_didShow_productSearch_in_either_design_then_hides_primary_navigation_bar(
        usesStoreDesignSystem: Bool
    ) throws {
        // Given: the coordinator must recognise product search with either list design's cell
        let (sut, primaryNavigationController, _) = try makeSUT(splitViewController: CollapsedSplitViewController(style: .doubleColumn))
        let command = ProductSearchUICommand(siteID: 123, onProductSelection: { _ in }, onCancel: {})
        let searchViewController: UIViewController = usesStoreDesignSystem
            ? SearchViewController(storeID: 123, command: command, cellType: StoreProductListTableViewCell.self, cellSeparator: .none)
            : SearchViewController(storeID: 123, command: command, cellType: ProductsTabProductTableViewCell.self, cellSeparator: .none)
        primaryNavigationController.setViewControllers([searchViewController], animated: false)
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.navigationController(primaryNavigationController, willShow: searchViewController, animated: false)
        sut.navigationController(primaryNavigationController, didShow: searchViewController, animated: false)

        // Then
        #expect(primaryNavigationController.isNavigationBarHidden)
        #expect(primaryNavigationController.navigationBar.isHidden)
    }

    @Test
    func test_navigationController_didShow_when_UIKit_passes_a_null_view_controller_in_collapsed_layout_with_content_then_does_not_crash() throws {
        // Given: content shown, then collapsed, as when deleting a product on iPad
        let splitViewController = CollapsibleSplitViewController(style: .doubleColumn)
        let (sut, primaryNavigationController, _) = try makeSUT(splitViewController: splitViewController)
        sut.didExpand()
        splitViewController.stubbedIsCollapsed = true
        // UIKit passes null to `didShow` after `removeAllContent`, though Swift types it as non-optional.
        let nullViewController = unsafeBitCast(0, to: UIViewController.self)
        primaryNavigationController.setNavigationBarHidden(false, animated: false)

        // When
        sut.navigationController(primaryNavigationController, didShow: nullViewController, animated: true)

        // Then
        #expect(primaryNavigationController.navigationBar.isHidden == false)
    }
}

private extension ProductsSplitViewCoordinatorTests {
    func makeSUT(
        splitViewController: UISplitViewController = UISplitViewController(style: .doubleColumn),
        featureFlagService: MockFeatureFlagService? = nil
    ) throws -> (ProductsSplitViewCoordinator, UINavigationController, UINavigationController) {
        let sut = ProductsSplitViewCoordinator(siteID: 123,
                                               splitViewController: splitViewController,
                                               featureFlagService: featureFlagService ?? makeFeatureFlagService(usesStoreDesignSystem: false))
        sut.start()
        let primaryNavigationController = try #require(splitViewController.viewController(for: .primary) as? UINavigationController)
        let secondaryNavigationController = try #require(splitViewController.viewController(for: .secondary) as? UINavigationController)
        return (sut, primaryNavigationController, secondaryNavigationController)
    }

    func makeFeatureFlagService(usesStoreDesignSystem: Bool) -> MockFeatureFlagService {
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = usesStoreDesignSystem
        return featureFlagService
    }
}

private final class CollapsedSplitViewController: UISplitViewController {
    override var isCollapsed: Bool { true }
}

private final class CollapsibleSplitViewController: UISplitViewController {
    var stubbedIsCollapsed = false
    override var isCollapsed: Bool { stubbedIsCollapsed }
}

private final class MockInteractiveTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    private var interactionChangeHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void)?
    private var completionHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void)?

    private(set) var isCancelled = false

    func changeInteraction(isCancelled: Bool) {
        self.isCancelled = isCancelled
        interactionChangeHandler?(self)
    }

    func completeTransition(isCancelled: Bool) {
        self.isCancelled = isCancelled
        completionHandler?(self)
    }

    func animate(alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
                 completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        completionHandler = completion
        return true
    }

    func animateAlongsideTransition(in view: UIView?,
                                    animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
                                    completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool {
        completionHandler = completion
        return true
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {
        interactionChangeHandler = handler
    }

    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {
        interactionChangeHandler = handler
    }

    let isAnimated = true
    let presentationStyle: UIModalPresentationStyle = .none
    let initiallyInteractive = true
    let isInterruptible = true
    let isInteractive = true
    let transitionDuration: TimeInterval = 0.35
    let percentComplete: CGFloat = 0
    let completionVelocity: CGFloat = 1
    let completionCurve: UIView.AnimationCurve = .easeInOut

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        nil
    }

    let containerView = UIView()
    let targetTransform: CGAffineTransform = .identity
}

private final class ViewControllersUpdateSpyNavigationController: UINavigationController {
    private(set) var viewControllerUpdates: [[UIViewController]] = []

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllerUpdates.append(viewControllers)
        super.setViewControllers(viewControllers, animated: animated)
    }

    func resetViewControllerUpdates() {
        viewControllerUpdates = []
    }
}

/// Stands in for a screen that blocks the swipe back, like a product form with unsaved changes.
private final class UnsavedChangesViewController: UIViewController {
    override func shouldPopOnSwipeBack() -> Bool {
        false
    }
}
