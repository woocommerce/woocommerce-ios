import XCTest
@testable import WooCommerce
import Yosemite

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
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: id,
                                                        name: name,
                                                        company: company,
                                                        country: country,
                                                        address: address,
                                                        city: city,
                                                        state: state,
                                                        postalCode: postalCode,
                                                        email: email,
                                                        phone: phone,
                                                        isDefault: saveAsDefault,
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
        XCTAssertEqual(viewModel.isDefault, saveAsDefault)
        XCTAssertEqual(viewModel.showCompanyField, showCompanyField)
        XCTAssertEqual(viewModel.status, .verified)
    }

    func test_origin_address_inits_with_expected_values() {
        // Given
        let storageManager = MockStorageManager()
        let countries = [Country(code: "US", name: "United States", states: []), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)
        let address = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "123-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: true)

        // When
        let viewModel = WooShippingEditAddressViewModel(address: address, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.id, address.id)
        XCTAssertEqual(viewModel.name, address.fullName)
        XCTAssertEqual(viewModel.country, address.country)
        XCTAssertEqual(viewModel.company, address.company)
        XCTAssertEqual(viewModel.address, address.combinedAddress)
        XCTAssertEqual(viewModel.city, address.city)
        XCTAssertEqual(viewModel.state, address.state)
        XCTAssertEqual(viewModel.postalCode, address.postcode)
        XCTAssertEqual(viewModel.phone, address.phone)
        XCTAssertEqual(viewModel.email, address.email)
        XCTAssertTrue(viewModel.isDefault)
        XCTAssertTrue(viewModel.showCompanyField)
        XCTAssertEqual(viewModel.status, .verified)
        XCTAssertTrue(viewModel.showSaveAsDefault)
        XCTAssertEqual(viewModel.countries.count, 1, "Should only include USPS-supported countries for origin addresses")
    }

    func test_isRequired_returns_expected_values() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        stores: stores,
                                                        storageManager: storageManager)

        // When
        var requirements: [WooShippingEditAddressView.AddressField: Bool] = [:]
        for field in WooShippingEditAddressView.AddressField.allCases {
            requirements[field] = viewModel.isRequired(field)
        }

        // Then
        XCTAssertEqual(requirements[.name], true)
        XCTAssertEqual(requirements[.company], true)
        XCTAssertEqual(requirements[.country], true)
        XCTAssertEqual(requirements[.address], true)
        XCTAssertEqual(requirements[.city], true)
        XCTAssertEqual(requirements[.state], false)
        XCTAssertEqual(requirements[.postalCode], true)
        XCTAssertEqual(requirements[.email], true)
        XCTAssertEqual(requirements[.phone], true)
    }

    func test_isRequired_returns_false_for_company_when_name_is_not_empty() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // When
        let isCompanyRequired = viewModel.isRequired(.company)

        // Then
        XCTAssertFalse(isCompanyRequired)
    }

    func test_isRequired_returns_false_for_name_when_company_is_not_empty() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: "",
                                                        name: "",
                                                        company: "HEADQUARTERS",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // When
        let isNameRequired = viewModel.isRequired(.name)

        // Then
        XCTAssertFalse(isNameRequired)
    }

    func test_isRequired_returns_false_when_phone_number_not_required() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // When
        let isPhoneRequired = viewModel.isRequired(.phone)

        // Then
        XCTAssertFalse(isPhoneRequired)
    }

    func test_it_inits_with_expected_values_for_origin_address_type() {
        // Given
        let storageManager = MockStorageManager()
        let countries = [Country(code: "US", name: "United States", states: []), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

        // When
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.showSaveAsDefault)
        XCTAssertEqual(viewModel.countries.count, 1, "Should only include USPS-supported countries for origin addresses")
    }

    func test_it_inits_with_expected_values_for_destination_address_type() {
        // Given
        let storageManager = MockStorageManager()
        let countries = [Country(code: "US", name: "United States", states: []), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

        // When
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // Then
        XCTAssertFalse(viewModel.showSaveAsDefault)
        XCTAssertEqual(viewModel.countries.count, 2, "Should include all countries for destination addresses")
    }

    func test_init_fetches_countries_from_remote() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [])
        stores.whenReceivingAction(ofType: DataAction.self) { action in
            switch action {
            case .synchronizeCountries(_, let completion):
                storageManager.insertSampleCountries(readOnlyCountries: [country])
                completion(.success([country]))
            }
        }

        // When
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        stores: stores,
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.countries.count, 1)
        XCTAssertTrue(stores.receivedActions.first is DataAction)
    }

    func test_isRequired_returns_true_when_selected_country_contains_states() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [.init(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: country.code,
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefault: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        let isStateRequired = viewModel.isRequired(.state)

        // Then
        XCTAssertTrue(isStateRequired)
    }
}
