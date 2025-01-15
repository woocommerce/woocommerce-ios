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
        let phone = "1-234-456-7890"
        let saveAsDefault = true
        let showCompanyField = true
        let isVerified = true

        let storageManager = MockStorageManager()
        let countries = [Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)

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
                                                        isDefaultAddress: saveAsDefault,
                                                        showCompanyField: showCompanyField,
                                                        isVerified: isVerified,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.id, id)
        XCTAssertEqual(viewModel.name.value, name)
        XCTAssertEqual(viewModel.company.value, company)
        XCTAssertEqual(viewModel.country.value, country)
        XCTAssertEqual(viewModel.address.value, address)
        XCTAssertEqual(viewModel.city.value, city)
        XCTAssertEqual(viewModel.state.value, state)
        XCTAssertEqual(viewModel.postalCode.value, postalCode)
        XCTAssertEqual(viewModel.email.value, email)
        XCTAssertEqual(viewModel.phone.value, phone)
        XCTAssertEqual(viewModel.isDefaultAddress, saveAsDefault)
        XCTAssertEqual(viewModel.showCompanyField, showCompanyField)
        XCTAssertEqual(viewModel.status, .verified)
    }

    func test_origin_address_inits_with_expected_values() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let countries = [Country(code: "US", name: "United States", states: [state]), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)
        let address = WooShippingOriginAddress(id: "default_address",
                                               company: "HEADQUARTERS",
                                               address1: "15 ALGONKIN ST",
                                               address2: "STE 100",
                                               city: "TICONDEROGA",
                                               state: "NY",
                                               postcode: "12883-1487",
                                               country: "US",
                                               phone: "223-456-7890",
                                               firstName: "JANE",
                                               lastName: "DOE",
                                               email: "TEST@EXAMPLE.COM",
                                               defaultAddress: true,
                                               isVerified: false)

        // When
        let viewModel = WooShippingEditAddressViewModel(address: address, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.id, address.id)
        XCTAssertEqual(viewModel.name.value, address.fullName)
        XCTAssertEqual(viewModel.country.value, address.country)
        XCTAssertEqual(viewModel.company.value, address.company)
        XCTAssertEqual(viewModel.address.value, address.combinedAddress)
        XCTAssertEqual(viewModel.city.value, address.city)
        XCTAssertEqual(viewModel.state.value, address.state)
        XCTAssertEqual(viewModel.postalCode.value, address.postcode)
        XCTAssertEqual(viewModel.phone.value, address.phone)
        XCTAssertEqual(viewModel.email.value, address.email)
        XCTAssertTrue(viewModel.isDefaultAddress)
        XCTAssertTrue(viewModel.showCompanyField)
        XCTAssertEqual(viewModel.status, .unverified)
        XCTAssertTrue(viewModel.showSaveAsDefault)
        XCTAssertEqual(viewModel.countries.count, 1, "Should only include USPS-supported countries for origin addresses")
    }

    func test_it_validates_address_with_missing_information_and_sets_expected_status_on_init() {
        // Given & When
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        phoneNumberRequired: true)

        // Then
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    func test_expected_fields_are_required() {
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        stores: stores,
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.name.required, true)
        XCTAssertEqual(viewModel.company.required, true)
        XCTAssertEqual(viewModel.country.required, true)
        XCTAssertEqual(viewModel.address.required, true)
        XCTAssertEqual(viewModel.city.required, true)
        XCTAssertEqual(viewModel.state.required, false)
        XCTAssertEqual(viewModel.postalCode.required, true)
        XCTAssertEqual(viewModel.email.required, true)
        XCTAssertEqual(viewModel.phone.required, true)
    }

    func test_company_not_required_when_name_is_not_empty() {
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // Then
        XCTAssertFalse(viewModel.company.required)
    }

    func test_name_not_required_when_company_is_not_empty() {
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // Then
        XCTAssertFalse(viewModel.name.required)
    }

    func test_phone_number_not_required_when_phoneNumberRequired_set_to_false() {
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: false)

        // Then
        XCTAssertFalse(viewModel.phone.required)
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
                                                        isDefaultAddress: true,
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
                                                        isDefaultAddress: true,
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        stores: stores,
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.countries.count, 1)
        XCTAssertTrue(stores.receivedActions.first is DataAction)
    }

    func test_state_required_when_selected_country_contains_states() {
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // Then
        XCTAssertTrue(viewModel.state.required)
    }

    func test_selected_country_and_state_properies_set_when_address_contains_country_and_state_in_countries() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let country = Country(code: "US", name: "United States", states: [state])
        storageManager.insertSampleCountries(readOnlyCountries: [country])

        // When
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: country.code,
                                                        address: "",
                                                        city: "",
                                                        state: state.code,
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedCountry, country)
        XCTAssertEqual(viewModel.selectedState, state)
        XCTAssertEqual(viewModel.country.value, country.code)
        XCTAssertEqual(viewModel.state.value, state.code)
    }

    func test_selectedState_cleared_when_new_country_is_selected() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let country = Country(code: "US", name: "United States", states: [state])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: country.code,
                                                        address: "",
                                                        city: "",
                                                        state: state.code,
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        let countrySelectorCommand = viewModel.countrySelectorVM.command
        let viewController = ListSelectorViewController(command: countrySelectorCommand, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countrySelectorCommand.handleSelectedChange(selected: Country.fake(), viewController: viewController)

        // Then
        XCTAssertNil(viewModel.selectedState)
    }

    func test_selectedState_not_cleared_when_same_country_is_selected() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let country = Country(code: "US", name: "United States", states: [state])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: country.code,
                                                        address: "",
                                                        city: "",
                                                        state: state.code,
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        let countrySelectorCommand = viewModel.countrySelectorVM.command
        let viewController = ListSelectorViewController(command: countrySelectorCommand, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countrySelectorCommand.handleSelectedChange(selected: country, viewController: viewController)

        // Then
        XCTAssertNotNil(viewModel.selectedState)
    }

    func test_validateAddress_sets_expected_properties_when_all_fields_valid() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "HEADQUARTERS",
                                                        country: "US",
                                                        address: "15 ALGONKIN ST STE 100",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "TEST@EXAMPLE.COM",
                                                        phone: "1-234-456-7890",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        viewModel.validateAddress()

        // Then
        XCTAssertTrue(viewModel.invalidFields.isEmpty)
        XCTAssertEqual(viewModel.status, .verified)
    }

    func test_validateAddress_sets_expected_properties_when_all_fields_empty() {
        // Given
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true)

        // When
        viewModel.validateAddress()

        // Then
        // Note that empty state is valid when country is empty (has no states).
        let expectedInvalidFieldTypes = WooShippingAddressFieldType.allCases.filter { $0 != .state }
        XCTAssertEqual(viewModel.invalidFields.map { $0.type }, expectedInvalidFieldTypes)
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    func test_validate_sets_expected_properties_when_all_fields_valid() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "HEADQUARTERS",
                                                        country: "US",
                                                        address: "15 ALGONKIN ST STE 100",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "TEST@EXAMPLE.COM",
                                                        phone: "1-234-456-7890",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        for field in WooShippingAddressFieldType.allCases {
            viewModel.validate(field)
        }

        // Then
        XCTAssertTrue(viewModel.invalidFields.isEmpty)
        XCTAssertEqual(viewModel.status, .verified)
    }

    func test_validate_sets_expected_properties_when_all_fields_empty() {
        // Given
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true)

        // When
        for field in WooShippingAddressFieldType.allCases {
            viewModel.validate(field)
        }

        // Then
        // Note that empty state is valid when country is empty (has no states).
        let expectedInvalidFields = WooShippingAddressFieldType.allCases.filter { $0 != .state }
        XCTAssertEqual(viewModel.invalidFields.map { $0.type }, expectedInvalidFields)
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    func test_validate_sets_state_as_invalid_field_when_empty_and_country_contains_states() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [.fake()])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "US",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        viewModel.validate(.state)

        // Then
        XCTAssertTrue(viewModel.invalidFields.map { $0.type }.contains(.state))
    }

    func test_validate_sets_phone_as_invalid_field_when_invalid_for_US() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "US",
                                                        address: "",
                                                        city: "",
                                                        state: "",
                                                        postalCode: "",
                                                        email: "",
                                                        phone: "123-4567",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true,
                                                        storageManager: storageManager)

        // When
        viewModel.validate(.phone)

        // Then
        XCTAssertTrue(viewModel.invalidFields.map { $0.type }.contains(.phone))
    }

    func test_validate_removes_valid_field_from_invalidFields() {
        // Given
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
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        phoneNumberRequired: true)
        // Precondition check
        viewModel.validate(.name)
        XCTAssertTrue(viewModel.invalidFields.map { $0.type }.contains(.name))

        // When
        viewModel.name.value = "JANE DOE"
        viewModel.validate(.name)

        // Then
        XCTAssertFalse(viewModel.invalidFields.map { $0.type }.contains(.name))
    }
}
