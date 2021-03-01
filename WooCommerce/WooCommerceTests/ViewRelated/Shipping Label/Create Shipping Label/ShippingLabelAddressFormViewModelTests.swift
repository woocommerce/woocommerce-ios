import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelAddressFormViewModelTests: XCTestCase {

    func test_handleAddressValueChanges_returns_updated_ShippingLabelAddress() {

        // Given
        let shippingAddress = MockShippingLabelAddress.sampleAddress()
        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress)

        // When
        viewModel.handleAddressValueChanges(row: .name, newValue: "Skylar Ferry")
        viewModel.handleAddressValueChanges(row: .company, newValue: "Automattic Inc.")
        viewModel.handleAddressValueChanges(row: .phone, newValue: "12345")
        viewModel.handleAddressValueChanges(row: .country, newValue: "United States")
        viewModel.handleAddressValueChanges(row: .state, newValue: "CA")
        viewModel.handleAddressValueChanges(row: .address, newValue: "60 29th")
        viewModel.handleAddressValueChanges(row: .address2, newValue: "Street #343")
        viewModel.handleAddressValueChanges(row: .city, newValue: "San Francisco")
        viewModel.handleAddressValueChanges(row: .postcode, newValue: "94121-2303")

        // Then
        XCTAssertEqual(viewModel.address?.name, "Skylar Ferry")
        XCTAssertEqual(viewModel.address?.company, "Automattic Inc.")
        XCTAssertEqual(viewModel.address?.phone, "12345")
        XCTAssertEqual(viewModel.address?.country, "United States")
        XCTAssertEqual(viewModel.address?.state, "CA")
        XCTAssertEqual(viewModel.address?.address1, "60 29th")
        XCTAssertEqual(viewModel.address?.address2, "Street #343")
        XCTAssertEqual(viewModel.address?.city, "San Francisco")
        XCTAssertEqual(viewModel.address?.postcode, "94121-2303")
    }

    func test_sections_are_returned_correctly_if_there_are_no_errors() {
        // Given
        let shippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                   name: "Skylar Ferry",
                                                   phone: "12345",
                                                   country: "United States",
                                                   state: "CA",
                                                   address1: "60 29th",
                                                   address2: "Street #343",
                                                   city: "San Francisco",
                                                   postcode: "94121-2303")

        // When
        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress)

        // Then
        let expectedRows: [ShippingLabelAddressFormViewModel.Row] = [.name, .company, .phone, .address, .address2, .city, .postcode, .state, .country]
        XCTAssertEqual(viewModel.sections, [ShippingLabelAddressFormViewModel.Section(rows: expectedRows)])
    }

    func test_sections_are_returned_correctly_if_an_address_validation_error_occurs() {
        // Given
        let shippingAddress = MockShippingLabelAddress.sampleAddress()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let validationError = ShippingLabelAddressValidationError(addressError: "Error", generalError: nil)
        let expectedValidationResponse = ShippingLabelAddressValidationResponse(address: nil,
                                                                                errors: validationError,
                                                                                isTrivialNormalization: nil)

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .validateAddress(_, _, onCompletion):
                onCompletion(.success(expectedValidationResponse))
            default:
                break
            }
        }

        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress, stores: stores)
        viewModel.validateAddress()

        // Then
        let expectedRows: [ShippingLabelAddressFormViewModel.Row] = [.name,
                                                                     .company,
                                                                     .phone,
                                                                     .address,
                                                                     .fieldError,
                                                                     .address2,
                                                                     .city,
                                                                     .postcode,
                                                                     .state,
                                                                     .country]
        XCTAssertEqual(viewModel.sections, [ShippingLabelAddressFormViewModel.Section(rows: expectedRows)])
    }

    func test_address_validation_returns_correct_values_if_succeeded() {
        // Given
        let shippingAddress = MockShippingLabelAddress.sampleAddress()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let expectedValidationResponse = ShippingLabelAddressValidationResponse(address: shippingAddress,
                                                                                errors: nil,
                                                                                isTrivialNormalization: true)

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .validateAddress(_, _, onCompletion):
                onCompletion(.success(expectedValidationResponse))
            default:
                break
            }
        }

        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress, stores: stores)
        viewModel.validateAddress()

        // Then
        XCTAssertEqual(viewModel.isAddressValidated, true)
        XCTAssertEqual(viewModel.addressValidationError, nil)
    }

    func test_address_validation_returns_correct_values_if_the_validation_fails() {
        // Given
        let shippingAddress = MockShippingLabelAddress.sampleAddress()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let validationError = ShippingLabelAddressValidationError(addressError: "Error", generalError: nil)
        let expectedValidationResponse = ShippingLabelAddressValidationResponse(address: nil,
                                                                                errors: validationError,
                                                                                isTrivialNormalization: nil)

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .validateAddress(_, _, onCompletion):
                onCompletion(.success(expectedValidationResponse))
            default:
                break
            }
        }

        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress, stores: stores)
        viewModel.validateAddress()

        // Then
        XCTAssertEqual(viewModel.isAddressValidated, false)
        XCTAssertEqual(viewModel.addressValidationError, validationError)
    }

    func test_address_validation_returns_correct_values_if_the_validation_returns_an_error() {
        // Given
        let shippingAddress = MockShippingLabelAddress.sampleAddress()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let error = SampleError.first

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .validateAddress(_, _, onCompletion):
                onCompletion(.failure(error))
            default:
                break
            }
        }

        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress, stores: stores)
        viewModel.validateAddress()

        // Then
        let validationError = ShippingLabelAddressValidationError(addressError: nil, generalError: error.localizedDescription)
        XCTAssertEqual(viewModel.isAddressValidated, false)
        XCTAssertEqual(viewModel.addressValidationError, validationError)
    }

    func test_address_validation_toggle_shouldShowTopBannerView() {
        // Given
        let shippingAddress = MockShippingLabelAddress.sampleAddress()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let expectedValidationResponse = ShippingLabelAddressValidationResponse(address: shippingAddress,
                                                                                errors: nil,
                                                                                isTrivialNormalization: true)

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .validateAddress(_, _, onCompletion):
                DispatchQueue.main.async {
                    onCompletion(.success(expectedValidationResponse))
                }
            default:
                break
            }
        }

        let viewModel = ShippingLabelAddressFormViewModel(siteID: 10, type: .origin, address: shippingAddress, stores: stores)
        viewModel.validateAddress()

        // Then
        XCTAssertTrue(viewModel.showLoadingIndicator)
        waitUntil { () -> Bool in
            !viewModel.showLoadingIndicator
        }
    }
}
