import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingOriginAddressListViewModelTests: XCTestCase {

    func test_it_inits_with_expected_addresses() {
        // Given
        let selectedAddressID = "1"
        let addresses = [WooShippingLabelAddress.fake().copy(id: selectedAddressID), WooShippingLabelAddress.fake()]

        // When
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: selectedAddressID)

        // Then
        XCTAssertEqual(viewModel.addresses, addresses)
        XCTAssertEqual(viewModel.selectedAddressID, selectedAddressID)
        XCTAssertNil(viewModel.addressToEdit)
    }

    func test_isSelected_returns_expected_value_for_selected_address() {
        // Given
        let selectedAddress = WooShippingLabelAddress.fake().copy(id: "1")
        let addresses = [selectedAddress, WooShippingLabelAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: selectedAddress.id)

        // When
        let isSelected = viewModel.isSelected(selectedAddress)

        // Then
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_returns_expected_value_for_unselected_address() {
        // Given
        let unselectedAddress = WooShippingLabelAddress.fake().copy(id: "1")
        let addresses = [unselectedAddress, WooShippingLabelAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: nil)

        // When
        let isSelected = viewModel.isSelected(unselectedAddress)

        // Then
        XCTAssertFalse(isSelected)
    }

    func test_select_sets_selectedAddressID() {
        // Given
        let addressToSelect = WooShippingLabelAddress.fake().copy(id: "1")
        let addresses = [addressToSelect, WooShippingLabelAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: nil)

        // When
        viewModel.select(addressToSelect)

        // Then
        XCTAssertEqual(viewModel.selectedAddressID, addressToSelect.id)
    }

    func test_select_calls_onSelect_closure() {
        // Given
        let addressToSelect = WooShippingLabelAddress.fake().copy(id: "1")
        let addresses = [addressToSelect, WooShippingLabelAddress.fake().copy(id: "2")]
        let viewModel = WooShippingOriginAddressListViewModel(addresses: addresses, selectedAddressID: nil)

        // When
        let selectedAddress = waitFor { promise in
            viewModel.onSelect = { address in
                promise(address)
            }
            viewModel.select(addressToSelect)
        }

        // Then
        XCTAssertEqual(selectedAddress, addressToSelect)
    }

    func test_editAddress_sets_addressToEdit_view_model() throws {
        // Given
        let addressToEdit = WooShippingLabelAddress.fake()
        let viewModel = WooShippingOriginAddressListViewModel(addresses: [addressToEdit])

        // When
        viewModel.editAddress(addressToEdit)

        // Then
        let addressToEditViewModel = try XCTUnwrap(viewModel.addressToEdit, "addressToEdit was unexpectedly nil")
    }

}
