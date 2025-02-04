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
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.normalizeAddressVM)
    }

    func test_origin_address_inits_with_expected_values() {
        // Given
        let storageManager = MockStorageManager()
        let state = StateOfACountry(code: "NY", name: "New York")
        let countries = [Country(code: "US", name: "United States", states: [state]), Country(code: "CA", name: "Canada", states: [])]
        storageManager.insertSampleCountries(readOnlyCountries: countries)
        let address = WooShippingLabelAddress(id: "default_address",
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

    func test_validateAddress_sets_expected_status_when_all_fields_valid() {
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
        XCTAssertTrue(viewModel.invalidFieldTypes.isEmpty)
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
                                                        phoneNumberRequired: true,
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
                                                        storageManager: storageManager,
                                                        debounceDelayInSeconds: 0)

        // When
        viewModel.validate(.phone)

        // Then
        XCTAssertTrue(viewModel.invalidFieldTypes.contains(.phone))
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
                                                        phoneNumberRequired: true,
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
        let expectedAddress = ShippingLabelAddress(company: "HEADQUARTERS",
                                                   name: "JANE DOE",
                                                   phone: "1-234-456-7890",
                                                   country: "US",
                                                   state: "NY",
                                                   address1: "15 ALGONKIN ST STE 100",
                                                   address2: "",
                                                   city: "TICONDEROGA",
                                                   postcode: "12883-1487")
        var receivedAddress: ShippingLabelAddress?
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
        let viewModel = WooShippingEditAddressViewModel(type: .destination,
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
                                                        phoneNumberRequired: true,
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
        let originAddress = WooShippingLabelAddress.fake().copy(id: "origin",
                                                                 phone: "123-456-7890",
                                                                 firstName: "JANE",
                                                                 lastName: "DOE",
                                                                 email: "TEXT@EXAMPLE.COM")
        let suggestedAddress = WooShippingAddress(company: "HEADQUARTERS",
                                                  name: "JANE DOE",
                                                  phone: "123-456-7890",
                                                  country: "US",
                                                  state: "NY",
                                                  address1: "15 ALGONKIN ST STE 100",
                                                  address2: "",
                                                  city: "TICONDEROGA",
                                                  postcode: "12883-1487",
                                                  email: "TEST@EXAMPLE.COM")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingEditAddressViewModel(address: originAddress, stores: stores)

        // When
        let receivedAddress: WooShippingLabelAddress = await waitForAsync { promise in
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
        let expectedAddress = WooShippingLabelAddress(id: originAddress.id,
                                                      company: suggestedAddress.company,
                                                      address1: suggestedAddress.address1,
                                                      address2: suggestedAddress.address2,
                                                      city: suggestedAddress.city,
                                                      state: suggestedAddress.state,
                                                      postcode: suggestedAddress.postcode,
                                                      country: suggestedAddress.country,
                                                      phone: originAddress.phone,
                                                      firstName: suggestedAddress.name,
                                                      lastName: "",
                                                      email: originAddress.email,
                                                      defaultAddress: originAddress.defaultAddress,
                                                      isVerified: true)
        XCTAssertEqual(receivedAddress, expectedAddress)
    }

    @MainActor
    func test_origin_address_update_calls_onOriginAddressEdited_closure() async {
        // Given
        let expectedAddress = WooShippingLabelAddress.fake().copy(id: "origin")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let editedAddress: WooShippingLabelAddress = await waitForAsync { promise in
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
}

private extension WooShippingEditAddressViewModel {
    var invalidFieldTypes: [WooShippingAddressFieldType] {
        allFields.filter { $0.errorMessage != nil }.map { $0.type }
    }
}
