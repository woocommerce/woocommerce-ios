import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingNormalizeAddressViewModelTests: XCTestCase {
    func test_it_inits_with_expected_values() {
        // Given
        let enteredAddress = WooShippingNormalizeAddressViewModel.sampleEnteredAddress
        let suggestedAddress = WooShippingNormalizeAddressViewModel.sampleSuggestedAddress

        // When
        let viewModel = WooShippingNormalizeAddressViewModel(enteredAddress: enteredAddress, suggestedAddress: suggestedAddress, onConfirm: { _ in })

        // Then
        XCTAssertEqual(viewModel.enteredAddress, enteredAddress)
        XCTAssertEqual(viewModel.suggestedAddress, suggestedAddress)
        XCTAssertEqual(viewModel.selectedAddress, .suggested)
    }

    func test_confirmSelectedAddress_calls_onConfirm_with_expected_address() {
        // Given
        let enteredAddress = WooShippingNormalizeAddressViewModel.sampleEnteredAddress
        let suggestedAddress = WooShippingNormalizeAddressViewModel.sampleSuggestedAddress
        var confirmedAddress: WooShippingAddress?
        let viewModel = WooShippingNormalizeAddressViewModel(enteredAddress: enteredAddress, suggestedAddress: suggestedAddress, onConfirm: { address in
            confirmedAddress = address
        })

        // When
        viewModel.selectedAddress = .entered
        viewModel.confirmSelectedAddress()

        // Then
        XCTAssertEqual(confirmedAddress, enteredAddress)
    }
}
