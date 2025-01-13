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
                                                        isVerified: isVerified,
                                                        phoneNumberRequired: true)

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

    func test_isRequired_returns_expected_values() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        saveAsDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true)

        // When
        var requirements: [WooShippingEditAddressView.AddressField: Bool] = [:]
        for field in WooShippingEditAddressView.AddressField.allCases {
            requirements[field] = viewModel.isRequired(field)
        }

        // Then
        XCTAssertEqual(requirements[.name], true)
        XCTAssertEqual(requirements[.company], false)
        XCTAssertEqual(requirements[.country], true)
        XCTAssertEqual(requirements[.address], true)
        XCTAssertEqual(requirements[.city], true)
        XCTAssertEqual(requirements[.state], true)
        XCTAssertEqual(requirements[.postalCode], true)
        XCTAssertEqual(requirements[.email], true)
        XCTAssertEqual(requirements[.phone], true)
    }

    func test_isRequired_returns_false_when_phone_number_not_required() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        saveAsDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // When
        let isPhoneRequired = viewModel.isRequired(.phone)

        // Then
        XCTAssertFalse(isPhoneRequired)
    }

}
