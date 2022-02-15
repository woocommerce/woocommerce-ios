import XCTest
import Yosemite
@testable import WooCommerce

final class InboxNoteRowViewModelTests: XCTestCase {
    // MARK: - `InboxNoteRowViewModel`

    func test_initializing_InboxNoteRowViewModel_with_note_has_expected_properties() throws {
        // Given
        let action = InboxAction.fake().copy(id: 606)
        let note = InboxNote.fake().copy(actions: [action])

        // When
        let viewModel = InboxNoteRowViewModel(note: note)

        // Then
        XCTAssertEqual(viewModel.id, note.id)
        XCTAssertEqual(viewModel.title, note.title)
        XCTAssertEqual(viewModel.attributedContent.string, note.content)

        let actionViewModel = try XCTUnwrap(viewModel.actions.first)
        XCTAssertEqual(actionViewModel.id, action.id)
    }

    // MARK: - `InboxNoteRowActionViewModel`

    func test_initializing_InboxNoteRowActionViewModel_with_action_with_empty_URL_path_has_nil_URL() {
        // When
        let actionViewModel = InboxNoteRowActionViewModel(action: .init(id: 134, name: "wcpay_applepay_holiday2021",
                                                                        label: "Accept Apple Pay",
                                                                        status: "actioned",
                                                                        url: ""))

        // Then
        XCTAssertEqual(actionViewModel, .init(id: 134, title: "Accept Apple Pay", url: nil))
        XCTAssertNil(actionViewModel.url)
    }

    func test_initializing_InboxNoteRowActionViewModel_with_action_has_expected_properties() {
        // When
        let actionViewModel = InboxNoteRowActionViewModel(action: .init(id: 134, name: "wcpay_applepay_holiday2021",
                                                                        label: "Accept Apple Pay",
                                                                        status: "actioned",
                                                                        url: "https://woocommerce.com"))

        // Then
        XCTAssertEqual(actionViewModel, .init(id: 134, title: "Accept Apple Pay", url: .init(string: "https://woocommerce.com")))
        XCTAssertEqual(actionViewModel.id, 134)
        XCTAssertEqual(actionViewModel.title, "Accept Apple Pay")
        XCTAssertEqual(actionViewModel.url?.absoluteString, "https://woocommerce.com")
    }
}
