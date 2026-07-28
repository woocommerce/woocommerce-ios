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

    @Test
    func popToRootOrScrollToTop_when_a_screen_refuses_to_pop_then_does_not_pop() {
        // Given a stack whose top screen has unsaved changes and refuses to pop.
        let root = UIViewController()
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.pushViewController(NonPoppableViewController(), animated: false)
        #expect(navigationController.viewControllers.count == 2)

        // When re-selecting the tab asks the stack to pop to root.
        navigationController.popToRootOrScrollToTop(animated: false)

        // Then the stack is unchanged, so the unsaved edits are not discarded.
        #expect(navigationController.viewControllers.count == 2)
    }

    @Test
    func popToRootOrScrollToTop_when_an_intermediate_screen_refuses_to_pop_then_does_not_pop() {
        // Given a dirty intermediate screen sitting below a clean top screen that would pop.
        let root = UIViewController()
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.pushViewController(NonPoppableViewController(), animated: false)
        navigationController.pushViewController(UIViewController(), animated: false)
        #expect(navigationController.viewControllers.count == 3)

        // When re-selecting the tab asks the stack to pop to root.
        navigationController.popToRootOrScrollToTop(animated: false)

        // Then the stack is unchanged, so the clean top can't let the dirty screen below be discarded.
        #expect(navigationController.viewControllers.count == 3)
    }
}

/// Refuses to pop, mimicking a screen with unsaved changes.
private final class NonPoppableViewController: UIViewController {
    override func shouldPopOnBackButton() -> Bool {
        false
    }
}
