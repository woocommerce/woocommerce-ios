import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingEditAddressViewModelTests: XCTestCase {

    private let sampleOrderID: Int64 = 123

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
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.normalizeAddressVM)
    }

    func test_origin_address_inits_with_expected_values() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let countries = [Country(code: "US", name: "United States", states: [state]), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)
        let address = WooShippingOriginAddress(siteID: 123,
                                               id: "default_address",
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

    func test_destination_address_inits_with_expected_values() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let countries = [Country(code: "US", name: "United States", states: [state]), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)
        let email = "TEST@EXAMPLE.COM"
        let address = WooShippingAddress(company: "HEADQUARTERS",
                                         name: "JANE DOE",
                                         email: email,
                                         phone: "223-456-7890",
                                         country: "US",
                                         state: "NY",
                                         address1: "15 ALGONKIN ST",
                                         address2: "STE 100",
                                         city: "TICONDEROGA",
                                         postcode: "12883-1487")

        // When
        let viewModel = WooShippingEditAddressViewModel(address: address,
                                                        orderID: sampleOrderID,
                                                        email: email,
                                                        isVerified: false,
                                                        originCountryCode: "US",
                                                        originStateCode: "CA",
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.name.value, address.name)
        XCTAssertEqual(viewModel.country.value, address.country)
        XCTAssertEqual(viewModel.company.value, address.company)
        XCTAssertEqual(viewModel.address.value, address.combinedAddress)
        XCTAssertEqual(viewModel.city.value, address.city)
        XCTAssertEqual(viewModel.state.value, address.state)
        XCTAssertEqual(viewModel.postalCode.value, address.postcode)
        XCTAssertEqual(viewModel.phone.value, address.phone)
        XCTAssertEqual(viewModel.email.value, email)
        XCTAssertTrue(viewModel.showCompanyField)
        XCTAssertEqual(viewModel.status, .unverified)
        XCTAssertFalse(viewModel.showSaveAsDefault)
        XCTAssertEqual(viewModel.countries.count, 2, "Should include all countries for destination addresses")
    }

    func test_it_validates_address_with_missing_information_and_sets_expected_status_on_init() {
        // Given & When
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        isVerified: false)

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
                                                        isVerified: true)

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
                                                        isVerified: true)

        // Then
        XCTAssertFalse(viewModel.name.required)
    }

    func test_phone_number_required_for_origin_address() {
        // Given
        let address = WooShippingOriginAddress.fake()

        // When
        let viewModel = WooShippingEditAddressViewModel(address: address)

        // Then
        XCTAssertTrue(viewModel.phone.required)
    }

    func test_phone_number_required_for_destination_address() {
        // Given
        let address = WooShippingAddress(company: "HEADQUARTERS",
                                         name: "JANE DOE",
                                         email: "",
                                         phone: "223-456-7890",
                                         country: "US",
                                         state: "NY",
                                         address1: "15 ALGONKIN ST",
                                         address2: "STE 100",
                                         city: "TICONDEROGA",
                                         postcode: "12883-1487")

        // When
        let viewModel = WooShippingEditAddressViewModel(address: address,
                                                        orderID: sampleOrderID,
                                                        email: "",
                                                        isVerified: false,
                                                        originCountryCode: address.country,
                                                        originStateCode: "CA")

        // Then
        XCTAssertTrue(viewModel.phone.required)
    }

    func test_phone_number_required_for_destination_address_when_customs_form_required() {
        // Given
        let address = WooShippingAddress(company: "HEADQUARTERS",
                                         name: "JANE DOE",
                                         email: "",
                                         phone: "223-456-7890",
                                         country: "US",
                                         state: "NY",
                                         address1: "15 ALGONKIN ST",
                                         address2: "STE 100",
                                         city: "TICONDEROGA",
                                         postcode: "12883-1487")

        // When
        let viewModel = WooShippingEditAddressViewModel(address: address,
                                                        orderID: sampleOrderID,
                                                        email: "",
                                                        isVerified: false,
                                                        originCountryCode: "CA",
                                                        originStateCode: "BC")

        // Then
        XCTAssertTrue(viewModel.phone.required)
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
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager)

        // Then
        XCTAssertFalse(viewModel.showSaveAsDefault)
        XCTAssertEqual(viewModel.countries.count, 2, "Should include all countries for destination addresses")
    }

    func test_init_fetches_countries_from_storage() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [])
        storageManager.insertSampleCountries(readOnlyCountries: [country])

        // When
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.countries.count, 1)
    }

    func test_state_required_when_selected_country_contains_states() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [.init(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager)

        // When
        let countrySelectorCommand = viewModel.countrySelectorVM.command
        let viewController = ListSelectorViewController(command: countrySelectorCommand, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countrySelectorCommand.handleSelectedChange(selected: country, viewController: viewController)

        // Then
        XCTAssertNotNil(viewModel.selectedState)
    }

    func test_validateAddress_sets_expected_status_when_all_fields_valid() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager)

        // When
        viewModel.validateAddress()

        // Then
        XCTAssertTrue(viewModel.invalidFieldTypes.isEmpty)
        XCTAssertEqual(viewModel.status, .verified)
    }

    func test_validateAddress_sets_expected_properties_when_all_fields_empty() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        debounceDelayInSeconds: 0)

        // When
        viewModel.validateAddress()

        // Then
        // Note that empty state is valid when country is empty (has no states).
        let expectedInvalidFieldTypes = viewModel.allFields.filter { $0.type != .state }.map { $0.type }
        XCTAssertEqual(viewModel.invalidFieldTypes, expectedInvalidFieldTypes)
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    func test_validate_sets_expected_status_when_all_fields_valid() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager,
                                                        debounceDelayInSeconds: 0)

        // When
        for field in WooShippingAddressFieldType.allCases {
            viewModel.validate(field)
        }

        // Then
        XCTAssertTrue(viewModel.invalidFieldTypes.isEmpty)
        XCTAssertEqual(viewModel.status, .verified)
    }

    func test_validate_sets_expected_properties_when_all_fields_empty() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        debounceDelayInSeconds: 0)

        // When
        for field in WooShippingAddressFieldType.allCases {
            viewModel.validate(field)
        }

        // Then
        // Note that empty state is valid when country is empty (has no states).
        let expectedInvalidFieldTypes = viewModel.allFields.filter { $0.type != .state }.map { $0.type }
        XCTAssertEqual(viewModel.invalidFieldTypes, expectedInvalidFieldTypes)
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    func test_validate_sets_state_as_invalid_field_when_empty_and_country_contains_states() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [.fake()])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager,
                                                        debounceDelayInSeconds: 0)

        // When
        viewModel.validate(.state)

        // Then
        XCTAssertTrue(viewModel.invalidFieldTypes.contains(.state))
    }

    func test_validate_sets_phone_as_invalid_field_when_invalid_for_US() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager,
                                                        debounceDelayInSeconds: 0)

        // When
        viewModel.validate(.phone)

        // Then
        XCTAssertTrue(viewModel.invalidFieldTypes.contains(.phone))
    }

    func test_validate_removes_valid_field_from_invalidFields() {
        // Given
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        debounceDelayInSeconds: 0)
        // Precondition check
        viewModel.validate(.name)
        XCTAssertTrue(viewModel.invalidFieldTypes.contains(.name))

        // When
        viewModel.name.value = "JANE DOE"
        viewModel.validate(.name)

        // Then
        XCTAssertFalse(viewModel.invalidFieldTypes.contains(.name))
    }

    func test_status_is_unverified_when_verified_address_has_changes() {
        // Given
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        storageManager: storageManager)

        // Check precondition
        XCTAssertEqual(viewModel.status, .verified)

        // When
        viewModel.name.value = "JANE DOE SMITH"

        // Then
        XCTAssertEqual(viewModel.status, .unverified)
    }

    @MainActor
    func test_isLoading_set_during_and_after_remote_validation() async {
        // Given
        var isLoadingDuringRemoteAction = false
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        stores: stores,
                                                        debounceDelayInSeconds: 0)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                isLoadingDuringRemoteAction = viewModel.isLoading
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            }
        }

        // When
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertTrue(isLoadingDuringRemoteAction)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func test_remotelyValidateAddress_sends_expected_address_to_validate() async {
        // Given
        let expectedAddress = WooShippingAddress(company: "HEADQUARTERS",
                                                 name: "JANE DOE",
                                                 email: "",
                                                 phone: "1-234-456-7890",
                                                 country: "US",
                                                 state: "NY",
                                                 address1: "15 ALGONKIN ST STE 100",
                                                 address2: "",
                                                 city: "TICONDEROGA",
                                                 postcode: "12883-1487")
        var receivedAddress: WooShippingAddress?
        let storageManager = MockStorageManager()
        let country = Country(code: "US", name: "United States", states: [StateOfACountry(code: "NY", name: "New York")])
        storageManager.insertSampleCountries(readOnlyCountries: [country])
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, address, completion) = action {
                receivedAddress = address
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            }
        }
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: expectedAddress.name,
                                                        company: expectedAddress.company,
                                                        country: expectedAddress.country,
                                                        address: expectedAddress.address1,
                                                        city: expectedAddress.city,
                                                        state: expectedAddress.state,
                                                        postalCode: expectedAddress.postcode,
                                                        email: "",
                                                        phone: expectedAddress.phone,
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: true,
                                                        stores: stores,
                                                        storageManager: storageManager,
                                                        debounceDelayInSeconds: 0)

        // When
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertEqual(receivedAddress, expectedAddress)
    }

    @MainActor
    func test_remotelyValidateAddress_sets_normalizeAddressVM_on_success() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        stores: stores,
                                                        debounceDelayInSeconds: 0)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            }
        }

        // When
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertNotNil(viewModel.normalizeAddressVM)
    }

    @MainActor
    func test_remotelyValidateAddress_sets_status_and_field_errors_on_validation_error() async {
        // Given
        let expectedNameError = "Either Name or Company is required"
        let expectedAddressError = "House number is missing"
        let expectedGeneralError = "Address not found"
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
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
                                                        stores: stores,
                                                        debounceDelayInSeconds: 0)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.failure(WooShippingAddressValidationError(addressError: expectedAddressError,
                                                                      generalError: expectedGeneralError,
                                                                      nameError: expectedNameError)))
            }
        }

        // When
        viewModel.address.value = "ALGONKIN ST"
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertEqual(viewModel.name.errorMessage, expectedNameError)
        XCTAssertEqual(viewModel.address.errorMessage, expectedAddressError)
        XCTAssertEqual(viewModel.statusLabel, expectedGeneralError)
    }

    @MainActor
    func test_isLoading_set_during_and_after_remote_origin_address_update() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: .fake(), stores: stores)

        // When
        let isLoadingDuringRemoteAction: Bool = await waitForAsync { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .validateAddress(_, _, completion):
                    completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
                case let .updateOriginAddress(_, _, _, completion):
                    promise(viewModel.isLoading)
                    completion(.success(WooShippingOriginAddressUpdate(address: .fake(), isVerified: true)))
                default:
                    XCTFail("Unexpected action received: \(action)")
                }

            }
            await viewModel.remotelyValidateAddress()
            viewModel.normalizeAddressVM?.confirmSelectedAddress()
        }

        // Then
        XCTAssertTrue(isLoadingDuringRemoteAction)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func test_origin_address_update_sends_expected_origin_address_to_remote() async {
        // Given
        let originAddress = WooShippingOriginAddress.fake().copy(id: "origin",
                                                                 phone: "123-456-7890",
                                                                 firstName: "JANE",
                                                                 lastName: "DOE",
                                                                 email: "TEXT@EXAMPLE.COM")
        let suggestedAddress = WooShippingNormalizedAddress(company: "HEADQUARTERS",
                                                            firstName: "JANE",
                                                            lastName: "DOE",
                                                            email: "TEXT@EXAMPLE.COM",
                                                            phone: "123-456-7890",
                                                            country: "US",
                                                            state: "NY",
                                                            address1: "15 ALGONKIN ST STE 100",
                                                            address2: "",
                                                            city: "TICONDEROGA",
                                                            postcode: "12883-1487")
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: .fake().copy(siteID: 123)))
        let viewModel = WooShippingEditAddressViewModel(address: originAddress, stores: stores)

        // When
        let receivedAddress: WooShippingOriginAddress = await waitForAsync { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .validateAddress(_, _, completion):
                    completion(.success(.init(normalizedAddress: suggestedAddress, originalAddress: .fake(), isTrivialNormalization: true)))
                case let .updateOriginAddress(_, address, _, completion):
                    promise(address)
                    completion(.success(WooShippingOriginAddressUpdate(address: address, isVerified: true)))
                default:
                    XCTFail("Unexpected action received: \(action)")
                }
            }
            await viewModel.remotelyValidateAddress()
            viewModel.normalizeAddressVM?.confirmSelectedAddress()
        }

        // Then
        let expectedAddress = WooShippingOriginAddress(siteID: 123,
                                                       id: originAddress.id,
                                                       company: suggestedAddress.company,
                                                       address1: suggestedAddress.address1,
                                                       address2: suggestedAddress.address2,
                                                       city: suggestedAddress.city,
                                                       state: suggestedAddress.state,
                                                       postcode: suggestedAddress.postcode,
                                                       country: suggestedAddress.country,
                                                       phone: originAddress.phone,
                                                       firstName: suggestedAddress.fullName,
                                                       lastName: "",
                                                       email: originAddress.email,
                                                       defaultAddress: originAddress.defaultAddress,
                                                       isVerified: true)
        XCTAssertEqual(receivedAddress, expectedAddress)
    }

    @MainActor
    func test_origin_address_update_calls_onOriginAddressEdited_closure() async {
        // Given
        let expectedAddress = WooShippingOriginAddress.fake().copy(id: "origin")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let editedAddress: WooShippingOriginAddress = await waitForAsync { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .validateAddress(_, _, completion):
                    completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
                case let .updateOriginAddress(_, _, _, completion):
                    completion(.success(WooShippingOriginAddressUpdate(address: expectedAddress, isVerified: true)))
                default:
                    XCTFail("Unexpected action received: \(action)")
                }
            }
            // When
            let viewModel = WooShippingEditAddressViewModel(address: .fake(), stores: stores) { address in
                promise(address)
            }
            await viewModel.remotelyValidateAddress()
            viewModel.normalizeAddressVM?.confirmSelectedAddress()
        }

        // Then
        XCTAssertEqual(editedAddress, expectedAddress)
    }

    @MainActor
    func test_destination_address_update_sends_expected_origin_address_to_remote() async {
        // Given
        let sampleOrderID: Int64 = 123
        let destinationAddress = WooShippingAddress.fake().copy(name: "JANE DOE",
                                                                phone: "123-456-7890")
        let suggestedAddress = WooShippingNormalizedAddress(company: "HEADQUARTERS",
                                                            firstName: "JANE",
                                                            lastName: "DOE",
                                                            email: "TEXT@EXAMPLE.COM",
                                                            phone: "123-456-7890",
                                                            country: "US",
                                                            state: "NY",
                                                            address1: "15 ALGONKIN ST STE 100",
                                                            address2: "",
                                                            city: "TICONDEROGA",
                                                            postcode: "12883-1487")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: destinationAddress,
                                                        orderID: sampleOrderID,
                                                        email: "TEXT@EXAMPLE.COM",
                                                        isVerified: false,
                                                        originCountryCode: nil,
                                                        originStateCode: nil,
                                                        stores: stores)

        // When
        let receivedAddress: WooShippingDestinationAddress = await waitForAsync { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .validateAddress(_, _, completion):
                    completion(.success(.init(normalizedAddress: suggestedAddress, originalAddress: .fake(), isTrivialNormalization: true)))
                case let .updateDestinationAddress(_, _, address, _, completion):
                    promise(address)
                    completion(.success(WooShippingDestinationAddressUpdate(address: address, isVerified: true)))
                default:
                    XCTFail("Unexpected action received: \(action)")
                }
            }
            await viewModel.remotelyValidateAddress()
            viewModel.normalizeAddressVM?.confirmSelectedAddress()
        }

        // Then
        let expectedAddress = WooShippingDestinationAddress(company: suggestedAddress.company,
                                                            address1: suggestedAddress.address1,
                                                            address2: suggestedAddress.address2,
                                                            city: suggestedAddress.city,
                                                            state: suggestedAddress.state,
                                                            postcode: suggestedAddress.postcode,
                                                            country: suggestedAddress.country,
                                                            phone: suggestedAddress.phone,
                                                            name: suggestedAddress.fullName,
                                                            firstName: "",
                                                            lastName: "",
                                                            email: "TEXT@EXAMPLE.COM")
        XCTAssertEqual(receivedAddress, expectedAddress)
    }

    @MainActor
    func test_destination_address_update_calls_onDestinationAddressEdited_closure() async {
        // Given
        let sampleOrderID: Int64 = 123
        let normalizedAddress = WooShippingNormalizedAddress.fake().copy(firstName: "JANE",
                                                                         lastName: "DOE",
                                                                         email: "TEXT@EXAMPLE.COM",
                                                                         phone: "123-456-7890")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let result: (WooShippingDestinationAddressUpdate, String?) = await waitForAsync { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                switch action {
                case let .validateAddress(_, _, completion):
                    completion(.success(.init(normalizedAddress: normalizedAddress, originalAddress: .fake(), isTrivialNormalization: true)))
                case let .updateDestinationAddress(_, _, address, _, completion):
                    completion(.success(WooShippingDestinationAddressUpdate(address: address, isVerified: true)))
                default:
                    XCTFail("Unexpected action received: \(action)")
                }
            }
            // When

            let viewModel = WooShippingEditAddressViewModel(address: .fake(),
                                                            orderID: sampleOrderID,
                                                            email: "TEXT@EXAMPLE.COM",
                                                            isVerified: false,
                                                            originCountryCode: nil,
                                                            originStateCode: nil,
                                                            stores: stores) { addressUpdate, email in
                promise((addressUpdate, email))
            }
            viewModel.name.value = "JANE DOE"

            await viewModel.remotelyValidateAddress()
            viewModel.normalizeAddressVM?.confirmSelectedAddress()
        }

        // Then
        XCTAssertEqual(result.0.address.toWooShippingAddress(), normalizedAddress.toWooShippingAddress())
        XCTAssertEqual(result.1, "TEXT@EXAMPLE.COM")
        XCTAssertEqual(result.0.isVerified, true)
    }

    // MARK: - Error Alert Tests

    @MainActor
    func test_addressErrorState_is_none_initially() {
        // Given & When
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
                                                        isDefaultAddress: false,
                                                        showCompanyField: false,
                                                        isVerified: false)

        // Then
        XCTAssertEqual(viewModel.addressErrorState, .none)
    }

    @MainActor
    func test_addressErrorState_is_set_when_address_validation_fails_with_network_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "HEADQUARTERS",
                                                        country: "US",
                                                        address: "15 ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)
        XCTAssertEqual(viewModel.addressErrorState, .none)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.failure(NSError(domain: "NetworkError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"])))
            }
        }

        // When
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertEqual(viewModel.addressErrorState, .validation)
        XCTAssertEqual(viewModel.addressErrorState?.title, "Address Validation Error")
        XCTAssertEqual(viewModel.addressErrorState?.message, "The address you entered could not be verified. Please try again later.")
    }

    @MainActor
    func test_addressErrorState_is_set_when_origin_address_update_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: .fake(), stores: stores)
        XCTAssertEqual(viewModel.addressErrorState, .none)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .validateAddress(_, _, completion):
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            case let .updateOriginAddress(_, _, _, completion):
                completion(.failure(NSError(domain: "UpdateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update origin address"])))
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }

        // When
        await viewModel.remotelyValidateAddress()
        viewModel.normalizeAddressVM?.confirmSelectedAddress()

        // Then
        await until {
            if case .updateOrigin = viewModel.addressErrorState {
                return true
            }
            return false
        }

        XCTAssertEqual(viewModel.addressErrorState?.title, "Origin Address Update Error")
        XCTAssertEqual(viewModel.addressErrorState?.message, "The origin address could not be updated. Please try again later.")
    }

    @MainActor
    func test_addressErrorState_is_set_when_destination_address_update_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: .fake(),
                                                        orderID: sampleOrderID,
                                                        email: "test@example.com",
                                                        isVerified: false,
                                                        originCountryCode: nil,
                                                        originStateCode: nil,
                                                        stores: stores)
        XCTAssertEqual(viewModel.addressErrorState, .none)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .validateAddress(_, _, completion):
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            case let .updateDestinationAddress(_, _, _, _, completion):
                completion(.failure(NSError(domain: "UpdateError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update destination address"])))
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }

        // When
        await viewModel.remotelyValidateAddress()
        viewModel.normalizeAddressVM?.confirmSelectedAddress()

        // Then
        await until {
            if case .updateDestination = viewModel.addressErrorState {
                return true
            }
            return false
        }

        XCTAssertEqual(viewModel.addressErrorState?.title, "Destination Address Update Error")
        XCTAssertEqual(viewModel.addressErrorState?.message, "The destination address could not be updated. Please try again later.")
    }

    @MainActor
    func test_address_validation_error_alert_retry_action_calls_remotelyValidateAddress() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "HEADQUARTERS",
                                                        country: "US",
                                                        address: "15 ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)

        var validationCallCount = 0
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                validationCallCount += 1
                if validationCallCount == 1 {
                    // First call fails
                    completion(.failure(NSError(domain: "NetworkError", code: 500)))
                } else {
                    // Second call succeeds
                    completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
                }
            }
        }

        // When
        await viewModel.remotelyValidateAddress() // First call - should fail and set alert

        // Then
        await until {
            viewModel.addressErrorState == .validation && validationCallCount == 1
        }

        // Simulate retry button tap by calling remotelyValidateAddress again
        await viewModel.remotelyValidateAddress()

        // Then
        await until {
            validationCallCount == 2
        }
    }

    @MainActor
    func test_origin_address_update_error_alert_retry_action_calls_retryOriginAddressUpdate() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: .fake(), stores: stores)

        var validationCallCount = 0
        var updateCallCount = 0
        var savedAddress: WooShippingAddress?
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .validateAddress(_, _, completion):
                validationCallCount += 1
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            case let .updateOriginAddress(_, _, _, completion):
                updateCallCount += 1
                if updateCallCount == 1 {
                    // First update fails
                    completion(.failure(NSError(domain: "UpdateError", code: 500)))
                } else {
                    // Second update succeeds
                    completion(.success(WooShippingOriginAddressUpdate(address: .fake(), isVerified: true)))
                }
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }

        // When
        await viewModel.remotelyValidateAddress()
        viewModel.normalizeAddressVM?.confirmSelectedAddress() // This should fail and set alert

        // Then
        await until {
            if case .updateOrigin(let address) = viewModel.addressErrorState {
                savedAddress = address
                return updateCallCount == 1
            }
            return false
        }

        // Simulate retry button tap by calling updateConfirmedAddress with the saved address
        if let address = savedAddress {
            viewModel.updateConfirmedAddress(address)
        }

        // Then
        await until {
            updateCallCount == 2
        }
    }

    @MainActor
    func test_destination_address_update_error_alert_retry_action_calls_retryDestinationAddressUpdate() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: .fake(),
                                                        orderID: sampleOrderID,
                                                        email: "test@example.com",
                                                        isVerified: false,
                                                        originCountryCode: nil,
                                                        originStateCode: nil,
                                                        stores: stores)

        var validationCallCount = 0
        var updateCallCount = 0
        var savedAddress: WooShippingAddress?
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .validateAddress(_, _, completion):
                validationCallCount += 1
                completion(.success(.init(normalizedAddress: .fake(), originalAddress: .fake(), isTrivialNormalization: true)))
            case let .updateDestinationAddress(_, _, _, _, completion):
                updateCallCount += 1
                if updateCallCount == 1 {
                    // First update fails
                    completion(.failure(NSError(domain: "UpdateError", code: 500)))
                } else {
                    // Second update succeeds
                    completion(.success(WooShippingDestinationAddressUpdate(address: .fake(), isVerified: true)))
                }
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }

        // When
        await viewModel.remotelyValidateAddress()
        viewModel.normalizeAddressVM?.confirmSelectedAddress() // This should fail and set alert

        // Then
        await until {
            if case .updateDestination(let address) = viewModel.addressErrorState {
                savedAddress = address
                return updateCallCount == 1
            }
            return false
        }

        // Simulate retry button tap by calling updateConfirmedAddress with the saved address
        if let address = savedAddress {
            viewModel.updateConfirmedAddress(address)
        }

        // Then
        await until {
            updateCallCount == 2
        }
    }

    @MainActor
    func test_addressErrorState_does_not_interfere_with_validation_error_handling() async {
        // Given
        let expectedNameError = "Either Name or Company is required"
        let expectedAddressError = "House number is missing"
        let expectedGeneralError = "Address not found"
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "US",
                                                        address: "ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.failure(WooShippingAddressValidationError(addressError: expectedAddressError,
                                                                      generalError: expectedGeneralError,
                                                                      nameError: expectedNameError)))
            }
        }

        // When
        // Make a change to trigger hasChanges = true
        viewModel.address.value = "15 ALGONKIN ST" // This should trigger hasChanges
        await viewModel.remotelyValidateAddress()

        // Then
        // Should handle validation errors normally, not show error alert
        XCTAssertEqual(viewModel.addressErrorState, .none)
        XCTAssertEqual(viewModel.name.errorMessage, expectedNameError)
        XCTAssertEqual(viewModel.address.errorMessage, expectedAddressError)
        XCTAssertEqual(viewModel.statusLabel, expectedGeneralError)
    }

    // MARK: - canConfirmWithoutVerification Tests

    func test_canConfirmWithoutVerification_is_false_initially() {
        // Given & When
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "HEADQUARTERS",
                                                        country: "US",
                                                        address: "15 ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false)

        // Then
        XCTAssertFalse(viewModel.canConfirmWithoutVerification)
    }

    @MainActor
    func test_canConfirmWithoutVerification_is_enabled_for_destination_addresses_when_validation_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "US",
                                                        address: "ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)

        // Initial state
        XCTAssertFalse(viewModel.canConfirmWithoutVerification)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.failure(WooShippingAddressValidationError(addressError: "House number is missing",
                                                                      generalError: "Address not found",
                                                                      nameError: nil)))
            }
        }

        // When
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertTrue(viewModel.canConfirmWithoutVerification)
        XCTAssertEqual(viewModel.status, .unverified)
    }

    @MainActor
    func test_canConfirmWithoutVerification_remains_false_for_origin_addresses_even_when_validation_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .origin,
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "US",
                                                        address: "ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: true,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)

        // Initial state
        XCTAssertFalse(viewModel.canConfirmWithoutVerification)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.failure(WooShippingAddressValidationError(addressError: "House number is missing",
                                                                      generalError: "Address not found",
                                                                      nameError: nil)))
            }
        }

        // When
        await viewModel.remotelyValidateAddress()

        // Then
        XCTAssertFalse(viewModel.canConfirmWithoutVerification)
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    @MainActor
    func test_canConfirmWithoutVerification_resets_to_false_when_address_fields_change() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "",
                                                        company: "",
                                                        country: "US",
                                                        address: "ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .validateAddress(_, _, completion) = action {
                completion(.failure(WooShippingAddressValidationError(addressError: "House number is missing",
                                                                      generalError: "Address not found",
                                                                      nameError: "Either Name or Company is required")))
            }
        }

        await viewModel.remotelyValidateAddress()
        XCTAssertTrue(viewModel.canConfirmWithoutVerification)
        XCTAssertEqual(viewModel.status, .unverified)

        // When any field value changes
        viewModel.name.value = "JANE DOE"

        // Then
        XCTAssertFalse(viewModel.canConfirmWithoutVerification)
        XCTAssertEqual(viewModel.status, .missingInformation)
    }

    @MainActor
    func test_updateConfirmedAddress_without_verification_triggers_updateDestinationAddress_with_isVerified_false() async {
        // Given
        let sampleOrderID: Int64 = 123
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(type: .destination(orderID: sampleOrderID),
                                                        id: "",
                                                        name: "JANE DOE",
                                                        company: "HEADQUARTERS",
                                                        country: "US",
                                                        address: "15 ALGONKIN ST",
                                                        city: "TICONDEROGA",
                                                        state: "NY",
                                                        postalCode: "12883-1487",
                                                        email: "test@example.com",
                                                        phone: "123-456-7890",
                                                        isDefaultAddress: false,
                                                        showCompanyField: true,
                                                        isVerified: false,
                                                        stores: stores)

        let testAddress = WooShippingAddress(company: "TEST COMPANY",
                                             name: "TEST NAME",
                                             email: "test@example.com",
                                             phone: "555-123-4567",
                                             country: "US",
                                             state: "CA",
                                             address1: "123 TEST ST",
                                             address2: "",
                                             city: "TEST CITY",
                                             postcode: "90210")

        // When
        let receivedIsVerified: Bool = await waitForAsync { promise in
            stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
                if case let .updateDestinationAddress(_, _, _, isVerified, completion) = action {
                    promise(isVerified)
                    completion(.success(WooShippingDestinationAddressUpdate(address: .fake(), isVerified: isVerified)))
                }
            }
            viewModel.updateConfirmedAddress(testAddress, withoutVerification: true)
        }

        // Then
        XCTAssertFalse(receivedIsVerified, "updateDestinationAddress should be called with isVerified: false when withoutVerification is true")
    }
}

private extension WooShippingEditAddressViewModel {
    var invalidFieldTypes: [WooShippingAddressFieldType] {
        allFields.filter { $0.errorMessage != nil }.map { $0.type }
    }
}
