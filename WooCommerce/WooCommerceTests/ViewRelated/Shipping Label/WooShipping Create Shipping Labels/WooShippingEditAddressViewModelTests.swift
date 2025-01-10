import XCTest
@testable import WooCommerce

final class WooShippingEditAddressViewModelTests: XCTestCase {

    func test_it_inits_with_expected_values() {
        // Given
        let id = "default_address"
        let name = "JANE DOE"
        let company = "HEADQUARTERS"
        let address = "15 ALGONKIN ST STE 100"
        let city = "TICONDEROGA"
        let state = "NY"
        let postalCode = "12883-1487"
        let country = "US"
        let email = "TEST@EXAMPLE.COM"
        let phone = "123-456-7890"
        let saveAsDefault = true
        let showCompanyField = true
        let isVerified = true

        // When
        let viewModel = WooShippingEditAddressViewModel(id: id,
                                                        name: name,
                                                        company: company,
                                                        country: country,
                                                        address: address,
                                                        city: city,
                                                        state: state,
                                                        postalCode: postalCode,
                                                        email: email,
                                                        phone: phone,
                                                        saveAsDefault: saveAsDefault,
                                                        showCompanyField: showCompanyField,
                                                        isVerified: isVerified)

        // Then
        XCTAssertEqual(viewModel.id, id)
        XCTAssertEqual(viewModel.name, name)
        XCTAssertEqual(viewModel.company, company)
        XCTAssertEqual(viewModel.country, country)
        XCTAssertEqual(viewModel.address, address)
        XCTAssertEqual(viewModel.city, city)
        XCTAssertEqual(viewModel.state, state)
        XCTAssertEqual(viewModel.postalCode, postalCode)
        XCTAssertEqual(viewModel.email, email)
        XCTAssertEqual(viewModel.phone, phone)
        XCTAssertEqual(viewModel.saveAsDefault, saveAsDefault)
        XCTAssertEqual(viewModel.showCompanyField, showCompanyField)
        XCTAssertEqual(viewModel.status, .verified)
    }

}
