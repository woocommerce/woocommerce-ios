import XCTest

@testable import WooCommerce

final class SimplePaymentsNoteViewModelTests: XCTestCase {

    func test_viewModel_done_button_starts_disabled() {
        // Given
        let viewModel = SimplePaymentsNoteViewModel(originalNote: "")

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_viewModel_done_buttons_gets_enabled_after_adding_content() {
        // Given
        let viewModel = SimplePaymentsNoteViewModel(originalNote: "")

        // When
        viewModel.newNote = "Content"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_viewModel_starts_non_empty_note_when_provided() {
        // Given
        let viewModel = SimplePaymentsNoteViewModel(originalNote: "content")

        // Then
        XCTAssertEqual(viewModel.newNote, "content")
    }

    func test_viewModel_note_is_reverted_after_canceling_flow() {
        // Given
        let viewModel = SimplePaymentsNoteViewModel(originalNote: "")
        viewModel.newNote = "Content"

        // When
        viewModel.userDidCancelFlow()

        // Then
        XCTAssertEqual(viewModel.newNote, "")
    }
}
