import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct ProductsSecondaryStackRestorationPolicyTests {
    @Test func test_stack_to_restore_when_stack_changes_during_transition_then_returns_original_stack() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        sut.prepareForTransition(currentStack: originalStack)

        // When
        let stackToRestore = sut.stackToRestore(currentStack: [originalStack[0]])

        // Then
        #expect(stackToRestore == originalStack)
    }

    @Test func test_stack_to_restore_when_stack_does_not_change_then_returns_nil() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        sut.prepareForTransition(currentStack: originalStack)

        // When
        let stackToRestore = sut.stackToRestore(currentStack: originalStack)

        // Then
        #expect(stackToRestore == nil)
    }

    @Test func test_stack_to_restore_after_first_completion_then_clears_saved_stack() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        sut.prepareForTransition(currentStack: originalStack)
        _ = sut.stackToRestore(currentStack: [originalStack[0]])

        // When
        let stackToRestore = sut.stackToRestore(currentStack: [])

        // Then
        #expect(stackToRestore == nil)
    }
}
