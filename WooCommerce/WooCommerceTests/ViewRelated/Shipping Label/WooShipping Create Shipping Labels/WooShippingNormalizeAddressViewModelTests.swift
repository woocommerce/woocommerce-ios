import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingNormalizeAddressViewModelTests: XCTestCase {

    func test_it_inits_with_expected_values() {
        // Given
        let enteredAddress = WooShippingNormalizeAddressViewModel.sampleEnteredAddress
        let suggestedAddress = WooShippingNormalizeAddressViewModel.sampleSuggestedAddress

        // When
        let viewModel = WooShippingNormalizeAddressViewModel(enteredAddress: enteredAddress, suggestedAddress: suggestedAddress)

        // Then
        XCTAssertEqual(viewModel.enteredAddress, enteredAddress)
        XCTAssertEqual(viewModel.suggestedAddress, suggestedAddress)
        XCTAssertEqual(viewModel.selectedAddress, .suggested)
    }

}
