import XCTest
@testable import WooCommerce
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.POSProduct

final class LegacyCartViewModelTests: XCTestCase {

    private var sut: CartViewModel!
    private var posModel: PointOfSaleAggregateModel!

    override func setUp() {
        super.setUp()
        posModel = PointOfSaleAggregateModel(itemProvider: MockPOSItemProvider(),
                                             cardPresentPaymentService: MockCardPresentPaymentService(),
                                             orderService: MockPOSOrderService())
        sut = CartViewModel(posModel: posModel)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_removeItemFromCart() {
        /* TODO:
         https://github.com/woocommerce/woocommerce-ios/issues/13209
         The unique UUID for CartItem is set on init, but CartItem is only internal to addItemToCart()
         We need to extract this to a separate function and assure that ID's are correct,
         otherwise the UUID's for testing won't match
         */
    }

    func test_itemsInCartLabel_when_addItemToCart_then_label_updates_accordingly() {
        XCTAssertNil(sut.itemsInCartLabel, "Initial state")

        // Given
        let anItem = makeItem()
        let anotherItem = makeItem()

        // When/Then
        posModel.addToCart(anItem)
        XCTAssertEqual(sut.itemsInCartLabel, "1 item")

        posModel.addToCart(anotherItem)
        XCTAssertEqual(sut.itemsInCartLabel, "2 items")
    }
}

private func makeItem(name: String = "") -> POSItem {
    return POSProduct(itemID: UUID(),
                      productID: 0,
                      name: name,
                      price: "",
                      formattedPrice: "",
                      itemCategories: [],
                      productImageSource: nil,
                      productType: .simple)
}

import Testing

struct CartViewModelTests {
    let orderService: MockPOSOrderService
    let cardPresentPaymentService: MockCardPresentPaymentService
    let posModel: PointOfSaleAggregateModel
    let sut: CartViewModel

    init () async throws {
        let orderService = MockPOSOrderService()
        self.orderService = orderService
        let cardPresentPaymentService = MockCardPresentPaymentService()
        self.cardPresentPaymentService = cardPresentPaymentService
        let posModel = PointOfSaleAggregateModel(itemProvider: MockPOSItemProvider(),
                                                 cardPresentPaymentService: cardPresentPaymentService,
                                                 orderService: orderService)
        self.posModel = posModel
        sut = CartViewModel(posModel: posModel)
    }

    @Test func shouldPreventCartEditing_when_paymentState_idle_and_order_is_syncing() async throws {
        // Given

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: .syncing,
                                             paymentState: .idle) == true)
    }

    @Test func shouldPreventCartEditing_when_paymentState_cardPaymentSuccessful() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .cardPaymentSuccessful) == true)
    }

    @Test func shouldPreventCartEditing_when_paymentState_processingPayment() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .processingPayment) == true)
    }

    @Test func shouldPreventCartEditing_false_when_paymentState_acceptingCard() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .acceptingCard) == false)
    }

    @Test func shouldPreventCartEditing_false_when_paymentState_validatingOrderError() async throws {
        // Given
        let orderLoaded = PointOfSaleOrderState.loaded(PointOfSaleOrderTotals(
            cartTotal: "$10.00",
            orderTotal: "$12.00",
            taxTotal: "$2.00"))

        // When, Then
        #expect(sut.shouldPreventCartEditing(orderState: orderLoaded,
                                             paymentState: .validatingOrderError) == false)
    }

}
