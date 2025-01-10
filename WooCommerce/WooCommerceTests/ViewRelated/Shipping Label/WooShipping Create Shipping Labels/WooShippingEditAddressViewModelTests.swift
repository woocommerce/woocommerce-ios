import XCTest
@testable import WooCommerce

final class WooShippingEditAddressViewModelTests: XCTestCase {

    func test_it_inits_with_expected_values() {
        // Given
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

        // When
        let viewModel = WooShippingEditAddressViewModel(name: name,
                                                        company: company,
                                                        country: country,
                                                        address: address,
                                                        city: city,
                                                        state: state,
                                                        postalCode: postalCode,
                                                        email: email,
                                                        phone: phone,
                                                        saveAsDefault: saveAsDefault,
                                                        showCompanyField: showCompanyField)

        // Then
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
    }

}
