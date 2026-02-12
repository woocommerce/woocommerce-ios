import Testing
import Foundation
import Combine
import struct Yosemite.Order
import protocol Yosemite.PaymentCaptureCelebrationProtocol
@testable import PointOfSale

struct POSPaymentModelTests {

    // MARK: - Init

    @Test("init sets payment state to idle by default")
    @MainActor
    func init_sets_paymentState_to_idle() {
        let sut = makePaymentController()
        #expect(sut.paymentState == .idle)
    }

    // MARK: - Start Payment

    @Test("startPayment collects card payment when reader is connected")
    @MainActor
    func startPayment_whenReaderConnected_collectsCardPayment() async {
        let service = MockCardPresentPaymentService()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")

        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        #expect(service.collectPaymentWasCalled == true)
    }

    @Test("startPayment collects on reader connect when reader is disconnected")
    @MainActor
    func startPayment_whenReaderDisconnected_collectsOnConnect() async {
        let service = MockCardPresentPaymentService()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        // Not called yet since reader is disconnected
        #expect(service.collectPaymentWasCalled == false)

        // Connect the reader and wait for the Combine chain to trigger collectPayment
        await withCheckedContinuation { continuation in
            service.onCollectPaymentCalled = {
                continuation.resume()
            }
            service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        }

        #expect(service.collectPaymentWasCalled == true)
    }

    // MARK: - Cash Payment

    @Test("startCashPayment cancels card payment and transitions to cash")
    @MainActor
    func startCashPayment_cancelsCardAndTransitionsToCash() async {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        await sut.startCashPayment()

        #expect(service.cancelPaymentCalled == true)
        #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .collectingCash))
    }

    @Test("cancelCashPayment resets to idle")
    @MainActor
    func cancelCashPayment_resetsToIdle() async {
        let sut = makePaymentController()

        await sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        await sut.cancelCashPayment()
        #expect(sut.paymentState.cash == .idle)
    }

    @Test("collectCashPayment calls handler and transitions to success")
    @MainActor
    func collectCashPayment_callsHandlerAndTransitionsToSuccess() async throws {
        let cashHandler = MockPOSCashPaymentHandler()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake()
        let celebration = MockPaymentCaptureCelebration()

        let sut = makePaymentController(
            orderProvider: orderProvider,
            cashPaymentHandler: cashHandler,
            celebration: celebration)

        try await sut.collectCashPayment(changeDueAmount: "$5.00")

        #expect(cashHandler.completeCashPaymentCalled == true)
        #expect(cashHandler.completeCashPaymentReceivedChangeDue == "$5.00")
        #expect(sut.paymentState.cash == .paymentSuccess)
        #expect(celebration.celebrationWasCalled == true)
    }

    @Test("collectCashPayment runs post-payment step")
    @MainActor
    func collectCashPayment_runsPostPaymentStep() async throws {
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake()
        var postPaymentStepCalled = false

        let sut = makePaymentController(
            orderProvider: orderProvider,
            postPaymentStep: { postPaymentStepCalled = true })

        try await sut.collectCashPayment(changeDueAmount: nil)

        #expect(postPaymentStepCalled == true)
    }

    // MARK: - Receipt

    @Test("sendReceipt sends to receipt sender with current order")
    @MainActor
    func sendReceipt_sendsToReceiptSender() async throws {
        let receiptSender = MockPOSReceiptSender()
        let orderProvider = MockPOSPaymentOrderProvider()
        let order = Order.fake().copy(orderID: 123, total: "10.00")
        orderProvider.orderToReturn = order

        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            receiptSender: receiptSender)

        // Collect a payment to set the currentOrder
        await sut.startPayment()

        try await sut.sendReceipt(to: "test@example.com")

