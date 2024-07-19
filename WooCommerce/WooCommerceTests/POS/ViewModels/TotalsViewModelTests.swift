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
                                               currencyFormatter: .init(currencySettings: .init()))
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
        let order: Order = orderService.order(from: sut.order!)

        // When
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
        sut.startNewTransaction()

        // Then
        XCTAssertEqual(sut.paymentState, paymentState)
        XCTAssertNil(sut.order)
        XCTAssertNil(sut.cardPresentPaymentInlineMessage)
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
