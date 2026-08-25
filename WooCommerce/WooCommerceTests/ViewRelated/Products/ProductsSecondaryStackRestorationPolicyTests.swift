import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct ProductsSecondaryStackRestorationPolicyTests {
    @Test func test_stack_to_restore_when_stack_changes_during_transition_then_returns_original_stack() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        let transitionID = sut.prepareForTransition(currentStack: originalStack)

        // When
        let stackToRestore = sut.stackToRestore(for: transitionID, currentStack: [originalStack[0]])

        // Then
        #expect(stackToRestore == originalStack)
    }

    @Test func test_stack_to_restore_when_stack_does_not_change_then_returns_nil() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        let transitionID = sut.prepareForTransition(currentStack: originalStack)

        // When
        let stackToRestore = sut.stackToRestore(for: transitionID, currentStack: originalStack)

        // Then
        #expect(stackToRestore == nil)
    }

    @Test func test_stack_to_restore_after_first_completion_then_clears_saved_stack() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        let transitionID = sut.prepareForTransition(currentStack: originalStack)
        _ = sut.stackToRestore(for: transitionID, currentStack: [originalStack[0]])

        // When
        let stackToRestore = sut.stackToRestore(for: transitionID, currentStack: [])

        // Then
        #expect(stackToRestore == nil)
    }

    @Test func test_stack_to_restore_when_stack_is_replaced_during_transition_then_returns_nil() {
        // Given
        let originalStack = [UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        let transitionID = sut.prepareForTransition(currentStack: originalStack)

        // When
        let stackToRestore = sut.stackToRestore(for: transitionID, currentStack: [UIViewController()])

        // Then
        #expect(stackToRestore == nil)
    }

    @Test func test_stack_to_restore_when_transitions_overlap_then_uses_each_transition_snapshot() {
        // Given
        let firstStack = [UIViewController(), UIViewController()]
        let secondStack = [UIViewController(), UIViewController(), UIViewController()]
        let sut = ProductsSecondaryStackRestorationPolicy()
        let firstTransitionID = sut.prepareForTransition(currentStack: firstStack)
        let secondTransitionID = sut.prepareForTransition(currentStack: secondStack)

        // When
        let firstStackToRestore = sut.stackToRestore(for: firstTransitionID, currentStack: [firstStack[0]])
        let secondStackToRestore = sut.stackToRestore(for: secondTransitionID, currentStack: [secondStack[0], secondStack[1]])

        // Then
        #expect(firstStackToRestore == firstStack)
        #expect(secondStackToRestore == secondStack)
    }
}
