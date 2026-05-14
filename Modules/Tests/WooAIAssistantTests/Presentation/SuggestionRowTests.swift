import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct SuggestionRowTests {

    @Test
    func test_SuggestionRow_when_tapped_then_picks_expanded_prompt_not_title() {
        // Given
        var picked: String?
        let item = EmptyStateView.SuggestionItem(
            symbol: "chart.bar",
            title: "How's revenue this week?",
            prompt: "How's my revenue this week? Show me total sales for this week and how it compares to last week."
        )
        let row = SuggestionRow(item: item, symbolWidth: 20, onPick: { picked = $0 })

        // When
        row.handleTap()

        // Then
        #expect(picked == item.prompt)
        #expect(picked != item.title)
    }
}
