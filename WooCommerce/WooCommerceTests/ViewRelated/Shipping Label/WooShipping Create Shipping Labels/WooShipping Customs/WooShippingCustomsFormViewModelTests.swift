import XCTest
import Yosemite
@testable import WooCommerce

class WooShippingCustomsFormViewModelTests: XCTestCase {
    private var viewModel: WooShippingCustomsFormViewModel!

    override func setUp() {
        super.setUp()

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake(), onCompletion: { _ in })
    }

    override func tearDown() {
        super.tearDown()

        viewModel = nil
    }

    func test_onDismiss_calls_onCompletion_with_right_values() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { form in
            passedForm = form
        })

        viewModel.internationalTransactionNumber = "NOEEI 30.37(a)"
        viewModel.returnToSenderIfNotDelivered = false
        viewModel.contentType = .other
        viewModel.contentExplanation = "explanation test"
        viewModel.restrictionType = .other
        viewModel.restrictionDetails = "restriction details"

        viewModel.itemsViewModels.first?.description = "Test Item"
        viewModel.itemsViewModels.first?.valuePerUnit = "10"
        viewModel.itemsViewModels.first?.weightPerUnit = "5"
        viewModel.itemsViewModels.first?.hsTariffNumber = "123456"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertEqual(passedForm?.restrictionType, .other)
        XCTAssertEqual(passedForm?.restrictionComments, viewModel.restrictionDetails)
        XCTAssertEqual(passedForm?.contentsType, .other)
        XCTAssertEqual(passedForm?.contentExplanation, viewModel.contentExplanation)
        XCTAssertEqual(passedForm?.itn, viewModel.internationalTransactionNumber)
        XCTAssertEqual(passedForm?.nonDeliveryOption, .abandon)

        XCTAssertEqual(passedForm?.items.count, orderItems.count)
        XCTAssertEqual(passedForm?.items.first?.productID, orderItems.first?.productID)
        XCTAssertEqual(passedForm?.items.first?.quantity, orderItems.first?.quantity)
        XCTAssertEqual(passedForm?.items.first?.description, viewModel.itemsViewModels.first?.description)
        XCTAssertEqual(passedForm?.items.first?.value, Double(viewModel.itemsViewModels.first?.valuePerUnit ?? "0"))
        XCTAssertEqual(passedForm?.items.first?.weight, Double(viewModel.itemsViewModels.first?.weightPerUnit ?? "0"))
        XCTAssertEqual(passedForm?.items.first?.hsTariffNumber, viewModel.itemsViewModels.first?.hsTariffNumber)
    }

    func test_onDismiss_when_calls_onCompletion_with_invalid_hsTariffNumber_then_returns_empty() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { form in
            passedForm = form
        })

        viewModel.itemsViewModels.first?.hsTariffNumber = "12"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertTrue(passedForm?.items.first?.hsTariffNumber.isEmpty ?? false)
    }

    func test_onDismiss_when_calls_onCompletion_with_content_and_restriction_not_other_then_returns_empty() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { form in
            passedForm = form
        })

        viewModel.contentType = .documents
        viewModel.contentExplanation = "content explanation"

        viewModel.restrictionType = .quarantine
        viewModel.restrictionDetails = "restriction details"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertEqual(passedForm?.contentsType, .documents)
        XCTAssertEqual(passedForm?.restrictionType, .quarantine)
        XCTAssertEqual(passedForm?.contentExplanation, "")
        XCTAssertEqual(passedForm?.restrictionComments, "")
    }

    func test_onDismiss_when_calls_onCompletion_with_invalid_itn_then_returns_empty() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { form in
            passedForm = form
        })

        viewModel.internationalTransactionNumber = "1234"

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertTrue(passedForm?.itn.isEmpty ?? false)
    }

    func test_init_passes_right_currency() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        // When
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(currency: "USD", items: orderItems), onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.itemsViewModels.first?.currencySymbol, "$")
    }

    func test_itnValidationError_returns_invalidFormat_for_invalid_values() {
        // Given
        let invalidValues = [
            "AES X123456789012346",
            "NOEEI 30.37(a))",
            "INVALID 123456",
            "AES X123@#4567890"
        ]

        // When & Then
        for invalidValue in invalidValues {
            viewModel.internationalTransactionNumber = invalidValue
            XCTAssertEqual(viewModel.itnValidationError, .invalidFormat)
        }
    }

    func test_itnValidationError_when_item_view_models_hsTariffNumberTotalValue_is_nil() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(currency: "USD", currencySymbol: "$", items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels.forEach { item in
            item.hsTariffNumber = ""
        }

        // Then
        XCTAssertNil(viewModel.itnValidationError)

        // When
        viewModel.itemsViewModels.forEach { item in
            item.valuePerUnit = "1300"
        }

        // Then
        XCTAssertEqual(viewModel.itnValidationError, .missingForTotalShipmentValue)
    }

    func test_itnValidationError_when_item_view_models_hsTariffNumberTotalValue_is_less_than_2500() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels.first?.hsTariffNumberTotalValue = ("123456", 1000)

        // Then
        XCTAssertNil(viewModel.itnValidationError)
    }

    func test_itnValidationError_when_item_view_models_hsTariffNumberTotalValue_is_more_than_2500() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels[0].requiredInformationIsEntered = true
        viewModel.itemsViewModels[0].hsTariffNumberTotalValue = ("123456", 1000)
        viewModel.itemsViewModels[1].hsTariffNumberTotalValue = ("123456", 2000)
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.internationalTransactionNumber = ""
        viewModel.updateDestinationCountry(code: "CA") // ITN is not required for Canada

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
        XCTAssertNil(viewModel.itnValidationError)

        // When
        viewModel.updateDestinationCountry(code: "UK")

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
        XCTAssertEqual(viewModel.itnValidationError, .missingForTariffClass)
    }

    func test_itnValidationError_when_destination_country_requires_ITN() {
        // Given
        let requiredDestinations = ["IR", "SY", "KP", "CU", "SD"]
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2)]
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })
        viewModel.itemsViewModels.forEach { item in
            item.hsTariffNumber = ""
            item.valuePerUnit = "1000"
        }

        // When
        viewModel.updateDestinationCountry(code: "UK")

        // Then
        XCTAssertNil(viewModel.itnValidationError)

        // When
        for destination in requiredDestinations {
            viewModel.updateDestinationCountry(code: destination)

            // Then
            XCTAssertEqual(viewModel.itnValidationError, .missingForRequiredDestination)
        }
    }

    func test_requiredInformationIsEntered_when_itn_is_required_but_invalid_then_returns_false() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.internationalTransactionNumber = "1234"

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_itn_is_required_and_valid_then_returns_true() {
        // Given
        let orderItems = [MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.internationalTransactionNumber = "NOEEI 30.37(a)"
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_content_type_is_other_but_details_are_empty_then_returns_false() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.contentType = .other
        viewModel.contentExplanation = ""

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_restriction_type_is_other_but_details_are_empty_then_returns_false() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.restrictionType = .other
        viewModel.restrictionDetails = ""

        // Then
        XCTAssertFalse(viewModel.requiredInformationIsEntered)
    }

    func test_requiredInformationIsEntered_when_required_data_is_entered_then_returns_true() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { _ in })

        // When
        viewModel.itemsViewModels.first?.requiredInformationIsEntered = true
        viewModel.itemsViewModels[1].requiredInformationIsEntered = true
        viewModel.restrictionType = .other
        viewModel.restrictionDetails = "test"
        viewModel.contentType = .other
        viewModel.contentExplanation = "test"
        viewModel.internationalTransactionNumber = "NOEEI 30.37(a)"

        // Then
        XCTAssertTrue(viewModel.requiredInformationIsEntered)
    }
}
