import XCTest
import Yosemite
import TestKit
import Combine
@testable import WooCommerce

final class CreateOrderAddressFormViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123

    let testingStorage = MockStorageManager()

    let testingStores = MockStoresManager(sessionManager: .testingInstance)

    var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        testingStorage.reset()
        testingStorage.insertSampleCountries(readOnlyCountries: Self.sampleCountries)

        testingStores.reset()
        subscriptions.removeAll()
    }

    func test_input_of_identical_addresses_disables_different_address_toggle() {
        // Given
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: sampleAddress(), shippingAddress: sampleAddress()),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)

        // Then
        XCTAssertFalse(viewModel.showDifferentAddressForm)
    }

    func test_input_of_identical_addresses_does_not_prefill_second_set_of_fields() {
        // Given
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: sampleAddress(), shippingAddress: sampleAddress()),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        assertEqual(viewModel.secondaryFields.toAddress(), .empty)
    }

    func test_input_of_different_addresses_enables_different_address_toggle() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)

        // Then
        XCTAssertTrue(viewModel.showDifferentAddressForm)
    }

    func test_creating_with_second_address_prefills_fields_with_correct_data() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.secondaryFields.firstName, address2.firstName)
        XCTAssertEqual(viewModel.secondaryFields.lastName, address2.lastName)
        XCTAssertEqual(viewModel.secondaryFields.email, address2.email ?? "")
        XCTAssertEqual(viewModel.secondaryFields.phone, address2.phone ?? "")

        XCTAssertEqual(viewModel.secondaryFields.company, address2.company ?? "")
        XCTAssertEqual(viewModel.secondaryFields.address1, address2.address1)
        XCTAssertEqual(viewModel.secondaryFields.address2, address2.address2 ?? "")
        XCTAssertEqual(viewModel.secondaryFields.city, address2.city)
        XCTAssertEqual(viewModel.secondaryFields.postcode, address2.postcode)

        let country = Self.sampleCountries.first { $0.code == address2.country }
        XCTAssertEqual(viewModel.secondaryFields.country, country?.name)
        XCTAssertEqual(viewModel.secondaryFields.state, country?.states.first?.name) // Only one state supported in tests

        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_selecting_country_updates_country_field() {
        // Given
        let newCountry = Self.sampleCountries[0]

        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        viewModel.onLoadTrigger.send()

        // When
        let countryViewModel = viewModel.createSecondaryCountryViewModel()
        let viewController = ListSelectorViewController(command: countryViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countryViewModel.command.handleSelectedChange(selected: newCountry, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.secondaryFields.country, newCountry.name)
    }

    func test_country_and_state_names_are_converted_from_codes_when_available() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        XCTAssertEqual(viewModel.secondaryFields.country, "US")
        XCTAssertNil(viewModel.secondaryFields.selectedCountry)
        XCTAssertEqual(viewModel.secondaryFields.state, "NY")
        XCTAssertNil(viewModel.secondaryFields.selectedState)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.secondaryFields.country, "United States")
        XCTAssertNotNil(viewModel.secondaryFields.selectedCountry)
        XCTAssertEqual(viewModel.secondaryFields.state, "New York")
        XCTAssertNotNil(viewModel.secondaryFields.selectedState)
    }

    func test_state_name_is_displayed_as_string_when_mapping_is_not_available() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(state: "Bavaria", country: "Germany")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        XCTAssertEqual(viewModel.secondaryFields.state, "Bavaria")
        XCTAssertNil(viewModel.secondaryFields.selectedState)
    }

    func test_selecting_country_without_states_nullifies_selectedState_property_but_keeps_state_field() {
        // Given
        let newCountry = Country(code: "GB", name: "United Kingdom", states: [])

        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        viewModel.onLoadTrigger.send()
        XCTAssertEqual(viewModel.secondaryFields.state, "New York")
        XCTAssertNotNil(viewModel.secondaryFields.selectedState)

        // When
        let countryViewModel = viewModel.createSecondaryCountryViewModel()
        let viewController = ListSelectorViewController(command: countryViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countryViewModel.command.handleSelectedChange(selected: newCountry, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.secondaryFields.state, "New York")
        XCTAssertNil(viewModel.secondaryFields.selectedState)
    }

    func test_selecting_country_with_states_nullifies_selectedState_property_and_state_field() {
        // Given
        let newCountry = Country(code: "AU", name: "Australia", states: [.init(code: "VIC", name: "Victoria")])

        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        viewModel.onLoadTrigger.send()
        XCTAssertEqual(viewModel.secondaryFields.state, "New York")
        XCTAssertNotNil(viewModel.secondaryFields.selectedState)

        // When
        let countryViewModel = viewModel.createSecondaryCountryViewModel()
        let viewController = ListSelectorViewController(command: countryViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        countryViewModel.command.handleSelectedChange(selected: newCountry, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.secondaryFields.state, "")
        XCTAssertNil(viewModel.secondaryFields.selectedState)
    }

    func test_selecting_state_updates_state_field() {
        // Given
        let newState = StateOfACountry(code: "CA", name: "California")

        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        viewModel.onLoadTrigger.send()

        // When
        let stateViewModel = viewModel.createSecondaryStateViewModel()
        let viewController = ListSelectorViewController(command: stateViewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        stateViewModel.command.handleSelectedChange(selected: newState, viewController: viewController)

        // Then
        XCTAssertEqual(viewModel.secondaryFields.state, newState.name)
    }

    func test_updating_second_fields_enables_done_button() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.secondaryFields.firstName = "Johnny"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_updating_second_fields_back_to_original_values_disables_done_button() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.secondaryFields.firstName = "Johnny"
        viewModel.secondaryFields.lastName = "Ipsum"
        viewModel.secondaryFields.firstName = "John"
        viewModel.secondaryFields.lastName = "Appleseed"

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_turning_off_different_address_toggle_for_different_input_addresses_enables_done_button() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.showDifferentAddressForm = false

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: true))
    }

    func test_switching_different_address_toggle_for_same_input_addresses_does_not_enable_done_button() {
        // Given
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: sampleAddress(), shippingAddress: sampleAddress()),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.onLoadTrigger.send()
        viewModel.showDifferentAddressForm = true

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))

        // When
        viewModel.showDifferentAddressForm = false

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done(enabled: false))
    }

    func test_view_model_returns_duplicated_billing_address_when_toggle_is_disabled() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        var updatedAddressData: CreateOrderAddressFormViewModel.NewOrderAddressData?
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: { updatedData in
            updatedAddressData = updatedData
        },
                                                        storageManager: testingStorage)

        // When
        viewModel.showDifferentAddressForm = false
        viewModel.fields.firstName = "Tester"
        viewModel.saveAddress { _ in }

        // Then
        assertEqual(updatedAddressData?.billingAddress?.firstName, "Tester")
        assertEqual(updatedAddressData?.billingAddress, updatedAddressData?.shippingAddress)
    }

    func test_view_model_returns_different_billing_and_shipping_addresses_when_toggle_is_enabled() {
        // Given
        let address1 = sampleAddress()
        let address2 = sampleAddress().copy(firstName: "John")
        var updatedAddressData: CreateOrderAddressFormViewModel.NewOrderAddressData?
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: address1, shippingAddress: address2),
                                                        onAddressUpdate: { updatedData in
            updatedAddressData = updatedData
        },
                                                        storageManager: testingStorage)

        // When
        XCTAssertTrue(viewModel.showDifferentAddressForm)
        viewModel.fields.firstName = "Tester"
        viewModel.saveAddress { _ in }

        // Then
        assertEqual(updatedAddressData?.billingAddress?.firstName, "Tester")
        assertEqual(updatedAddressData?.shippingAddress?.firstName, "John")
        XCTAssertNotEqual(updatedAddressData?.billingAddress, updatedAddressData?.shippingAddress)
    }

    func test_view_model_fires_error_notice_after_failing_to_fetch_countries() {
        // Given
        testingStorage.reset()
        testingStores.whenReceivingAction(ofType: DataAction.self) { action in
            switch action {
            case .synchronizeCountries(_, let completion):
                completion(.failure(NSError(domain: "", code: 0)))
            }
        }

        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: sampleAddress(), shippingAddress: sampleAddress()),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage,
                                                        stores: testingStores)

        // When
        viewModel.onLoadTrigger.send()

        // Then
        assertEqual(viewModel.notice, AddressFormViewModel.NoticeFactory.createErrorNotice(from: .unableToLoadCountries))
    }

    func test_view_model_shows_email_field() {
        // Given
        let viewModel = CreateOrderAddressFormViewModel(siteID: sampleSiteID,
                                                        addressData: .init(billingAddress: sampleAddress(), shippingAddress: sampleAddress()),
                                                        onAddressUpdate: nil,
                                                        storageManager: testingStorage)

        // Then
        XCTAssertTrue(viewModel.showEmailField)
    }
}

private extension CreateOrderAddressFormViewModelTests {
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
}

private extension CreateOrderAddressFormViewModelTests {
    static let sampleCountries: [Country] = {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            let states = regionCode == "US" ? [StateOfACountry(code: "NY", name: "New York")] : []
            return Country(code: regionCode, name: name, states: states)
        }.sorted { a, b in
            a.name <= b.name
        }
    }()
}
