import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelFormViewModelTests: XCTestCase {

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
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRate: MockShippingLabelCarrierRate.makeRate(),
                                                                     selectedSignatureRate: nil,
                                                                     selectedAdultSignatureRate: nil,
                                                                     editable: true)
        XCTAssertNotNil(shippingLabelFormViewModel.selectedRate)

        // When
        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertNil(shippingLabelFormViewModel.selectedRate)

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
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRate: MockShippingLabelCarrierRate.makeRate(),
                                                                     selectedSignatureRate: nil,
                                                                     selectedAdultSignatureRate: nil,
                                                                     editable: true)
        XCTAssertNotNil(shippingLabelFormViewModel.selectedRate)

        // When
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertNil(shippingLabelFormViewModel.selectedRate)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let row = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(row?.dataState, .pending)
        XCTAssertEqual(row?.displayMode, .disabled)
    }

    func test_handlePackageDetailsValueChanges_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageID = "my-package-id"
        let expectedPackageWeight = "55"

        // When
        shippingLabelFormViewModel.handlePackageDetailsValueChanges(selectedPackageID: expectedPackageID, totalPackageWeight: expectedPackageWeight)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.selectedPackageID, expectedPackageID)
        XCTAssertEqual(shippingLabelFormViewModel.totalPackageWeight, expectedPackageWeight)
    }

    func test_handlePackageDetailsValueChanges_reset_carrier_and_rates_selection() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageID = "my-package-id"
        let expectedPackageWeight = "55"

        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRate: MockShippingLabelCarrierRate.makeRate(),
                                                                     selectedSignatureRate: nil,
                                                                     selectedAdultSignatureRate: nil,
                                                                     editable: true)
        XCTAssertNotNil(shippingLabelFormViewModel.selectedRate)

        // When
        shippingLabelFormViewModel.handlePackageDetailsValueChanges(selectedPackageID: expectedPackageID, totalPackageWeight: expectedPackageWeight)

        // Then
        XCTAssertNil(shippingLabelFormViewModel.selectedRate)

        let rows = shippingLabelFormViewModel.state.sections.first?.rows
        let row = rows?.first { $0.type == .shippingCarrierAndRates }
        XCTAssertEqual(row?.dataState, .pending)
        XCTAssertEqual(row?.displayMode, .editable)
    }

    func test_handleCarrierAndRatesValueChanges_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        XCTAssertNil(shippingLabelFormViewModel.selectedRate)
        XCTAssertNil(shippingLabelFormViewModel.selectedSignatureRate)
        XCTAssertNil(shippingLabelFormViewModel.selectedAdultSignatureRate)

        // When
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRate: MockShippingLabelCarrierRate.makeRate(),
                                                                     selectedSignatureRate: MockShippingLabelCarrierRate.makeRate(title: "UPS"),
                                                                     selectedAdultSignatureRate: nil,
                                                                     editable: true)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.selectedRate, MockShippingLabelCarrierRate.makeRate())
        XCTAssertEqual(shippingLabelFormViewModel.selectedSignatureRate, MockShippingLabelCarrierRate.makeRate(title: "UPS"))
        XCTAssertNil(shippingLabelFormViewModel.selectedAdultSignatureRate)
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

    func test_validateAddress_returns_validation_error_when_missing_name() {
        // Given
        let expectedValidationError = ShippingLabelAddressValidationError(addressError: nil, generalError: "Name is required")
        let originAddress = Address.fake()
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: originAddress,
                                                                    destinationAddress: nil)

        // When
        shippingLabelFormViewModel.validateAddress(type: .origin) { validationState, validationSuccess in
            guard case let .validationError(error) = validationState else {
                XCTFail("Validation error was not returned")
                return
            }
            XCTAssertEqual(error, expectedValidationError)
        }
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
}
