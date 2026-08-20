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
    func makeSUT() throws -> (ProductsSplitViewCoordinator, UINavigationController, UINavigationController) {
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let sut = ProductsSplitViewCoordinator(siteID: 123, splitViewController: splitViewController)
        sut.start()
        let primaryNavigationController = try #require(splitViewController.viewController(for: .primary) as? UINavigationController)
        let secondaryNavigationController = try #require(splitViewController.viewController(for: .secondary) as? UINavigationController)
        return (sut, primaryNavigationController, secondaryNavigationController)
    }
}
