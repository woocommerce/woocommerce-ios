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

    @Test func collapsing_orders_with_detail_transfers_its_navigation_item_to_the_primary_bar() throws {
        // Given
        let viewController = OrdersSplitViewWrapperController(siteID: 123)
        viewController.loadViewIfNeeded()
        let splitViewController = try #require(viewController.children.first as? WooSplitViewController)
        let primaryNavigationController = try #require(
            splitViewController.viewController(for: .primary) as? UINavigationController
        )
        let secondaryNavigationController = try #require(
            splitViewController.viewController(for: .secondary) as? UINavigationController
        )
        viewController.presentDetails(for: 456, siteID: 123)
        let detailViewController = try #require(secondaryNavigationController.topViewController)

        // When
        let selectedColumn = splitViewController.splitViewController(
            splitViewController,
            topColumnForCollapsingToProposedTopColumn: .secondary
        )

        // Then
        #expect(selectedColumn == .primary)
        #expect(primaryNavigationController.topViewController === detailViewController)
        #expect(secondaryNavigationController.viewControllers.isEmpty)
        #expect(primaryNavigationController.navigationBar.items?.contains(where: { $0 === detailViewController.navigationItem }) == true)
        #expect(secondaryNavigationController.navigationBar.items?.contains(where: { $0 === detailViewController.navigationItem }) == false)
    }

    @Test func collapsing_split_view_moves_content_between_navigation_bars_without_shared_items() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let rootViewController = UIViewController()
        let detailViewController = UIViewController()
        let primaryNavigationController = UINavigationController(rootViewController: rootViewController)
        let secondaryNavigationController = UINavigationController(rootViewController: detailViewController)
        let sut = SplitViewNavigationStack(splitViewController: splitViewController,
                                           primaryNavigationController: primaryNavigationController,
                                           secondaryNavigationController: secondaryNavigationController)

        // When
        sut.prepareForCollapsing(showsSecondaryContent: true)

        // Then
        #expect(primaryNavigationController.viewControllers == [rootViewController, detailViewController])
        #expect(secondaryNavigationController.viewControllers.isEmpty)
        #expect(detailViewController.navigationController === primaryNavigationController)
        #expect(primaryNavigationController.navigationBar.items?.contains(where: { $0 === detailViewController.navigationItem }) == true)
        #expect(secondaryNavigationController.navigationBar.items?.contains(where: { $0 === detailViewController.navigationItem }) == false)
        #expect(sut.navigationItemsHaveSingleOwners())
    }

    @Test func expanding_split_view_removes_content_from_primary_before_restoring_secondary() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let rootViewController = UIViewController()
        let detailViewController = UIViewController()
        let childViewController = UIViewController()
        let primaryNavigationController = UINavigationController(rootViewController: rootViewController)
        let secondaryNavigationController = UINavigationController()
        secondaryNavigationController.viewControllers = [detailViewController, childViewController]
        let sut = SplitViewNavigationStack(splitViewController: splitViewController,
                                           primaryNavigationController: primaryNavigationController,
                                           secondaryNavigationController: secondaryNavigationController)
        sut.prepareForCollapsing(showsSecondaryContent: true)

        // When
        sut.didExpand()

        // Then
        #expect(primaryNavigationController.viewControllers == [rootViewController])
        #expect(secondaryNavigationController.viewControllers == [detailViewController, childViewController])
        #expect(detailViewController.navigationController === secondaryNavigationController)
        #expect(childViewController.navigationController === secondaryNavigationController)
        #expect(primaryNavigationController.navigationBar.items?.contains(where: { $0 === detailViewController.navigationItem }) == false)
        #expect(secondaryNavigationController.navigationBar.items?.contains(where: { $0 === detailViewController.navigationItem }) == true)
        #expect(sut.navigationItemsHaveSingleOwners())
    }

    @Test func replacing_collapsed_content_detaches_previous_controller_before_attaching_replacement() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        let rootViewController = UIViewController()
        let initialDetailViewController = UIViewController()
        let replacementDetailViewController = UIViewController()
        let primaryNavigationController = UINavigationController(rootViewController: rootViewController)
        let secondaryNavigationController = UINavigationController(rootViewController: initialDetailViewController)
        let sut = SplitViewNavigationStack(splitViewController: splitViewController,
                                           primaryNavigationController: primaryNavigationController,
                                           secondaryNavigationController: secondaryNavigationController)
        sut.prepareForCollapsing(showsSecondaryContent: true)

        // When
        sut.setContentViewControllers([replacementDetailViewController], showsInCollapsedLayout: true)

        // Then
        #expect(initialDetailViewController.navigationController == nil)
        #expect(replacementDetailViewController.navigationController === primaryNavigationController)
        #expect(primaryNavigationController.viewControllers == [rootViewController, replacementDetailViewController])
        #expect(secondaryNavigationController.viewControllers.isEmpty)
        #expect(sut.navigationItemsHaveSingleOwners())
    }
}
