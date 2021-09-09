import XCTest
import Yosemite
import TestKit
@testable import WooCommerce

final class EditAddressFormViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123

    func test_creating_with_address_prefills_fields_with_correct_data() {
        // Given
        let address = sampleAddress()
        let viewModel = EditAddressFormViewModel(siteID: sampleSiteID, address: address)

        // Then
        XCTAssertEqual(viewModel.firstName, address.firstName)
        XCTAssertEqual(viewModel.lastName, address.lastName)
        XCTAssertEqual(viewModel.email, address.email ?? "")
        XCTAssertEqual(viewModel.phone, address.phone ?? "")

        XCTAssertEqual(viewModel.company, address.company ?? "")
        XCTAssertEqual(viewModel.address1, address.address1)
        XCTAssertEqual(viewModel.address2, address.address2 ?? "")
        XCTAssertEqual(viewModel.city, address.city)
        XCTAssertEqual(viewModel.postcode, address.postcode)

        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_updating_fields_enables_done_button() {
        // Given
        let address = sampleAddress()
        let viewModel = EditAddressFormViewModel(siteID: sampleSiteID, address: address)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.firstName = "John"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_updating_fields_back_to_original_values_disables_done_button() {
        // Given
        let address = sampleAddress()
        let viewModel = EditAddressFormViewModel(siteID: sampleSiteID, address: address)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.firstName = "John"
        viewModel.lastName = "Ipsum"
        viewModel.firstName = "Johnny"
        viewModel.lastName = "Appleseed"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_creating_without_address_disables_done_button() {
        // Given
        let viewModel = EditAddressFormViewModel(siteID: sampleSiteID, address: nil)

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_creating_with_address_with_empty_nullable_fields_disables_done_button() {
        // Given
        let address = sampleAddressWithEmptyNullableFields()
        let viewModel = EditAddressFormViewModel(siteID: sampleSiteID, address: address)

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }
}

private extension EditAddressFormViewModelTests {
    func sampleAddress() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: nil,
                       address1: "234 70th Street",
                       address2: nil,
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    func sampleAddressWithEmptyNullableFields() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "",
                       email: "")
    }
}
