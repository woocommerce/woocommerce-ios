import XCTest
import Yosemite
@testable import WooCommerce

class WooShippingCustomsFormViewModelTests: XCTestCase {
    private var viewModel: WooShippingCustomsFormViewModel!

    func test_onDismiss_calls_onCompletion_with_right_values() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        var passedForm: ShippingLabelCustomsForm?
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(items: orderItems), onCompletion: { form in
            passedForm = form
        })

        viewModel.restrictionType = .quarantine
        viewModel.contentType = .gift
        viewModel.internationalTransactionNumber = "1234"
        viewModel.returnToSenderIfNotDelivered = false

        viewModel.itemsViewModels.first?.description = "Test Item"
        viewModel.itemsViewModels.first?.valuePerUnit = "10"
        viewModel.itemsViewModels.first?.weightPerUnit = "5"
        viewModel.itemsViewModels.first?.hsTariffNumber = "123456"
        viewModel.itemsViewModels.first?.originCountry = WooShippingCustomsCountry(code: "US", name: "United States")

        // When
        viewModel.onDismiss()

        // Then
        XCTAssertEqual(passedForm?.restrictionType, .quarantine)
        XCTAssertEqual(passedForm?.contentsType, .gift)
        XCTAssertEqual(passedForm?.itn, viewModel.internationalTransactionNumber)
        XCTAssertEqual(passedForm?.nonDeliveryOption, .abandon)

        XCTAssertEqual(passedForm?.items.count, orderItems.count)
        XCTAssertEqual(passedForm?.items.first?.productID, orderItems.first?.productID)
        XCTAssertEqual(passedForm?.items.first?.quantity, orderItems.first?.quantity)
        XCTAssertEqual(passedForm?.items.first?.description, viewModel.itemsViewModels.first?.description)
        XCTAssertEqual(passedForm?.items.first?.value, Double(viewModel.itemsViewModels.first?.valuePerUnit ?? "0"))
        XCTAssertEqual(passedForm?.items.first?.weight, Double(viewModel.itemsViewModels.first?.weightPerUnit ?? "0"))
        XCTAssertEqual(passedForm?.items.first?.hsTariffNumber, viewModel.itemsViewModels.first?.hsTariffNumber)
        XCTAssertEqual(passedForm?.items.first?.originCountry, viewModel.itemsViewModels.first?.originCountry.name)
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

    func test_init_passes_right_currency() {
        // Given
        let orderItems = [MockOrderItem.sampleItem(productID: 123, quantity: 2), MockOrderItem.sampleItem()]

        // When
        viewModel = WooShippingCustomsFormViewModel(order: Order.fake().copy(currency: "USD", items: orderItems), onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.itemsViewModels.first?.currencySymbol, "$")
    }
}
