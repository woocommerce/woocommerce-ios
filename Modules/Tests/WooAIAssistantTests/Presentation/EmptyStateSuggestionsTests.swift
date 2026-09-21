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

    @Test
    func test_defaultSuggestions_when_inspected_then_includes_newest_customers_prompt() throws {
        // Given
        let suggestions = EmptyStateView.defaultSuggestions

        // When
        let newCustomersSuggestion = try #require(suggestions.last)

        // Then
        #expect(newCustomersSuggestion.title == "Who are my newest customers?")
        #expect(newCustomersSuggestion.prompt == "Show my newest customers. List up to 10 customers sorted by registration date, newest first.")
    }
}
