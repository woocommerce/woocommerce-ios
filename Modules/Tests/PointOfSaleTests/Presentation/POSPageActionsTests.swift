import Testing
@testable import PointOfSale

@MainActor
struct POSPageActionsTests {
    @Test func test_compactLayout_when_there_are_no_actions_then_returns_none() {
        // Given
        let actions = POSPageActions.none

        // When
        let layout = actions.compactLayout

        // Then
        #expect(Self.summary(of: layout) == .none)
    }

    @Test(arguments: [
        (secondaryCount: 0, expected: LayoutSummary.stacked(primary: "primary", secondary: [])),
        (secondaryCount: 1, expected: LayoutSummary.stacked(primary: "primary", secondary: ["secondary-0"])),
        (secondaryCount: 2, expected: LayoutSummary.overflow(primary: "primary", menu: ["secondary-0", "secondary-1"]))
    ])
    func test_compactLayout_when_primary_is_set_then_overflows_above_two_actions(secondaryCount: Int, expected: LayoutSummary) {
        // Given
        let actions = POSPageActions(primary: Self.action("primary"), secondary: Self.secondaryActions(count: secondaryCount))

        // When
        let layout = actions.compactLayout

        // Then
        #expect(Self.summary(of: layout) == expected)
    }

    @Test(arguments: [
        (secondaryCount: 1, expected: LayoutSummary.stacked(primary: nil, secondary: ["secondary-0"])),
        (secondaryCount: 2, expected: LayoutSummary.stacked(primary: nil, secondary: ["secondary-0", "secondary-1"])),
        (secondaryCount: 3, expected: LayoutSummary.overflow(primary: nil, menu: ["secondary-0", "secondary-1", "secondary-2"]))
    ])
    func test_compactLayout_when_primary_is_nil_then_keeps_every_secondary_action(secondaryCount: Int, expected: LayoutSummary) {
        // Given
        let actions = POSPageActions(primary: nil, secondary: Self.secondaryActions(count: secondaryCount))

        // When
        let layout = actions.compactLayout

        // Then
        #expect(Self.summary(of: layout) == expected)
    }
}

extension POSPageActionsTests {
    enum LayoutSummary: Equatable {
        case none
        case stacked(primary: String?, secondary: [String])
        case overflow(primary: String?, menu: [String])
    }

    static func summary(of layout: POSPageActions.CompactLayout) -> LayoutSummary {
        switch layout {
        case .none:
            return .none
        case .stacked(let primary, let secondary):
            return .stacked(primary: primary?.id, secondary: secondary.map(\.id))
        case .overflow(let primary, let menu):
            return .overflow(primary: primary?.id, menu: menu.map(\.id))
        }
    }

    static func action(_ id: String) -> POSPageAction {
        POSPageAction(id: id, title: id, action: {})
    }

    static func secondaryActions(count: Int) -> [POSPageAction] {
        (0..<count).map { action("secondary-\($0)") }
    }
}
