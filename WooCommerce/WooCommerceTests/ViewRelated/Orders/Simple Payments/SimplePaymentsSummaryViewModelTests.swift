import Foundation
import XCTest
import Combine

@testable import WooCommerce

final class SimplePaymentsSummaryViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func test_updating_noteViewModel_updates_noteContent_property() {
        // Given
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "$100.00", totalWithTaxes: "$104.30")

        // When
        viewModel.noteViewModel.newNote = "Updated note"

        // Then
        assertEqual(viewModel.noteContent, viewModel.noteViewModel.newNote)
    }

    func test_calling_reloadContent_triggers_viewModel_update() {
        // Given
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "$100.00", totalWithTaxes: "$104.30")

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

    func test_provided_amount_gets_properly_formatted() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "100", totalWithTaxes: "104.30", currencyFormatter: currencyFormatter)

        // When & Then
        XCTAssertEqual(viewModel.providedAmount, "$100.00")
        XCTAssertEqual(viewModel.total, "$100.00")
    }

    func test_provided_amount_with_taxes_gets_properly_formatted() {
        // Given
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US.
        let viewModel = SimplePaymentsSummaryViewModel(providedAmount: "100", totalWithTaxes: "104.30", currencyFormatter: currencyFormatter)

        // When
        viewModel.enableTaxes = true

        // Then
        XCTAssertEqual(viewModel.providedAmount, "$100.00")
        XCTAssertEqual(viewModel.total, "$104.30")
    }
}
