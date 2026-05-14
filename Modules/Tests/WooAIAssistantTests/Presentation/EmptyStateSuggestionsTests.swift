import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct EmptyStateSuggestionsTests {

    @Test
    func test_defaultSuggestions_when_inspected_then_has_four_distinct_nonempty_prompts() {
        // Given
        let suggestions = EmptyStateView.defaultSuggestions

        // When
        let prompts = suggestions.map { $0.prompt }

        // Then
        #expect(suggestions.count == 4)
        #expect(prompts.allSatisfy { !$0.isEmpty })
        #expect(suggestions.allSatisfy { $0.prompt != $0.title })
    }
}
