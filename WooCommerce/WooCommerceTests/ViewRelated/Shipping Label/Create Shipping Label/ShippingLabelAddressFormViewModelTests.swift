import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelAddressFormViewModelTests: XCTestCase {

    func test_handleAddressValueChanges_returns_updated_ShippingLabelAddress() {

        // Given
        let shippingAddress = ShippingLabelAddress(company: "",
                                                   name: "",
                                                   phone: "",
                                                   country: "",
                                                   state: "",
                                                   address1: "",
                                                   address2: "",
                                                   city: "",
                                                   postcode: "")

        let viewModel = ShippingLabelAddressFormViewModel(type: .origin, address: shippingAddress)

        // When
        viewModel.handleAddressValueChanges(row: .name, newValue: "Skylar Ferry")
        viewModel.handleAddressValueChanges(row: .company, newValue: "Automattic Inc.")
        viewModel.handleAddressValueChanges(row: .phone, newValue: "12345")
        viewModel.handleAddressValueChanges(row: .country, newValue: "United States")
        viewModel.handleAddressValueChanges(row: .state, newValue: "CA")
        viewModel.handleAddressValueChanges(row: .address, newValue: "60 29th")
        viewModel.handleAddressValueChanges(row: .address2, newValue: "Street #343")
        viewModel.handleAddressValueChanges(row: .city, newValue: "San Francisco")
        viewModel.handleAddressValueChanges(row: .postcode, newValue: "94121-2303")

        // Then
        XCTAssertEqual(viewModel.address?.name, "Skylar Ferry")
        XCTAssertEqual(viewModel.address?.company, "Automattic Inc.")
        XCTAssertEqual(viewModel.address?.phone, "12345")
        XCTAssertEqual(viewModel.address?.country, "United States")
        XCTAssertEqual(viewModel.address?.state, "CA")
        XCTAssertEqual(viewModel.address?.address1, "60 29th")
        XCTAssertEqual(viewModel.address?.address2, "Street #343")
        XCTAssertEqual(viewModel.address?.city, "San Francisco")
        XCTAssertEqual(viewModel.address?.postcode, "94121-2303")
    }
}
