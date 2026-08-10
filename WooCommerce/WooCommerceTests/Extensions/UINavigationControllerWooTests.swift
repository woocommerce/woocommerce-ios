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
    func popToRootOrScrollToTop_when_an_intermediate_screen_refuses_to_pop_then_pops_to_that_screen() {
        // Given a dirty intermediate screen sitting below a clean top screen that would pop.
        let root = UIViewController()
        let nonPoppable = NonPoppableViewController()
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.pushViewController(nonPoppable, animated: false)
        navigationController.pushViewController(UIViewController(), animated: false)
        #expect(navigationController.viewControllers.count == 3)

        // When re-selecting the tab asks the stack to pop to root.
        navigationController.popToRootOrScrollToTop(animated: false)

        // Then the stack pops down to the refusing screen, making the unsaved changes visible instead of discarding them.
        #expect(navigationController.viewControllers.count == 2)
        #expect(navigationController.topViewController === nonPoppable)
    }

    @Test
    func screens_when_element_is_a_plain_screen_then_returns_just_that_screen() {
        // Given a stack element that is an ordinary screen.
        let screen = UIViewController()

        // When collecting the screens it stands for.
        let screens = UINavigationController.screens(in: screen)

        // Then it stands only for itself.
        #expect(screens == [screen])
    }

    @Test
    func screens_when_element_is_a_navigation_controller_then_returns_its_screens_top_down() {
        // Given a collapsed split view's column, which sits in the stack as a navigation controller.
        let columnRoot = UIViewController()
        let pushedScreen = UIViewController()
        let column = UINavigationController(rootViewController: columnRoot)
        column.pushViewController(pushedScreen, animated: false)

        // When collecting the screens it stands for.
        let screens = UINavigationController.screens(in: column)

        // Then every screen inside is asked, starting from the visible one, so a dirty screen
        // below the top is not skipped.
        #expect(screens == [pushedScreen, columnRoot])
    }

    @Test
    func popToRootOrScrollToTop_when_already_at_root_then_returns_true() {
        // Given a navigation stack that is already showing its root screen.
        let navigationController = UINavigationController(rootViewController: UIViewController())

        // When re-selecting the tab asks the stack to pop to root.
        let atRoot = navigationController.popToRootOrScrollToTop(animated: false)

        // Then the stack reports being at its root.
        #expect(atRoot)
    }

    @Test
    func popToRootOrScrollToTop_when_stack_pops_then_returns_true() {
        // Given a navigation stack that has been pushed beyond its root.
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(UIViewController(), animated: false)

        // When re-selecting the tab asks the stack to pop to root.
        let atRoot = navigationController.popToRootOrScrollToTop(animated: false)

        // Then the stack pops and reports being at its root.
        #expect(atRoot)
        #expect(navigationController.viewControllers.count == 1)
    }

    @Test
    func popToRootOrScrollToTop_when_a_screen_refuses_to_pop_then_returns_false() {
        // Given a stack whose top screen has unsaved changes and refuses to pop.
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(NonPoppableViewController(), animated: false)

        // When re-selecting the tab asks the stack to pop to root.
        let atRoot = navigationController.popToRootOrScrollToTop(animated: false)

        // Then the stack is unchanged and reports the refusal.
        #expect(!atRoot)
        #expect(navigationController.viewControllers.count == 2)
    }
}

/// Refuses to pop, mimicking a screen with unsaved changes.
private final class NonPoppableViewController: UIViewController {
    override func shouldPopOnBackButton() -> Bool {
        false
    }
}
