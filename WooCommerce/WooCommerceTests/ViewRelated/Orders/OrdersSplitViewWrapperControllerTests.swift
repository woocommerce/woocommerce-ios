import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct OrdersSplitViewWrapperControllerTests {
    @Test func presenting_order_loader_reuses_secondary_navigation_controller() throws {
        // Given
        let viewController = OrdersSplitViewWrapperController(siteID: 123)
        viewController.loadViewIfNeeded()
        let splitViewController = try #require(viewController.children.first as? UISplitViewController)
        let initialNavigationController = try #require(
            splitViewController.viewController(for: .secondary) as? UINavigationController
        )

        // When
        viewController.presentDetails(for: 456, siteID: 123)

        // Then
        let updatedNavigationController = try #require(
            splitViewController.viewController(for: .secondary) as? UINavigationController
        )
        #expect(updatedNavigationController === initialNavigationController)
        #expect(updatedNavigationController.topViewController is OrderLoaderViewController)
    }
}
