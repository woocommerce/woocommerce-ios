import XCTest
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import protocol Yosemite.POSOrderServiceProtocol

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
    func test_startNewTransaction() {
        // Given

        let paymentState: TotalsViewModel.PaymentState = .acceptingCard
        // When

        sut.startNewTransaction()

        // Then
        XCTAssertEqual(sut.paymentState, paymentState)
        XCTAssertNil(sut.order)
        XCTAssertNil(sut.cardPresentPaymentInlineMessage)
    }
}
