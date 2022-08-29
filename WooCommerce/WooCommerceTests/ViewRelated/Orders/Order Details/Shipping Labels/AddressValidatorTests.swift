import XCTest
import Yosemite
@testable import WooCommerce

/// AddressValidator Unit Tests
///
class AddressValidatorTests: XCTestCase {
    private var storesManager: MockStoresManager!

    private let validAddress = Address(firstName: "First name",
                                       lastName: "Last name",
                                       company: "Company name",
                                       address1: "Address one",
                                       address2: "Address two",
                                       city: "A city",
                                       state: "A State",
                                       postcode: "123456",
                                       country: "A Country",
                                       phone: "123456",
                                       email: "email@email.com"
    )

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(storesManager)
    }

    func testWhenAddressIsEmptyThenCompleteWithLocalFailure() {
        // Given
        var onCompletionWasCalled = false
        let addressValidator = AddressValidator(siteID: 123, stores: storesManager)

        // When
        addressValidator.validate(address: Address.empty, onlyLocally: true, onCompletion: { result in
            onCompletionWasCalled = true

            // Then
            guard let failure = result.failure else {
                XCTFail("A failure result was expected for an empty address")
                return
            }

            switch failure {
            case .local(let errorMessage):
                XCTAssertTrue(errorMessage.isNotEmpty)
                break
            default:
                XCTFail("A local failure was expected")
            }
        })

        XCTAssertTrue(onCompletionWasCalled)
    }

    func testWhenAddressIsValidAndValidationIsLocalOnlyThenCompleteWithSuccess() {
        // Given
        var onCompletionWasCalled = false
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self, thenCall: { action in
            if case let ShippingLabelAction.validateAddress(_, _, onCompletion) = action {
                onCompletion(.failure(ShippingLabelAddressValidationError(
                    addressError: "Shouldn't call remote validation",
                    generalError: "Shouldn't call remote validation"
                )))
            }
        })
        let addressValidator = AddressValidator(siteID: 123, stores: storesManager)

        // When
        addressValidator.validate(address: validAddress, onlyLocally: true, onCompletion: { result in
            onCompletionWasCalled = true

            // Then
            XCTAssertTrue(result.isSuccess)
        })

        XCTAssertTrue(onCompletionWasCalled)
    }

    func testWhenAddressIsValidThenCompleteWithSuccessWithLocalAndRemoteValidation() {
        // Given
        var onCompletionWasCalled = false
        var remoteValidationWasCalled = false
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self, thenCall: { action in
            if case let ShippingLabelAction.validateAddress(_, addressToBeValidated, onCompletion) = action {
                remoteValidationWasCalled = true
                onCompletion(.success(ShippingLabelAddressValidationSuccess(address: addressToBeValidated.address!, isTrivialNormalization: true)))
            }
        })
        let addressValidator = AddressValidator(siteID: 123, stores: storesManager)

        // When
        addressValidator.validate(address: validAddress, onlyLocally: false, onCompletion: { result in
            onCompletionWasCalled = true

            // Then
            XCTAssertTrue(result.isSuccess)
        })

        XCTAssertTrue(onCompletionWasCalled)
        XCTAssertTrue(remoteValidationWasCalled)
    }

    func testWhenAddressIsRemoteInvalidThenCompleteWithRemoteFailure() {
        // Given
        var onCompletionWasCalled = false
        var remoteValidationWasCalled = false
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self, thenCall: { action in
            if case let ShippingLabelAction.validateAddress(_, _, onCompletion) = action {
                remoteValidationWasCalled = true
                onCompletion(.failure(ShippingLabelAddressValidationError(
                    addressError: "Arbitrary remote validation error",
                    generalError: "Arbitrary remote validation error"
                )))
            }
        })
        let addressValidator = AddressValidator(siteID: 123, stores: storesManager)

        // When
        addressValidator.validate(address: validAddress, onlyLocally: false, onCompletion: { result in
            onCompletionWasCalled = true

            // Then
            guard let failure = result.failure else {
                XCTFail("A failure result was expected for an empty address")
                return
            }

            switch failure {
            case .remote(let error):
                XCTAssertTrue(error.addressError!.isNotEmpty)
                break
            default:
                XCTFail("A remote failure was expected")
            }
        })

        XCTAssertTrue(onCompletionWasCalled)
        XCTAssertTrue(remoteValidationWasCalled)
    }
}
