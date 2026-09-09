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
}

private extension ProductsSplitViewCoordinatorTests {
    func makeSUT(
        splitViewController: UISplitViewController = UISplitViewController(style: .doubleColumn)
    ) throws -> (ProductsSplitViewCoordinator, UINavigationController, UINavigationController) {
        let sut = ProductsSplitViewCoordinator(siteID: 123, splitViewController: splitViewController)
        sut.start()
        let primaryNavigationController = try #require(splitViewController.viewController(for: .primary) as? UINavigationController)
        let secondaryNavigationController = try #require(splitViewController.viewController(for: .secondary) as? UINavigationController)
        return (sut, primaryNavigationController, secondaryNavigationController)
    }
}

private final class CollapsedSplitViewController: UISplitViewController {
    override var isCollapsed: Bool { true }
}

@objc private final class MockInteractiveTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
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
