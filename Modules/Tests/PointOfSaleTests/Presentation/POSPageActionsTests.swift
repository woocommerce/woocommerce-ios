import Testing
@testable import PointOfSale

@MainActor
struct POSPageActionsTests {
    @Test func test_allActions_when_there_are_no_actions_then_is_empty() {
        // Given
        let actions = POSPageActions.none

        // When
        let ids = actions.allActions.map(\.id)

        // Then
        #expect(ids.isEmpty)
    }

    @Test func test_allActions_when_primary_and_secondary_are_set_then_lists_primary_first() {
        // Given
        let actions = POSPageActions(primary: Self.action("refund"), secondary: [Self.action("email"), Self.action("print")])

        // When
        let ids = actions.allActions.map(\.id)

        // Then
        #expect(ids == ["refund", "email", "print"])
    }

    @Test func test_allActions_when_only_primary_is_set_then_lists_primary() {
        // Given
        let actions = POSPageActions(primary: Self.action("email"))

        // When
        let ids = actions.allActions.map(\.id)

        // Then
        #expect(ids == ["email"])
    }

    @Test func test_allActions_when_primary_is_nil_then_lists_secondary() {
        // Given
        let actions = POSPageActions(primary: nil, secondary: [Self.action("email")])

        // When
        let ids = actions.allActions.map(\.id)

        // Then
        #expect(ids == ["email"])
    }
}

private extension POSPageActionsTests {
    static func action(_ id: String) -> POSPageAction {
        POSPageAction(id: id, title: id, accessibilityHint: id, action: {})
    }
}
