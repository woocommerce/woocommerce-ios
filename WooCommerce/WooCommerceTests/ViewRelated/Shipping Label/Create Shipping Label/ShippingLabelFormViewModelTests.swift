import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelFormViewModelTests: XCTestCase {

    func test_conversion_from_Address_to_ShippingLabelAddress_returns_correct_data() {

        // Given
        let address = Address(firstName: "Skylar",
                              lastName: "Ferry",
                              company: "Automattic Inc.",
                              address1: "60 29th Street #343",
                              address2: nil,
                              city: "San Francisco",
                              state: "CA",
                              postcode: "94121-2303",
                              country: "United States",
                              phone: nil,
                              email: nil)


        // When
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(siteID: 10, originAddress: address, destinationAddress: nil)

        // Then
        let originAddress = shippingLabelFormViewModel.originAddress

        XCTAssertEqual(originAddress?.company, "Automattic Inc.")
        XCTAssertEqual(originAddress?.name, "Skylar Ferry")
        XCTAssertEqual(originAddress?.phone, "")
        XCTAssertEqual(originAddress?.country, "United States")
        XCTAssertEqual(originAddress?.state, "CA")
        XCTAssertEqual(originAddress?.address1, "60 29th Street #343")
        XCTAssertEqual(originAddress?.address2, "")
        XCTAssertEqual(originAddress?.city, "San Francisco")
        XCTAssertEqual(originAddress?.postcode, "94121-2303")
    }

    func test_handleOriginAddressValueChanges_returns_updated_ShippingLabelAddress() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(siteID: 10, originAddress: nil, destinationAddress: nil)
        let expectedShippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                           name: "Skylar Ferry",
                                                           phone: "12345",
                                                           country: "United States",
                                                           state: "CA",
                                                           address1: "60 29th",
                                                           address2: "Street #343",
                                                           city: "San Francisco",
                                                           postcode: "94121-2303")

        // When
        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.originAddress, expectedShippingAddress)
    }

    func test_handleDestinationAddressValueChanges_returns_updated_ShippingLabelAddress() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(siteID: 10, originAddress: nil, destinationAddress: nil)
        let expectedShippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                           name: "Skylar Ferry",
                                                           phone: "12345",
                                                           country: "United States",
                                                           state: "CA",
                                                           address1: "60 29th",
                                                           address2: "Street #343",
                                                           city: "San Francisco",
                                                           postcode: "94121-2303")

        // When
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.destinationAddress, expectedShippingAddress)
    }
}
