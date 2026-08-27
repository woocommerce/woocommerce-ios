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
                                             isSearchProductsBySKUEnabled: false,
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
                                             isSearchProductsBySKUEnabled: false,
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
                                             isSearchProductsBySKUEnabled: false,
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
                                             isSearchProductsBySKUEnabled: false,
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