        #expect(receiptSender.sendReceiptWasCalled == true)
        #expect(receiptSender.sendReceiptCalledWithOrderID == 123)
        #expect(receiptSender.sendReceiptCalledWithEmail == "test@example.com")
    }

    @Test("sendReceipt throws when no current order")
    @MainActor
    func sendReceipt_throwsWhenNoCurrentOrder() async {
        let sut = makePaymentController()

        await #expect(throws: POSPaymentError.self) {
            try await sut.sendReceipt(to: "test@example.com")
        }
    }

    // MARK: - Reset

    @Test("reset clears all state")
    @MainActor
    func reset_clearsAllState() async {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(
            cardPresentPaymentService: service,
            paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle))

        // Set up some inline message
        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        sut.reset()

        #expect(sut.paymentState == .idle)
        #expect(sut.cardPresentPaymentInlineMessage == nil)
    }

    // MARK: - Combine Chains

    @Test("payment event publisher updates card payment state")
    @MainActor
    func paymentEventPublisher_updatesCardPaymentState() {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("payment event publisher updates inline message")
    @MainActor
    func paymentEventPublisher_updatesInlineMessage() {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        guard case .paymentSuccess = sut.cardPresentPaymentInlineMessage else {
            Issue.record("Expected paymentSuccess inline message")
            return
        }
    }

    @Test("reader connection publisher updates connection status")
    @MainActor
    func readerConnectionPublisher_updatesConnectionStatus() {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        #expect(sut.cardReaderConnectionStatus == .disconnected)

        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.85)

        #expect(sut.cardReaderConnectionStatus != .disconnected)
    }

    // MARK: - Configuration Actions

    @Test("capture error exit action uses configuration")
    @MainActor
    func captureErrorExitAction_usesConfiguration() async {
        var exitActionCalled = false
        let service = MockCardPresentPaymentService()

        let config = POSPaymentFlowConfiguration.cart(
            onNewOrder: { exitActionCalled = true },
            onEditOrder: {})

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            configuration: config)

        // Trigger a capture error event
        service.paymentEvent = .show(eventDetails: .paymentCaptureError(cancelPayment: {}))

        // Find the capture error message and trigger the exit action
        guard case .paymentCaptureError(let viewModel) = sut.cardPresentPaymentInlineMessage else {
            Issue.record("Expected paymentCaptureError inline message")
            return
        }
        viewModel.newOrderButtonViewModel.actionHandler()
        // Yield to let the Task { @MainActor in } enqueued by the action handler execute.
        await Task.yield()
        #expect(exitActionCalled == true)
        _ = sut // prevent sut from being released before the yield
    }

    @Test("connection success alert is filtered when waiting to start payment on connect")
    @MainActor
    func connectionSuccessAlert_isFiltered_whenWaitingToStartPayment() async {
        let service = MockCardPresentPaymentService()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake()

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        // Start payment while disconnected — sets up the subscription
        await sut.startPayment()

        // Emit a connection success event
        service.paymentEvent = .show(eventDetails: .connectionSuccess(done: {}))

        // Alert should be filtered
        #expect(sut.cardPresentPaymentAlertViewModel == nil)
    }

    @Test("connection success alert is shown when not waiting to start payment")
    @MainActor
    func connectionSuccessAlert_isShown_whenNotWaitingToStartPayment() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        // Start and complete a payment — clears the subscription
        await sut.startPayment()

        // Emit a connection success event
        service.paymentEvent = .show(eventDetails: .connectionSuccess(done: {}))

        // Alert should be shown
        #expect(sut.cardPresentPaymentAlertViewModel != nil)
    }
}

// MARK: - Factory

@MainActor
private func makePaymentController(
    cardPresentPaymentService: CardPresentPaymentFacade = MockCardPresentPaymentService(),
    orderProvider: POSPaymentOrderProviding = MockPOSPaymentOrderProvider(),
    cashPaymentHandler: POSCashPaymentHandling = MockPOSCashPaymentHandler(),
    receiptSender: POSReceiptSending = MockPOSReceiptSender(),
    postPaymentStep: (() async throws -> Void)? = nil,
    configuration: POSPaymentFlowConfiguration = .cart(onNewOrder: {}, onEditOrder: {}),
    analytics: POSAnalyticsProviding = MockPOSAnalytics(),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    celebration: PaymentCaptureCelebrationProtocol = MockPaymentCaptureCelebration(),
    paymentState: PointOfSalePaymentState = .idle
) -> POSPaymentModel {
    POSPaymentModel(
        cardPresentPaymentService: cardPresentPaymentService,
        orderProvider: orderProvider,
        cashPaymentHandler: cashPaymentHandler,
        receiptSender: receiptSender,
        postPaymentStep: postPaymentStep,
        configuration: configuration,
        analytics: analytics,
        collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
        celebration: celebration,
        paymentState: paymentState)
}
