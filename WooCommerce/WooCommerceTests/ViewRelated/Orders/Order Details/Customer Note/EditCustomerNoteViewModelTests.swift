import XCTest
import TestKit

@testable import WooCommerce

class EditCustomerNoteViewModelTests: XCTestCase {

    func test_done_button_is_disabled_when_note_content_is_the_same() {
        // Given
        let viewModel = EditCustomerNoteViewModel(originalNote: "Original", newNote: "Original")

        // When
        let doneButtonEnabled = viewModel.doneEnabled

        // Then
        XCTAssertFalse(doneButtonEnabled)
    }

    func test_done_button_is_enabled_when_note_content_is_the_different() {
        // Given
        let viewModel = EditCustomerNoteViewModel(originalNote: "Original", newNote: "New")

        // When
        let doneButtonEnabled = viewModel.doneEnabled

        // Then
        XCTAssertTrue(doneButtonEnabled)
    }
}
