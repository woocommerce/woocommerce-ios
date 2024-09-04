import XCTest
import Combine
@testable import WooCommerce
@testable import class Yosemite.POSOrderService
@testable import protocol Yosemite.POSOrderServiceProtocol
@testable import struct Yosemite.Order
@testable import struct Yosemite.POSProduct
@testable import protocol Yosemite.POSItem
@testable import struct Yosemite.OrderItem

final class TotalsViewModelTests: XCTestCase {

    private var sut: TotalsViewModel!
    private var cardPresentPaymentService: MockCardPresentPaymentService!
    private var orderService: MockPOSOrderService!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        cardPresentPaymentService = MockCardPresentPaymentService()
        orderService = MockPOSOrderService()
        sut = TotalsViewModel(orderService: orderService,
                              cardPresentPaymentService: cardPresentPaymentService,
                              currencyFormatter: .init(currencySettings: .init()),
                              paymentState: .acceptingCard)
        cancellables = Set()
    }
    func test_on_checkOutTapped_startSyncOrder() {}
    func test_stopSyncOrder() {}
    func test_order() {}
    func test_formattedPrice() {}
    func test_formattedOrderTotalPrice() {}
    func test_formattedOrderTotalTaxPrice() {}
    func test_clearOrder() {
        // When
        sut.clearOrder()

        // Then
        XCTAssertNil(sut.order)
    }
    func test_setOrder() {}
    func test_startNewOrder_after_collecting_payment() async throws {
        // Given
        let paymentState: TotalsViewModel.PaymentState = .acceptingCard
        let item = Self.makeItem()

        orderService.orderToReturn = Order.fake()

        await sut.syncOrder(for: [CartItem(id: UUID(), item: item, quantity: 1)], allItems: [item])
        XCTAssertNotNil(sut.order)

        var startNewOrderEventWasPublished = false
        sut.startNewOrderActionPublisher.sink { _ in
            startNewOrderEventWasPublished = true
        }.store(in: &cancellables)
        XCTAssertFalse(startNewOrderEventWasPublished)

        // When
        guard let order = sut.order else {
            return XCTFail("Expected order. Got nothing")
        }
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth)
        sut.startNewOrder()

        // Then
        XCTAssertTrue(startNewOrderEventWasPublished)
        XCTAssertEqual(sut.paymentState, paymentState)
        XCTAssertNil(sut.order)
        XCTAssertNil(sut.cardPresentPaymentInlineMessage)
    }

    func test_isShowingCardReaderStatus_when_order_not_loaded_then_false() async {
        // Given
        sut = TotalsViewModel(orderService: orderService,
                              cardPresentPaymentService: cardPresentPaymentService,
                              currencyFormatter: .init(currencySettings: .init()),
                              paymentState: .acceptingCard)
        orderService.orderToReturn = nil

        await sut.syncOrder(for: [], allItems: [])

        // Then
        XCTAssertFalse(sut.isShowingCardReaderStatus)
    }

    func test_isShowingCardReaderStatus_when_connected_and_payment_message_exists_then_true() async throws {
        // Given
        orderService.orderToReturn = Order.fake()
        cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .preparingForPayment(cancelPayment: {}))

        let item = Self.makeItem()
        await sut.syncOrder(for: [CartItem(id: UUID(), item: item, quantity: 1)], allItems: [item])

        // Then
        XCTAssertTrue(sut.isShowingCardReaderStatus)
    }

    func test_isShowingCardReaderStatus_when_connected_and_no_payment_message_then_false() {
        // Given
        cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        cardPresentPaymentService.paymentEvent = .idle

        // Then
        XCTAssertFalse(sut.isShowingCardReaderStatus)
    }

    func test_isShowingTotalsFields_when_payment_processing_then_false() {
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .processing)

        XCTAssertFalse(sut.isShowingTotalsFields)
    }

    func test_isShowingTotalsFields_when_payment_successful_then_false() {
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        XCTAssertFalse(sut.isShowingTotalsFields)
    }

    func test_isShowingTotalsFields_when_preparing_for_reader_then_true() {
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .preparingForPayment(cancelPayment: {}))

        XCTAssertTrue(sut.isShowingTotalsFields)
    }

    func test_when_a_reader_connects_collectPayment_is_attempted() async {
        // Given
        orderService.orderToReturn = Order.fake().copy(items: [OrderItem.fake()])
        await sut.syncOrder(for: [], allItems: [])

        waitFor { promise in
            self.cardPresentPaymentService.onCollectPaymentCalled = {
                // Then
                promise(())
            }
            // When
            self.cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
        }
    }

    func test_if_a_reader_is_already_connected_collectPayment_is_attempted_immediately() async {
        // Given
        cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)

        orderService.orderToReturn = Order.fake().copy(items: [OrderItem.fake()])
        await sut.syncOrder(for: [], allItems: [])

        waitFor { promise in
            self.cardPresentPaymentService.onCollectPaymentCalled = {
                // Then
                promise(())
            }
            // When
            self.sut.checkOutTapped(with: [], allItems: [])
        }
    }

    func test_cardPresentPaymentInlineMessage_when_paymentSuccess_then_total_set() async {
        // Given
        orderService.orderToReturn = Order.fake().copy(currency: "$", total: "52.30")
        await sut.syncOrder(for: [], allItems: [])

        // When
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentSuccess(done: { }))
        let message = sut.cardPresentPaymentInlineMessage

        // Then
        if case .paymentSuccess(let viewModel) = message {
            XCTAssertEqual(viewModel.title, "Payment successful")
            XCTAssertEqual(viewModel.message, "A payment of $52.30 was successfully made")
        } else {
            XCTFail("Expected cardPresentPaymentInlineMessage to be paymentSuccess")
        }
    }


    func test_orderState_when_syncOrder_succeeds_then_syncing_and_loaded() async {
        // Given sync order succeeds
        let expectation = XCTestExpectation(description: "OrderState should change 2 times when syncing order")
        orderService.orderToReturn = Order.fake()

        // When we sync order
        var orderStates: [TotalsViewModel.OrderState] = []
        sut.orderStatePublisher
            .collect(3)
            .sink { orderState in
                orderStates.append(contentsOf: orderState)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        await sut.syncOrder(for: [], allItems: [])
        await fulfillment(of: [expectation], timeout: 1)

        // Then OrderState changes from idle to syncing to loaded
        XCTAssertEqual(orderStates, [.idle, .syncing, .loaded])
    }

    func test_orderState_when_syncOrder_fails_then_syncing_and_error() async {
        // Given sync order fails
        let expectation = XCTestExpectation(description: "OrderState should change 2 times when syncing order")
        orderService.orderToReturn = nil

        // When we sync order
        var orderStates: [TotalsViewModel.OrderState] = []
        sut.orderStatePublisher
            .collect(3)
            .sink { orderState in
                orderStates.append(contentsOf: orderState)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        await sut.syncOrder(for: [], allItems: [])
        await fulfillment(of: [expectation], timeout: 1)

        // Then OrderState changes from idle to syncing to error
        XCTAssertEqual(orderStates, [.idle, .syncing, .error(.init(message: "", handler: {}))])
    }

    func test_when_reader_reconnects_on_TotalsView_reader_is_prepared_for_payment() async {
        // Given a reader has been connected, with the order synced, on the TotalsView
        sut.startShowingTotalsView()
        cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        orderService.orderToReturn = Order.fake()
        await sut.syncOrder(for: [], allItems: [])
        // And that reader has subsequently disconnected
        await cardPresentPaymentService.disconnectReader()

        let collectPaymentCalled = waitFor { promise in
            // Then the reader is prepared for payment
            self.cardPresentPaymentService.onCollectPaymentCalled = {
                promise(true)
            }

            // When a reader reconnects
            self.cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        }

        XCTAssertTrue(collectPaymentCalled)
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
