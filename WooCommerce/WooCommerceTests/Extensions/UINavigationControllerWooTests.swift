import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct UINavigationControllerWooTests {

    @Test
    func popToRootOrScrollToTop_when_stack_has_multiple_view_controllers_then_pops_to_root() {
        // Given a navigation stack that has been pushed beyond its root (e.g. after tapping into a detail).
        let root = UIViewController()
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.pushViewController(UIViewController(), animated: false)
        navigationController.pushViewController(UIViewController(), animated: false)
        #expect(navigationController.viewControllers.count == 3)

        // When re-selecting the tab asks the stack to pop to root.
        navigationController.popToRootOrScrollToTop(animated: false)

        // Then only the root remains, so re-selecting the tab returns it to its root screen.
        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first === root)
    }

    @Test
    func popToRootOrScrollToTop_when_stack_is_already_at_root_then_stays_at_root() {
        // Given a navigation stack that is already showing its root screen.
        let root = UIViewController()
        let navigationController = UINavigationController(rootViewController: root)
        #expect(navigationController.viewControllers.count == 1)

        // When re-selecting the tab asks the stack to pop to root (scroll-to-top branch).
        navigationController.popToRootOrScrollToTop(animated: false)

        // Then the root is preserved and never popped below a single view controller.
        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first === root)
    }
}
