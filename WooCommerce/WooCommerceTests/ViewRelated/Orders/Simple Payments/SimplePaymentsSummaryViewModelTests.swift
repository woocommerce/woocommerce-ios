import Foundation
import XCTest
import Combine

@testable import WooCommerce

final class SimplePaymentsSummaryViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func test_updating_noteViewModel_updates_noteContent_property() {
        // Given
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "$100.0")

        // When
        viewModel.noteViewModel.newNote = "Updated note"

        // Then
        assertEqual(viewModel.noteContent, viewModel.noteViewModel.newNote)
    }

    func test_calling_reloadContent_triggers_viewModel_update() {
        // Given
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "$100.0")

        // When
        let triggeredUpdate: Bool = waitFor { promise in
            viewModel.objectWillChange.sink {
                promise(true)
            }
            .store(in: &self.subscriptions)

            viewModel.reloadContent()
        }

        // Then
        XCTAssertTrue(triggeredUpdate)
    }
}
