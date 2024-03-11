import XCTest
@testable import WooCommerce

final class AddProductFromImageTextFieldViewModelTests: XCTestCase {
    typealias ViewModel = AddProductFromImageTextFieldView.ViewModel

    // MARK: - `onSuggestion`

    func test_onSuggestion_updates_suggestedText_when_text_is_not_empty() {
        // Given
        let viewModel = ViewModel(text: "Asparagus", placeholder: "")
        XCTAssertNil(viewModel.suggestedText)

        // When
        viewModel.onSuggestion("Mushroom")

        // Then
        XCTAssertEqual(viewModel.suggestedText, "Mushroom")
    }

    func test_onSuggestion_updates_text_when_text_is_empty() {
        // Given
        let viewModel = ViewModel(text: "", placeholder: "")

        // When
        viewModel.onSuggestion("Mushroom")

        // Then
        XCTAssertEqual(viewModel.text, "Mushroom")
        XCTAssertNil(viewModel.suggestedText)
    }

    func test_onSuggestion_does_not_update_suggestedText_when_suggestion_is_the_same_as_text() {
        // Given
        let viewModel = ViewModel(text: "Asparagus", placeholder: "")
        XCTAssertNil(viewModel.suggestedText)

        // When
        viewModel.onSuggestion("Asparagus")

        // Then
        XCTAssertNil(viewModel.suggestedText)
    }

    func test_onSuggestion_resets_suggestedText_when_suggestion_is_empty() {
        // Given
        let viewModel = ViewModel(text: "", placeholder: "")
        XCTAssertNil(viewModel.suggestedText)

        // When
        viewModel.onSuggestion("Asparagus")
        viewModel.onSuggestion("")

        // Then
        XCTAssertNil(viewModel.suggestedText)
    }

    // MARK: - `applySuggestedText`

    func test_applySuggestedText_replaces_text_with_suggestedText_and_resets_suggestedText() {
        // Given
        let viewModel = ViewModel(text: "Fish", placeholder: "")

        // When
        viewModel.onSuggestion("Asparagus")
        viewModel.applySuggestedText()

        // Then
        XCTAssertEqual(viewModel.text, "Asparagus")
        XCTAssertNil(viewModel.suggestedText)
    }

    // MARK: - `dismissSuggestedText`

    func test_dismissSuggestedText_resets_suggestedText_and_does_not_change_text() {
        // Given
        let viewModel = ViewModel(text: "Fish", placeholder: "")

        // When
        viewModel.onSuggestion("Asparagus")
        viewModel.dismissSuggestedText()

        // Then
        XCTAssertEqual(viewModel.text, "Fish")
        XCTAssertNil(viewModel.suggestedText)
    }

    // MARK: `hasAppliedGeneratedContent`

    func test_hasAppliedGeneratedContent_is_false_by_default() {
        // Given
        let viewModel = ViewModel(text: "Fish", placeholder: "")

        // Then
        XCTAssertFalse(viewModel.hasAppliedGeneratedContent)
    }

    func test_hasAppliedGeneratedContent_is_set_to_true_if_content_is_populated_from_suggestion() {
        // Given
        let viewModel = ViewModel(text: "", placeholder: "")

        // When
        viewModel.onSuggestion("Ramen")

        // Then
        XCTAssertTrue(viewModel.hasAppliedGeneratedContent)
    }

    func test_hasAppliedGeneratedContent_is_not_set_to_true_if_content_is_not_populated_from_suggestion() {
        // Given
        let viewModel = ViewModel(text: "Taco", placeholder: "")

        // When
        viewModel.onSuggestion("Ramen")

        // Then
        XCTAssertFalse(viewModel.hasAppliedGeneratedContent)
    }

    func test_hasAppliedGeneratedContent_is_set_to_true_if_suggestion_is_applied() {
        // Given
        let viewModel = ViewModel(text: "Taco", placeholder: "")

        // When
        viewModel.onSuggestion("Ramen")
        viewModel.applySuggestedText()

        // Then
        XCTAssertTrue(viewModel.hasAppliedGeneratedContent)
    }

    // MARK: `reset()`

    func test_reset_sets_all_properties_to_default_values() {
        // Given
        let viewModel = ViewModel(text: "Taco", placeholder: "")
        viewModel.onSuggestion("Ramen")
        viewModel.applySuggestedText()

        // When
        viewModel.reset()

        // Then
        XCTAssertFalse(viewModel.hasAppliedGeneratedContent)
        XCTAssertEqual(viewModel.text, "")
        XCTAssertNil(viewModel.suggestedText)
    }
}
