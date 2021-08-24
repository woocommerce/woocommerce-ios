import XCTest
import TestKit

@testable import WooCommerce

class EditCustomerNoteViewModelTests: XCTestCase {

    func test_done_button_is_disabled_when_note_content_is_the_same() {
        // Given
        let viewModel = EditCustomerNoteViewModel(originalNote: "Original")

        // When
        let navigationItem = viewModel.navigationTrailingItem

        // Then
        assertEqual(navigationItem, .done(enabled: false))
    }

    func test_done_button_is_enabled_when_note_content_is_the_different() {
        // Given
        let viewModel = EditCustomerNoteViewModel(originalNote: "Original")

        // When
        viewModel.newNote = "Edited"

        // Then
        assertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_loading_indicator_gets_enabled_during_network_request() {
        // Given
        let viewModel = EditCustomerNoteViewModel(originalNote: "Original")

        // When
        viewModel.updateNote {}

        // Then
        assertEqual(viewModel.navigationTrailingItem, .loading)
    }

    func test_loading_indicator_gets_disabled_after_the_network_operation_completes() {
        // Given
        let viewModel = EditCustomerNoteViewModel(originalNote: "Original")

        // When
        let navigationItem = waitFor { promise in
            viewModel.updateNote(onFinish: {
                promise(viewModel.navigationTrailingItem)
            })
        }

        // Then
        assertEqual(navigationItem, .done(enabled: false))
    }
}
