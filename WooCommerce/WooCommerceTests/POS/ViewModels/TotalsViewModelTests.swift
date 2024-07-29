import XCTest
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import protocol Yosemite.POSOrderServiceProtocol
@testable import struct Yosemite.Order
@testable import struct Yosemite.POSProduct
@testable import protocol Yosemite.POSItem

final class TotalsViewModelTests: XCTestCase {

    private var sut: TotalsViewModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var orderService: POSOrderServiceProtocol!

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        orderService = POSOrderPreviewService()
        sut = TotalsViewModel(orderService: orderService,
                              cardPresentPaymentService: cardPresentPaymentService,
                              currencyFormatter: .init(currencySettings: .init()),
                              paymentState: .acceptingCard,
                              isSyncingOrder: false)
    }
    func test_isSyncingOrder() {}
    func test_startSyncOrder() {}
    func test_stopSyncOrder() {}
    func test_order() {}
    func test_formattedPrice() {}
    func test_formattedOrderTotalPrice() {}
    func test_formattedOrderTotalTaxPrice() {}
    func test_areAmountsFullyCalculated() {}
    func test_clearOrder() {
        // When
        sut.clearOrder()

        // Then
        XCTAssertNil(sut.order)
    }
    func test_setOrder() {}
    func test_startNewTransaction_after_collecting_payment() async throws {
        // Given
        let paymentState: TotalsViewModel.PaymentState = .acceptingCard
        let item = Self.makeItem()

        await sut.syncOrder(for: [CartItem(id: UUID(), item: item, quantity: 1)], allItems: [item])
        XCTAssertNotNil(sut.order)

        // When
        guard let order = sut.order else {
            return XCTFail("Expected order. Got nothing")
        }
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
        sut.startNewTransaction()

        // Then
        XCTAssertEqual(sut.paymentState, paymentState)
        XCTAssertNil(sut.order)
        XCTAssertNil(sut.cardPresentPaymentInlineMessage)
    }

    func test_isShowingCardPresentPaymentStatus_when_order_syncing_then_false() {
        // Given
        sut.isSyncingOrder = true

        // Then
        XCTAssertFalse(sut.isShowingCardPresentPaymentStatus)
    }


    func test_isShowingCardPresentPaymentStatus_when_connected_and_payment_message_exists_then_true() {
        // Given
        sut.isSyncingOrder = false
        cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .preparingForPayment(cancelPayment: {}))

        // Then
        XCTAssertTrue(sut.isShowingCardPresentPaymentStatus)
    }

    func test_isShowingCardPresentPaymentStatus_when_connected_and_no_payment_message_then_false() {
        // Given
        sut.isSyncingOrder = false
        cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        cardPresentPaymentService.paymentEvent = .idle

        // Then
        XCTAssertFalse(sut.isShowingCardPresentPaymentStatus)
    }
}

private extension TotalsViewModelTests {
    static func makeItem() -> POSItem {
        return POSProduct(itemID: UUID(),
                          productID: 0,
                          name: "",
                          price: "",
                          formattedPrice: "",
                          itemCategories: [],
                          productImageSource: nil,
                          productType: .simple)
    }
}
