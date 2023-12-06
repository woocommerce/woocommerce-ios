import XCTest
@testable import WooCommerce

class OtherPaymentMethodsViewModelTests: XCTestCase {
    func test_note_text_on_initialization_then_shows_placeholder() {
        let viewModel = OtherPaymentMethodsViewModel(formattedTotal: "100.00", onMarkOrderAsComplete: { _ in })

        XCTAssertEqual(viewModel.noteText, Localization.noteTextPlaceholder)
    }

    func test_onMarkOrderAsCompleteTapped_when_there_is_a_note_then_passes_the_note() {

        var capturedNote: String?
        let viewModel = OtherPaymentMethodsViewModel(formattedTotal: "100.00", onMarkOrderAsComplete: { note in
            capturedNote = note
        })

        viewModel.noteText = "TestNote"
        viewModel.onMarkOrderAsCompleteTapped()

        XCTAssertEqual(capturedNote, viewModel.noteText)
    }

    func test_onMarkOrderAsCompleteTapped_when_note_is_empty_then_passes_nil() {

        var capturedNote: String?
        let viewModel = OtherPaymentMethodsViewModel(formattedTotal: "100.00", onMarkOrderAsComplete: { note in
            capturedNote = note
        })

        viewModel.noteText = ""
        viewModel.onMarkOrderAsCompleteTapped()

        XCTAssertNil(capturedNote)
    }

    func test_onMarkOrderAsCompleteTapped_when_note_does_not_change_then_passes_nil() {
        var capturedNote: String?
        let viewModel = OtherPaymentMethodsViewModel(formattedTotal: "100.00", onMarkOrderAsComplete: { note in
            capturedNote = note
        })

        viewModel.onMarkOrderAsCompleteTapped()

        XCTAssertNil(capturedNote)
    }
}

extension OtherPaymentMethodsViewModelTests {
    enum Localization {
        static let noteTextPlaceholder = NSLocalizedString("otherPaymentMethodsViewModel.note.placeholder",
                                                           value: "Enter optional note",
                                                           comment: "Placeholder for the text editor when adding a note in the payment methods view.")
    }
}
