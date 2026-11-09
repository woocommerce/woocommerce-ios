import Testing
@testable import PointOfSale

struct POSPushTransitionHelperTests {
    @Test func test_navigation_when_item_appears_then_pushes() {
        // When
        let navigation = POSPushTransitionHelper.navigation(from: nil, to: "hardware", isCompletingDrag: false, animatesPop: true)

        // Then
        #expect(navigation == .push)
    }

    @Test func test_navigation_when_item_changes_to_another_then_pushes() {
        // When
        let navigation = POSPushTransitionHelper.navigation(from: "store", to: "hardware", isCompletingDrag: true, animatesPop: true)

        // Then
        #expect(navigation == .push)
    }

    @Test func test_navigation_when_item_is_cleared_then_pops_retaining_the_outgoing_item() {
        // When
        let navigation = POSPushTransitionHelper.navigation(from: "hardware", to: nil, isCompletingDrag: false, animatesPop: true)

        // Then
        #expect(navigation == .pop(retainedItem: "hardware"))
    }

    @Test func test_navigation_when_item_is_cleared_by_a_completed_drag_then_only_settles_state() {
        // When
        let navigation = POSPushTransitionHelper.navigation(from: "hardware", to: nil, isCompletingDrag: true, animatesPop: true)

        // Then
        #expect(navigation == .settleCompletedDrag)
    }

    @Test func test_navigation_when_item_is_cleared_and_pop_is_not_animated_then_pops_without_animation() {
        // When
        let navigation = POSPushTransitionHelper.navigation(from: "hardware", to: nil, isCompletingDrag: false, animatesPop: false)

        // Then
        #expect(navigation == .popWithoutAnimation)
    }

    @Test func test_displayedItem_when_item_is_set_then_shows_it_over_a_popping_item() {
        // When
        let item = POSPushTransitionHelper.displayedItem(item: "payments", poppingItem: "hardware", isSideBySide: false)

        // Then
        #expect(item == "payments")
    }

    @Test func test_displayedItem_when_popping_on_a_phone_then_keeps_the_outgoing_item() {
        // When
        let item = POSPushTransitionHelper.displayedItem(item: nil, poppingItem: "hardware", isSideBySide: false)

        // Then
        #expect(item == "hardware")
    }

    @Test func test_displayedItem_when_cleared_side_by_side_then_shows_nothing() {
        // When
        let item = POSPushTransitionHelper.displayedItem(item: nil, poppingItem: "hardware", isSideBySide: true)

        // Then
        #expect(item == nil)
    }

    @Test func test_invalidatesInFlightDrag_when_back_becomes_unavailable_then_returns_true() {
        // When
        let invalidates = POSPushTransitionHelper.invalidatesInFlightDrag(couldNavigateBack: true, canNavigateBack: false)

        // Then
        #expect(invalidates)
    }

    @Test(arguments: [(false, false), (true, true), (false, true)])
    func test_invalidatesInFlightDrag_when_back_stays_or_becomes_available_then_returns_false(couldNavigateBack: Bool,
                                                                                               canNavigateBack: Bool) {
        // When
        let invalidates = POSPushTransitionHelper.invalidatesInFlightDrag(couldNavigateBack: couldNavigateBack,
                                                                          canNavigateBack: canNavigateBack)

        // Then
        #expect(!invalidates)
    }
}
