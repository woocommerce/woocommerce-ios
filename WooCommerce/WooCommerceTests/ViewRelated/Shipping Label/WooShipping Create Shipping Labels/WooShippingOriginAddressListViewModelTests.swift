import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingOriginAddressListViewModelTests: XCTestCase {

    func test_it_inits_with_expected_addresses() {
        // Given
        let selectedAddressID = "1"
        let addresses = [WooShippingOriginAddress.fake().copy(id: selectedAddressID), WooShippingOriginAddress.fake()]

        // When
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: selectedAddressID)

        // Then
        XCTAssertEqual(viewModel.addresses, addresses)
        XCTAssertEqual(viewModel.selectedAddressID, selectedAddressID)
    }

    func test_it_defaults_to_selecting_default_address() {
        // Given
        let defaultAddress = WooShippingOriginAddress.fake().copy(defaultAddress: true)
        let addresses = [defaultAddress, WooShippingOriginAddress.fake()]

        // When
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: nil)

        // Then
        XCTAssertEqual(viewModel.addresses, addresses)
        XCTAssertEqual(viewModel.selectedAddressID, defaultAddress.id)
    }

    func test_isSelected_returns_expected_value_for_selected_address() {
        // Given
        let selectedAddress = WooShippingOriginAddress.fake().copy(id: "1")
        let addresses = [selectedAddress, WooShippingOriginAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: selectedAddress.id)

        // When
        let isSelected = viewModel.isSelected(selectedAddress)

        // Then
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_returns_expected_value_for_unselected_address() {
        // Given
        let unselectedAddress = WooShippingOriginAddress.fake().copy(id: "1")
        let addresses = [unselectedAddress, WooShippingOriginAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: nil)

        // When
        let isSelected = viewModel.isSelected(unselectedAddress)

        // Then
        XCTAssertFalse(isSelected)
    }

    func test_select_sets_selectedAddressID() {
        // Given
        let addressToSelect = WooShippingOriginAddress.fake().copy(id: "1")
        let addresses = [addressToSelect, WooShippingOriginAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: nil)

        // When
        viewModel.select(addressToSelect)

        // Then
        XCTAssertEqual(viewModel.selectedAddressID, addressToSelect.id)
    }

}
