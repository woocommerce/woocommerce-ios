import XCTest
@testable import WooCommerce
import Yosemite
@testable import Storage

final class ShippingLabelFormViewModelTests: XCTestCase {

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

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
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: address,
                                                                    destinationAddress: nil)

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
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
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

    func test_handleOriginAddressValueChanges_reset_carrier_and_rates_selection() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                           name: "Skylar Ferry",
                                                           phone: "12345",
                                                           country: "United States",
                                                           state: "CA",
                                                           address1: "60 29th",
                                                           address2: "Street #343",
                                                           city: "San Francisco",
                                                           postcode: "94121-2303")
        let rate = ShippingLabelSelectedRate(packageID: "123",
                                             rate: MockShippingLabelCarrierRate.makeRate(),
                                             signatureRate: nil,
                                             adultSignatureRate: nil)
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRates: [rate],
                                                                     editable: true)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isNotEmpty)

        // When
        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isEmpty)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let row = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(row?.dataState, .pending)
        XCTAssertEqual(row?.displayMode, .disabled)
    }

    func test_handleDestinationAddressValueChanges_returns_updated_ShippingLabelAddress() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
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

    func test_handleDestinationAddressValueChanges_reset_carrier_and_rates_selection() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                           name: "Skylar Ferry",
                                                           phone: "12345",
                                                           country: "United States",
                                                           state: "CA",
                                                           address1: "60 29th",
                                                           address2: "Street #343",
                                                           city: "San Francisco",
                                                           postcode: "94121-2303")
        let rate = ShippingLabelSelectedRate(packageID: "123",
                                             rate: MockShippingLabelCarrierRate.makeRate(),
                                             signatureRate: nil,
                                             adultSignatureRate: nil)
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRates: [rate],
                                                                     editable: true)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isNotEmpty)

        // When
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isEmpty)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let row = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(row?.dataState, .pending)
        XCTAssertEqual(row?.displayMode, .disabled)
    }

    func test_handleNewPackagesResponse_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageResponse = ShippingLabelPackagesResponse.fake()

        // When
        shippingLabelFormViewModel.handleNewPackagesResponse(packagesResponse: expectedPackageResponse)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.packagesResponse, expectedPackageResponse)
    }

    func test_handlePackageDetailsValueChanges_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageID = "my-package-id"
        let expectedPackageWeight = "55"
        let selectedPackage = ShippingLabelPackageAttributes(packageID: expectedPackageID, totalWeight: expectedPackageWeight, items: [])

        // When
        shippingLabelFormViewModel.handlePackageDetailsValueChanges(details: [selectedPackage])

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.selectedPackagesDetails, [selectedPackage])
    }

    func test_handlePackageDetailsValueChanges_reset_carrier_and_rates_selection() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageID = "my-package-id"
        let expectedPackageWeight = "55"
        let selectedPackage = ShippingLabelPackageAttributes(packageID: expectedPackageID, totalWeight: expectedPackageWeight, items: [])

        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(), validated: true)
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(), validated: true)
        let rate = ShippingLabelSelectedRate(packageID: "123",
                                             rate: MockShippingLabelCarrierRate.makeRate(),
                                             signatureRate: nil,
                                             adultSignatureRate: nil)
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRates: [rate],
                                                                     editable: true)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isNotEmpty)

        // When
        shippingLabelFormViewModel.handlePackageDetailsValueChanges(details: [selectedPackage])

        // Then
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isEmpty)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let row = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(row?.dataState, .pending)
        XCTAssertEqual(row?.displayMode, .editable)
    }

    func test_handlePackageDetailsValueChanges_resets_customs_and_carrier_and_rates_selection() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageWeight = "55"
        let selectedPackage = ShippingLabelPackageAttributes(packageID: "my-package-id", totalWeight: expectedPackageWeight, items: [])

        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(phone: "0123456789", country: "US"),
                                                                   validated: true)
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(phone: "0987654321", country: "VN"),
                                                                        validated: true)
        shippingLabelFormViewModel.handleCustomsFormsValueChanges(customsForms: [ShippingLabelCustomsForm.fake()], isValidated: true)
        let rate = ShippingLabelSelectedRate(packageID: "123",
                                             rate: MockShippingLabelCarrierRate.makeRate(),
                                             signatureRate: nil,
                                             adultSignatureRate: nil)
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRates: [rate],
                                                                     editable: true)
        XCTAssertFalse(shippingLabelFormViewModel.customsForms.isEmpty)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isNotEmpty)

        // When
        shippingLabelFormViewModel.handlePackageDetailsValueChanges(details: [selectedPackage])

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.customsForms.first?.packageID, selectedPackage.id)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isEmpty)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let customsRow = rows?.first { $0.type == .customs }
        XCTAssertEqual(customsRow?.dataState, .pending)
        XCTAssertEqual(customsRow?.displayMode, .editable)

        let carrierRow = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(carrierRow?.dataState, .pending)
        XCTAssertEqual(carrierRow?.displayMode, .disabled)
    }

    func test_handleCustomsFormsValueChanges_resets_carrier_and_rates_selection() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)

        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(phone: "0123456789", country: "US"),
                                                                   validated: true)
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "VN"), validated: true)
        shippingLabelFormViewModel.handleCustomsFormsValueChanges(customsForms: [ShippingLabelCustomsForm.fake()], isValidated: true)
        let rate = ShippingLabelSelectedRate(packageID: "123",
                                             rate: MockShippingLabelCarrierRate.makeRate(),
                                             signatureRate: nil,
                                             adultSignatureRate: nil)
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRates: [rate],
                                                                     editable: true)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isNotEmpty)

        // When
        shippingLabelFormViewModel.handleCustomsFormsValueChanges(customsForms: [ShippingLabelCustomsForm.fake()], isValidated: true)

        // Then
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isEmpty)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let carrierRow = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(carrierRow?.dataState, .pending)
        XCTAssertEqual(carrierRow?.displayMode, .disabled)
    }

    func test_handleCarrierAndRatesValueChanges_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        XCTAssertTrue(shippingLabelFormViewModel.selectedRates.isEmpty)

        // When
        let rate = ShippingLabelSelectedRate(packageID: "123",
                                             rate: MockShippingLabelCarrierRate.makeRate(),
                                             signatureRate: MockShippingLabelCarrierRate.makeRate(title: "UPS"),
                                             adultSignatureRate: nil)
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRates: [rate],
                                                                     editable: true)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.selectedRates.first?.rate, MockShippingLabelCarrierRate.makeRate())
        XCTAssertEqual(shippingLabelFormViewModel.selectedRates.first?.signatureRate, MockShippingLabelCarrierRate.makeRate(title: "UPS"))
        XCTAssertNil(shippingLabelFormViewModel.selectedRates.first?.adultSignatureRate)
    }

    func test_sections_returns_updated_rows_after_validating_origin_address() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = MockShippingLabelAddress.sampleAddress()
        let currentRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[0].type, .shipFrom)
        XCTAssertEqual(currentRows?[0].dataState, .pending)
        XCTAssertEqual(currentRows?[0].displayMode, .editable)
        XCTAssertEqual(currentRows?[1].type, .shipTo)
        XCTAssertEqual(currentRows?[1].dataState, .pending)
        XCTAssertEqual(currentRows?[1].displayMode, .disabled)
        XCTAssertEqual(currentRows?[2].type, .packageDetails)
        XCTAssertEqual(currentRows?[2].dataState, .pending)
        XCTAssertEqual(currentRows?[2].displayMode, .disabled)

        // When

        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        let updatedRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(updatedRows?[0].type, .shipFrom)
        XCTAssertEqual(updatedRows?[0].dataState, .validated)
        XCTAssertEqual(updatedRows?[0].displayMode, .editable)
        XCTAssertEqual(updatedRows?[1].type, .shipTo)
        XCTAssertEqual(updatedRows?[1].dataState, .pending)
        XCTAssertEqual(updatedRows?[1].displayMode, .editable)
        XCTAssertEqual(updatedRows?[2].type, .packageDetails)
        XCTAssertEqual(updatedRows?[2].dataState, .pending)
        XCTAssertEqual(updatedRows?[2].displayMode, .disabled)
    }

    func test_sections_returns_updated_rows_after_validating_destination_address() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = MockShippingLabelAddress.sampleAddress()

        // When
        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)
        let currentRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[0].type, .shipFrom)
        XCTAssertEqual(currentRows?[0].dataState, .validated)
        XCTAssertEqual(currentRows?[0].displayMode, .editable)
        XCTAssertEqual(currentRows?[1].type, .shipTo)
        XCTAssertEqual(currentRows?[1].dataState, .pending)
        XCTAssertEqual(currentRows?[1].displayMode, .editable)
        XCTAssertEqual(currentRows?[2].type, .packageDetails)
        XCTAssertEqual(currentRows?[2].dataState, .pending)
        XCTAssertEqual(currentRows?[2].displayMode, .disabled)
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        let updatedRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(updatedRows?[0].type, .shipFrom)
        XCTAssertEqual(updatedRows?[0].dataState, .validated)
        XCTAssertEqual(updatedRows?[0].displayMode, .editable)
        XCTAssertEqual(updatedRows?[1].type, .shipTo)
        XCTAssertEqual(updatedRows?[1].dataState, .validated)
        XCTAssertEqual(updatedRows?[1].displayMode, .editable)
        XCTAssertEqual(updatedRows?[2].type, .packageDetails)
        XCTAssertEqual(updatedRows?[2].dataState, .pending)
        XCTAssertEqual(updatedRows?[2].displayMode, .editable)
    }

    func test_validateAddress_returns_validation_error_when_missing_name_without_triggering_action() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let expectedValidationError = ShippingLabelAddressValidationError(addressError: nil, generalError: "Name is required")
        let originAddress = Address.fake()
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: originAddress,
                                                                    destinationAddress: nil,
                                                                    stores: storesManager)

        // When
        shippingLabelFormViewModel.validateAddress(type: .origin) { validationState, validationSuccess in
            guard case let .validationError(error) = validationState else {
                XCTFail("Validation error was not returned")
                return
            }
            XCTAssertEqual(error, expectedValidationError)
        }

        // Then
        let triggeredValidateAddressAction: Bool = {
            var triggered = false
            for action in storesManager.receivedActions {
                if case ShippingLabelAction.validateAddress = action {
                    triggered = true
                    break
                }
            }
            return triggered
        }()
        XCTAssertFalse(triggeredValidateAddressAction)
    }

    func test_validateAddress_triggers_validate_action_when_name_is_not_missing() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        let originAddress = Address(firstName: "Lorem",
                                    lastName: "Ipsum",
                                    company: nil,
                                    address1: "",
                                    address2: nil,
                                    city: "",
                                    state: "",
                                    postcode: "",
                                    country: "",
                                    phone: nil,
                                    email: nil)
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: originAddress,
                                                                    destinationAddress: nil,
                                                                    stores: storesManager)

        // When
        shippingLabelFormViewModel.validateAddress(type: .origin) { _, _ in }

        // Then
        let triggeredValidateAddressAction: Bool = {
            var triggered = false
            for action in storesManager.receivedActions {
                if case ShippingLabelAction.validateAddress = action {
                    triggered = true
                    break
                }
            }
            return triggered
        }()
        XCTAssertTrue(triggeredValidateAddressAction)
    }

    func test_handlePaymentMethodValueChanges_returns_updated_data_and_state_with_no_selected_payment_method() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPaymentMethodID: Int64 = 0
        let expectedEmailReceiptsSetting = true
        let settings = ShippingLabelAccountSettings.fake().copy(selectedPaymentMethodID: expectedPaymentMethodID,
                                                                isEmailReceiptsEnabled: expectedEmailReceiptsSetting)

        // When
        viewModel.handlePaymentMethodValueChanges(settings: settings, editable: false)

        // Then
        let currentRows = viewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[4].type, .paymentMethod)
        XCTAssertEqual(currentRows?[4].dataState, .pending)
        XCTAssertEqual(viewModel.shippingLabelAccountSettings?.selectedPaymentMethodID, expectedPaymentMethodID)
        XCTAssertEqual(viewModel.shippingLabelAccountSettings?.isEmailReceiptsEnabled, expectedEmailReceiptsSetting)
    }

    func test_handlePaymentMethodValueChanges_returns_updated_data_and_state_with_selected_payment_method() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPaymentMethodID: Int64 = 12345
        let expectedEmailReceiptsSetting = false
        let settings = ShippingLabelAccountSettings.fake().copy(selectedPaymentMethodID: expectedPaymentMethodID,
                                                                isEmailReceiptsEnabled: expectedEmailReceiptsSetting)

        // When
        viewModel.handlePaymentMethodValueChanges(settings: settings, editable: false)

        // Then
        let currentRows = viewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[4].type, .paymentMethod)
        XCTAssertEqual(currentRows?[4].dataState, .validated)
        XCTAssertEqual(viewModel.shippingLabelAccountSettings?.selectedPaymentMethodID, expectedPaymentMethodID)
        XCTAssertEqual(viewModel.shippingLabelAccountSettings?.isEmailReceiptsEnabled, expectedEmailReceiptsSetting)
    }

    func test_getPaymentMethodBody_returns_placeholder_with_no_selected_payment_method() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                   originAddress: nil,
                                                   destinationAddress: nil)
        let settings = ShippingLabelAccountSettings.fake().copy()

        // When
        viewModel.handlePaymentMethodValueChanges(settings: settings, editable: false)

        // Then
        let paymentMethodBody = viewModel.getPaymentMethodBody()
        XCTAssertEqual(paymentMethodBody, "Add a new credit card")
    }

    func test_getPaymentMethodBody_returns_card_details_with_selected_payment_method() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                   originAddress: nil,
                                                   destinationAddress: nil)
        let paymentMethod = ShippingLabelPaymentMethod.fake().copy(paymentMethodID: 12345, cardDigits: "4242")
        let settings = ShippingLabelAccountSettings.fake().copy(paymentMethods: [paymentMethod], selectedPaymentMethodID: 12345)

        // When
        viewModel.handlePaymentMethodValueChanges(settings: settings, editable: true)

        // Then
        let paymentMethodBody = viewModel.getPaymentMethodBody()
        XCTAssertEqual(paymentMethodBody, "Credit card ending in 4242")
    }

    func test_filteredCountries_returns_only_USPS_supported_countries_for_origin_address() {
        // Given
        let country1 = Country(code: "US", name: "United States", states: [])
        let country2 = Country(code: "IT", name: "Italy", states: [])
        insert(country1)
        insert(country2)

        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: nil, destinationAddress: nil, storageManager: storageManager)

        // When
        let filteredCountries = viewModel.filteredCountries(for: .origin)

        // Then
        XCTAssertEqual(filteredCountries.count, 1)
    }

    func test_filteredCountries_returns_complete_country_list_for_destination_address() {
        // Given
        let country1 = Country(code: "US", name: "United States", states: [])
        let country2 = Country(code: "IT", name: "Italy", states: [])
        insert(country1)
        insert(country2)

        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: nil, destinationAddress: nil, storageManager: storageManager)

        // When
        let filteredCountries = viewModel.filteredCountries(for: .destination)

        // Then
        XCTAssertEqual(filteredCountries.count, 2)
    }

    func test_customsFormRequired_returns_false_for_origin_and_destination_in_US() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "New York",
                                    state: "NY",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 29th Street #343",
                                         address2: nil,
                                         city: "San Francisco",
                                         state: "CA",
                                         postcode: "94121-2303",
                                         country: "US",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)

        // Then
        XCTAssertFalse(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_returns_true_for_military_state_origin() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "Milatry City",
                                    state: "AA",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 Hang Bong",
                                         address2: nil,
                                         city: "Hanoi",
                                         state: "",
                                         postcode: "94121-2303",
                                         country: "VN",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_returns_true_for_military_state_destination() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 Hang Bong",
                                    address2: nil,
                                    city: "Hanoi",
                                    state: "",
                                    postcode: "94121-2303",
                                    country: "VN",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 29th Street #343",
                                         address2: nil,
                                         city: "Milatry City",
                                         state: "AA",
                                         postcode: "94121-2303",
                                         country: "US",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customsFormRequired_returns_true_for_destination_country_different_from_origin_country() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "San Francisco",
                                    state: "CA",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 Hang Bong",
                                         address2: nil,
                                         city: "Hanoi",
                                         state: "",
                                         postcode: "94121-2303",
                                         country: "VN",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)

        // Then
        XCTAssertTrue(viewModel.customsFormRequired)
    }

    func test_customs_row_is_not_present_initially_if_both_origin_and_destination_countries_are_US() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "New York",
                                    state: "NY",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 29th Street #343",
                                         address2: nil,
                                         city: "San Francisco",
                                         state: "CA",
                                         postcode: "94121-2303",
                                         country: "US",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)

        // Then
        let firstSection = viewModel.state.sections.first
        XCTAssertNotNil(firstSection)
        XCTAssertNil(firstSection?.rows.first(where: { $0.type == .customs }))
    }

    func test_customs_row_is_present_initially_when_customs_form_is_required() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "New York",
                                    state: "NY",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 Hang Bong",
                                         address2: nil,
                                         city: "Hanoi",
                                         state: "",
                                         postcode: "94121-2303",
                                         country: "VN",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)

        // Then
        let firstSection = viewModel.state.sections.first
        XCTAssertNotNil(firstSection?.rows.first(where: { $0.type == .customs }))
    }

    func test_updateRowsForCustomsIfNeeded_removes_customs_row_when_destination_is_updated_to_US() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "New York",
                                    state: "NY",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 Hang Bong",
                                         address2: nil,
                                         city: "Hanoi",
                                         state: "",
                                         postcode: "94121-2303",
                                         country: "VN",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)
        let newAddress = MockShippingLabelAddress.sampleAddress(country: "US", state: "NY")
        viewModel.handleDestinationAddressValueChanges(address: newAddress, validated: true)

        // Then
        XCTAssertNil(viewModel.state.sections.first?.rows.first(where: { $0.type == .customs }))
    }

    func test_updateRowsForCustomsIfNeeded_adds_customs_row_when_destination_is_updated_to_nonUS() {
        // Given
        let originAddress = Address(firstName: "Skylar",
                                    lastName: "Ferry",
                                    company: "Automattic Inc.",
                                    address1: "60 29th Street #343",
                                    address2: nil,
                                    city: "New York",
                                    state: "NY",
                                    postcode: "94121-2303",
                                    country: "US",
                                    phone: nil,
                                    email: nil)
        let destinationAddress = Address(firstName: "Skylar",
                                         lastName: "Ferry",
                                         company: "Automattic Inc.",
                                         address1: "60 29th Street #343",
                                         address2: nil,
                                         city: "San Francisco",
                                         state: "CA",
                                         postcode: "94121-2303",
                                         country: "US",
                                         phone: nil,
                                         email: nil)

        // When
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: originAddress, destinationAddress: destinationAddress)
        let newAddress = MockShippingLabelAddress.sampleAddress(country: "VN", state: "")
        viewModel.handleDestinationAddressValueChanges(address: newAddress, validated: true)

        // Then
        XCTAssertNotNil(viewModel.state.sections.first?.rows.first(where: { $0.type == .customs }))
    }

    func test_updateRowsForCustomsIfNeeded_updates_row_states_correctly_when_phone_number_is_missing_in_both_origin_address_only() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: nil, destinationAddress: nil)
        viewModel.handleOriginAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "US", state: "CA"), validated: true)
        viewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "US", state: "NY"), validated: true)

        let rows = viewModel.state.sections.first?.rows
        XCTAssertEqual(rows?[0].dataState, .validated)
        XCTAssertEqual(rows?[0].displayMode, .editable)
        XCTAssertEqual(rows?[1].dataState, .validated)
        XCTAssertEqual(rows?[1].displayMode, .editable)
        XCTAssertEqual(rows?[2].dataState, .pending)
        XCTAssertEqual(rows?[2].displayMode, .editable)

        // When
        viewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(phone: "0987654321", country: "VN", state: ""),
                                                       validated: true)

        // Then
        let updatedRows = viewModel.state.sections.first?.rows
        XCTAssertEqual(updatedRows?[0].dataState, .pending)
        XCTAssertEqual(updatedRows?[0].displayMode, .editable)
        XCTAssertEqual(updatedRows?[1].dataState, .validated)
        XCTAssertEqual(updatedRows?[1].displayMode, .editable)
        XCTAssertEqual(updatedRows?[2].dataState, .pending)
        XCTAssertEqual(updatedRows?[2].displayMode, .disabled)
    }

    func test_updateRowsForCustomsIfNeeded_updates_row_states_correctly_when_phone_number_is_missing_in_both_origin_and_destination_addresses() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(), originAddress: nil, destinationAddress: nil)
        viewModel.handleOriginAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "US", state: "CA"), validated: true)
        viewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "US", state: "NY"), validated: true)

        let rows = viewModel.state.sections.first?.rows
        XCTAssertEqual(rows?[0].dataState, .validated)
        XCTAssertEqual(rows?[0].displayMode, .editable)
        XCTAssertEqual(rows?[1].dataState, .validated)
        XCTAssertEqual(rows?[1].displayMode, .editable)
        XCTAssertEqual(rows?[2].dataState, .pending)
        XCTAssertEqual(rows?[2].displayMode, .editable)

        // When
        viewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "VN", state: ""), validated: true)

        // Then
        let updatedRows = viewModel.state.sections.first?.rows
        XCTAssertEqual(updatedRows?[0].dataState, .pending)
        XCTAssertEqual(updatedRows?[0].displayMode, .editable)
        XCTAssertEqual(updatedRows?[1].dataState, .pending)
        XCTAssertEqual(updatedRows?[1].displayMode, .disabled)
        XCTAssertEqual(updatedRows?[2].dataState, .pending)
        XCTAssertEqual(updatedRows?[2].displayMode, .disabled)
    }

    func test_customsForms_returns_correctly_when_updating_selectedPackageID() {
        // Given
        let expectedProductID: Int64 = 123
        let orderItem = OrderItem.fake().copy(productID: expectedProductID)
        let order = MockOrders().makeOrder(items: [orderItem])
        let viewModel = ShippingLabelFormViewModel(order: order, originAddress: nil, destinationAddress: nil)

        // When
        viewModel.handleOriginAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(phone: "0123456789", country: "US"), validated: true)
        viewModel.handleDestinationAddressValueChanges(address: MockShippingLabelAddress.sampleAddress(country: "VN"), validated: true)
        let item = ShippingLabelPackageItem.fake(id: expectedProductID)
        let selectedPackage = ShippingLabelPackageAttributes(packageID: "Food Package", totalWeight: "55", items: [item])
        viewModel.handlePackageDetailsValueChanges(details: [selectedPackage])

        // Then
        let defaultForms = viewModel.customsForms
        XCTAssertEqual(defaultForms.count, 1)
        XCTAssertEqual(defaultForms.first?.packageID, selectedPackage.id)
        XCTAssertEqual(defaultForms.first?.items.count, 1)
        XCTAssertEqual(defaultForms.first?.items.first?.productID, expectedProductID)
        XCTAssertEqual(defaultForms.first?.items.first?.weight, item.weight)
        XCTAssertEqual(defaultForms.first?.items.first?.description, item.name)
        XCTAssertEqual(defaultForms.first?.items.first?.hsTariffNumber, "")
        XCTAssertEqual(defaultForms.first?.items.first?.value, item.value)
        XCTAssertEqual(defaultForms.first?.items.first?.originCountry, "")
    }

    func test_getDestinationAddress_uses_shipping_phone_if_available() {
        // Given
        let billingAddress = Address.fake().copy(phone: "555-555-5555")
        let shippingAddress = Address.fake().copy(phone: "333-333-3333")

        // When
        let viewModel = ShippingLabelFormViewModel(order: Order.fake().copy(billingAddress: billingAddress),
                                                   originAddress: nil,
                                                   destinationAddress: shippingAddress)

        // Then
        XCTAssertEqual(viewModel.destinationAddress?.phone, shippingAddress.phone)
    }

    func test_getDestinationAddress_uses_billing_phone_when_no_shipping_phone_available() {
        // Given
        let billingAddress = Address.fake().copy(phone: "555-555-5555")

        // When
        let viewModel = ShippingLabelFormViewModel(order: Order.fake().copy(billingAddress: billingAddress),
                                                   originAddress: nil,
                                                   destinationAddress: Address.fake())

        // Then
        XCTAssertEqual(viewModel.destinationAddress?.phone, billingAddress.phone)
    }
}

// MARK: - Utils
private extension ShippingLabelFormViewModelTests {
    func insert(_ readOnlyCountry: Yosemite.Country) {
        let country = storage.insertNewObject(ofType: StorageCountry.self)
        country.update(with: readOnlyCountry)
    }
}
