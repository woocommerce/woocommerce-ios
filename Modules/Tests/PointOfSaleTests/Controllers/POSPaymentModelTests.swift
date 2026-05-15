import Testing
import Foundation
import Combine
import struct Yosemite.Order
import struct Yosemite.Address
import protocol Yosemite.PaymentCaptureCelebrationProtocol
import enum WooFoundationCore.WooAnalyticsStat
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
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
        orderProvider.totalDecimalToReturn = 10

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
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        // Not called yet since reader is disconnected
        #expect(service.collectPaymentWasCalled == false)

        // Connect the reader and wait for the Combine chain to trigger collectPayment
        await fireOnce { fire in
            service.onCollectPaymentCalled = { fire() }
            service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        }

        #expect(service.collectPaymentWasCalled == true)
    }

    // MARK: - Cash Payment

    @Test("startCashPayment transitions to cash immediately and cancels card payment in background")
    @MainActor
    func startCashPayment_cancelsCardAndTransitionsToCash() async {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        await withCheckedContinuation { continuation in
            service.onCancelPaymentCalled = {
                continuation.resume()
            }
            sut.startCashPayment()

            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .collectingCash))
        }
        #expect(service.cancelPaymentCalled == true)
    }

    @Test("idle card event is dropped during cash flow")
    @MainActor
    func cardIdleEvent_during_cashFlow_isDropped() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        #expect(sut.paymentState.card == .acceptingCard)

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When
        service.paymentEvent = .idle

        // Then
        #expect(sut.paymentState.cash == .collectingCash)
        #expect(sut.paymentState.card == .acceptingCard)
    }

    @Test("active card event during cash flow transitions back to card view")
    @MainActor
    func activeCardEvent_during_cashFlow_transitionsBackToCard() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When
        service.paymentEvent = .show(eventDetails: .processing)

        // Then
        #expect(sut.paymentState.cash == .idle)
        #expect(sut.paymentState.card == .processingPayment)
    }

    @Test("card payment success during cash flow transitions to card success")
    @MainActor
    func cardPaymentSuccess_during_cashFlow_transitionsToCardSuccess() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When
        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        // Then
        #expect(sut.paymentState.cash == .idle)
        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("startCashPayment is blocked during ineligible card states")
    @MainActor
    func startCashPayment_when_processingPayment_then_blocked() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            paymentState: PointOfSalePaymentState(card: .processingPayment, cash: .idle))

        // When
        sut.startCashPayment()

        // Then
        #expect(sut.paymentState.cash == .idle)
    }

    @Test("cancelCashPayment resets to idle")
    @MainActor
    func cancelCashPayment_resetsToIdle() async {
        // Given
        let sut = makePaymentController()

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When
        await sut.cancelCashPayment()

        // Then
        #expect(sut.paymentState.cash == .idle)
    }

    @Test("cancelCashPayment with connected reader calls startPayment")
    @MainActor
    func cancelCashPayment_when_readerConnected_then_callsStartPayment() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)
        service.cancelPaymentCalled = false
        service.collectPaymentWasCalled = false

        // When
        await sut.cancelCashPayment()

        // Then
        #expect(sut.paymentState.cash == .idle)
        #expect(service.cancelPaymentCalled == true)
        #expect(service.collectPaymentWasCalled == true)
        #expect(sut.isActive == true)
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

    // MARK: - Mark as Paid

    @Test("startMarkAsPaidPayment transitions to confirming immediately and cancels card payment in background")
    @MainActor
    func startMarkAsPaidPayment_cancelsCardAndTransitionsToConfirming() async {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        await withCheckedContinuation { continuation in
            service.onCancelPaymentCalled = {
                continuation.resume()
            }
            sut.startMarkAsPaidPayment()

            // Synchronous transition before the cancel completes — same shape as cash.
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .confirming))
        }
        #expect(service.cancelPaymentCalled == true)
    }

    @Test("startMarkAsPaidPayment is blocked during ineligible card states")
    @MainActor
    func startMarkAsPaidPayment_when_processingPayment_then_blocked() async {
        // Given
        let sut = makePaymentController(
            paymentState: PointOfSalePaymentState(card: .processingPayment, cash: .idle))

        // When
        sut.startMarkAsPaidPayment()

        // Then
        #expect(sut.paymentState.markAsPaid == .idle)
    }

    @Test("startMarkAsPaidPayment is a no-op when already confirming")
    @MainActor
    func startMarkAsPaidPayment_when_alreadyConfirming_then_noOp() async {
        // Given
        let analytics = MockPOSAnalytics()
        let sut = makePaymentController(
            analytics: analytics,
            paymentState: PointOfSalePaymentState(card: .idle, cash: .idle, markAsPaid: .confirming))

        // When
        sut.startMarkAsPaidPayment()

        // Then: no extra "tapped" analytics fired and no state churn.
        #expect(analytics.events.contains { $0.eventName == WooAnalyticsStat.pointOfSaleCheckoutMarkAsPaidTapped.rawValue } == false)
        #expect(sut.paymentState.markAsPaid == .confirming)
    }

    @Test("cancelMarkAsPaidPayment resets to idle")
    @MainActor
    func cancelMarkAsPaidPayment_resetsToIdle() async {
        // Given
        let sut = makePaymentController()

        sut.startMarkAsPaidPayment()
        #expect(sut.paymentState.markAsPaid == .confirming)

        // When
        await sut.cancelMarkAsPaidPayment()

        // Then
        #expect(sut.paymentState.markAsPaid == .idle)
    }

    @Test("cancelMarkAsPaidPayment with connected reader re-arms the card flow")
    @MainActor
    func cancelMarkAsPaidPayment_when_readerConnected_then_callsStartPayment() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startMarkAsPaidPayment()
        #expect(sut.paymentState.markAsPaid == .confirming)
        service.cancelPaymentCalled = false
        service.collectPaymentWasCalled = false

        // When
        await sut.cancelMarkAsPaidPayment()

        // Then
        #expect(sut.paymentState.markAsPaid == .idle)
        #expect(service.cancelPaymentCalled == true)
        #expect(service.collectPaymentWasCalled == true)
    }

    @Test("confirmMarkAsPaidPayment calls handler and transitions to success")
    @MainActor
    func confirmMarkAsPaidPayment_callsHandlerAndTransitionsToSuccess() async throws {
        let handler = MockPOSMarkAsPaidHandler()
        let order = Order.fake().copy(orderID: 123, total: "10.00")
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = order
        let celebration = MockPaymentCaptureCelebration()
        let analytics = MockPOSAnalytics()

        let sut = makePaymentController(
            orderProvider: orderProvider,
            markAsPaidHandler: handler,
            analytics: analytics,
            celebration: celebration)

        try await sut.confirmMarkAsPaidPayment()

        #expect(handler.markOrderAsPaidCalled == true)
        #expect(handler.markOrderAsPaidReceivedOrder?.orderID == order.orderID)
        #expect(sut.paymentState.markAsPaid == .paymentSuccess)
        #expect(celebration.celebrationWasCalled == true)
        #expect(analytics.events.contains { $0.eventName == WooAnalyticsStat.pointOfSaleMarkAsPaidConfirmed.rawValue })
    }

    @Test("confirmMarkAsPaidPayment runs post-payment step on success")
    @MainActor
    func confirmMarkAsPaidPayment_runsPostPaymentStep() async throws {
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake()
        var postPaymentStepCalled = false

        let sut = makePaymentController(
            orderProvider: orderProvider,
            postPaymentStep: { postPaymentStepCalled = true })

        try await sut.confirmMarkAsPaidPayment()

        #expect(postPaymentStepCalled == true)
    }

    @Test("confirmMarkAsPaidPayment rolls back to confirming and tracks failure when handler throws")
    @MainActor
    func confirmMarkAsPaidPayment_when_handlerThrows_then_rollsBackAndTracksFailure() async {
        struct HandlerError: Error {}
        let handler = MockPOSMarkAsPaidHandler()
        handler.errorToThrow = HandlerError()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake()
        let analytics = MockPOSAnalytics()

        let sut = makePaymentController(
            orderProvider: orderProvider,
            markAsPaidHandler: handler,
            analytics: analytics)

        await #expect(throws: HandlerError.self) {
            try await sut.confirmMarkAsPaidPayment()
        }

        #expect(sut.paymentState.markAsPaid == .confirming)
        #expect(analytics.events.contains { $0.eventName == WooAnalyticsStat.pointOfSaleMarkAsPaidFailed.rawValue })
    }

    @Test("confirmMarkAsPaidPayment tracks failure when provideOrder throws (currentOrder == nil)")
    @MainActor
    func confirmMarkAsPaidPayment_when_provideOrderThrows_then_tracksFailure() async {
        struct ProvideOrderError: Error {}
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.errorToThrow = ProvideOrderError()
        let handler = MockPOSMarkAsPaidHandler()
        let analytics = MockPOSAnalytics()

        let sut = makePaymentController(
            orderProvider: orderProvider,
            markAsPaidHandler: handler,
            analytics: analytics)

        await #expect(throws: ProvideOrderError.self) {
            try await sut.confirmMarkAsPaidPayment()
        }

        // Failure analytics fires from the model's catch even though we never reached the handler.
        #expect(handler.markOrderAsPaidCalled == false)
        #expect(analytics.events.contains { $0.eventName == WooAnalyticsStat.pointOfSaleMarkAsPaidFailed.rawValue })
        #expect(sut.paymentState.markAsPaid == .confirming)
    }

    @Test("confirmMarkAsPaidPayment reuses currentOrder when one is already cached")
    @MainActor
    func confirmMarkAsPaidPayment_when_currentOrderCached_then_doesNotCallProvideOrder() async throws {
        // Given a SUT that has already taken a payment path which cached `currentOrder`
        // (we simulate this by collecting cash first — both flows share the same cache).
        let cachedOrder = Order.fake().copy(orderID: 999, total: "10.00")
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = cachedOrder
        orderProvider.totalDecimalToReturn = 10

        let handler = MockPOSMarkAsPaidHandler()
        let sut = makePaymentController(
            orderProvider: orderProvider,
            markAsPaidHandler: handler)

        // Prime the cache via cash: collectCashPayment populates `currentOrder`.
        try await sut.collectCashPayment(changeDueAmount: nil)
        #expect(orderProvider.provideOrderCallCount == 1)

        // When
        try await sut.confirmMarkAsPaidPayment()

        // Then: provideOrder was NOT called again — the cached order was reused.
        #expect(orderProvider.provideOrderCallCount == 1)
        #expect(handler.markOrderAsPaidReceivedOrder?.orderID == cachedOrder.orderID)
    }

    // MARK: - Card Events During Mark as Paid

    @Test("idle card event is dropped during mark-as-paid flow")
    @MainActor
    func cardIdleEvent_during_markAsPaidFlow_isDropped() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        #expect(sut.paymentState.card == .acceptingCard)

        sut.startMarkAsPaidPayment()
        #expect(sut.paymentState.markAsPaid == .confirming)

        // When
        service.paymentEvent = .idle

        // Then: a non-committed `.idle` card event must not exit mark-as-paid.
        #expect(sut.paymentState.markAsPaid == .confirming)
        #expect(sut.paymentState.card == .acceptingCard)
    }

    @Test("acceptingCard event during mark-as-paid does not exit the flow")
    @MainActor
    func acceptingCardEvent_during_markAsPaidFlow_doesNotExitFlow() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()
        // Land in `.acceptingCard` first so the `allowsMarkAsPaidPayment` guard is open
        // when the merchant taps Mark as paid.
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startMarkAsPaidPayment()
        #expect(sut.paymentState.markAsPaid == .confirming)

        // When: a stale acceptingCard event arrives
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        // Then: the merchant stays on the confirmation flow.
        #expect(sut.paymentState.markAsPaid == .confirming)
    }

    @Test("cardInserted event during mark-as-paid exits the flow - card physically committed")
    @MainActor
    func cardInsertedEvent_during_markAsPaidFlow_exitsFlow() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startMarkAsPaidPayment()
        #expect(sut.paymentState.markAsPaid == .confirming)

        // When: card is physically inserted - irreversible commit, the merchant has chosen card.
        service.paymentEvent = .show(eventDetails: .cardInserted(cancelPayment: {}))

        // Then: mark-as-paid exits and card takes over.
        #expect(sut.paymentState.markAsPaid == .idle)
        #expect(sut.paymentState.card == .cardInserted)
    }

    @Test("processingPayment event during mark-as-paid exits the flow")
    @MainActor
    func processingPaymentEvent_during_markAsPaidFlow_exitsFlow() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startMarkAsPaidPayment()

        // When
        service.paymentEvent = .show(eventDetails: .processing)

        // Then
        #expect(sut.paymentState.markAsPaid == .idle)
        #expect(sut.paymentState.card == .processingPayment)
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

    @Test("sendReceipt updates customerBillingEmail to sent email")
    @MainActor
    func sendReceipt_when_successful_then_updates_customerBillingEmail() async throws {
        // Given
        let receiptSender = MockPOSReceiptSender()
        let orderProvider = MockPOSPaymentOrderProvider()
        let initialAddress = Address(firstName: "", lastName: "", company: nil, address1: "",
                                     address2: nil, city: "", state: "", postcode: "",
                                     country: "", phone: nil, email: "old@example.com")
        let order = Order.fake().copy(orderID: 123, total: "10.00", billingAddress: initialAddress)
        orderProvider.orderToReturn = order
        orderProvider.totalDecimalToReturn = 10

        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            receiptSender: receiptSender)

        await sut.startPayment()
        #expect(sut.customerBillingEmail == "old@example.com")

        // When
        try await sut.sendReceipt(to: "new@example.com")

        // Then
        #expect(sut.customerBillingEmail == "new@example.com")
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
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle))

        // Start a payment session to activate inline message subscriptions
        await sut.startPayment()

        // Set up some inline message
        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        sut.reset()

        #expect(sut.paymentState == .idle)
        #expect(sut.cardPresentPaymentInlineMessage == nil)
    }

    // MARK: - Combine Chains

    @Test("payment event publisher updates card payment state during active session")
    @MainActor
    func paymentEventPublisher_updatesCardPaymentState() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        // Start a payment session to activate subscriptions
        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("payment event publisher updates inline message during active session")
    @MainActor
    func paymentEventPublisher_updatesInlineMessage() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        // Start a payment session to activate subscriptions
        await sut.startPayment()

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
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let config = POSPaymentFlowConfiguration.cart(
            onNewOrder: { exitActionCalled = true },
            onEditOrder: {})

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            configuration: config)

        // Start a payment session to activate inline message subscriptions
        await sut.startPayment()

        // Trigger a capture error event
        service.paymentEvent = .show(eventDetails: .paymentCaptureError(cancelPayment: {}))

        // Find the capture error message and trigger the exit action
        guard case .paymentCaptureError(let viewModel) = sut.cardPresentPaymentInlineMessage else {
            Issue.record("Expected paymentCaptureError inline message")
            return
        }
        viewModel.newOrderButtonViewModel.actionHandler()
        #expect(exitActionCalled == true)
    }

    @Test("payment events do not update card state before startPayment is called")
    @MainActor
    func paymentEvents_doNotUpdateCardState_beforeStartPayment() {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        #expect(sut.paymentState.card == .idle)
    }

    @Test("payment events do not update inline message before startPayment is called")
    @MainActor
    func paymentEvents_doNotUpdateInlineMessage_beforeStartPayment() {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        #expect(sut.cardPresentPaymentInlineMessage == nil)
    }

    @Test("payment events do not update card state after reset")
    @MainActor
    func paymentEvents_doNotUpdateCardState_afterReset() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()
        sut.reset()

        // Events after reset should not update card state
        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

        #expect(sut.paymentState.card == .idle)
    }

    @Test("deactivate clears subscriptions without resetting state")
    @MainActor
    func deactivate_clearsSubscriptionsPreservesState() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()
        #expect(sut.isActive == true)
        // Mock's collectPayment emits paymentSuccess, so state is already updated
        #expect(sut.paymentState.card == .cardPaymentSuccessful)

        sut.deactivate()
        #expect(sut.isActive == false)

        // New events after suspend should not change the state
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        // State should still reflect the pre-suspend value, not the new event
        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("activate reactivates session after deactivate")
    @MainActor
    func activate_reactivatesSessionAfterDeactivate() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10.00

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()
        sut.deactivate()
        #expect(sut.isActive == false)

        // Reactivate the session
        await sut.activate()
        #expect(sut.isActive == true)

        // Events should now be processed again
        service.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))
        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("alerts are delivered without an active payment session")
    @MainActor
    func alerts_deliveredWithoutActiveSession() {
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        // Emit a connection success event without calling startPayment
        service.paymentEvent = .show(eventDetails: .connectionSuccess(done: {}))

        // Alerts are always-on, so this should still be delivered
        #expect(sut.cardPresentPaymentAlertViewModel != nil)
    }

    @Test("subsequent card events are processed after transitioning back from cash flow")
    @MainActor
    func subsequentCardEvents_processed_afterCashFlowTransition() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        #expect(sut.paymentState.card == .acceptingCard)

        // Enter cash flow
        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: non-idle card event transitions back to card view
        service.paymentEvent = .show(eventDetails: .processing)
        #expect(sut.paymentState.cash == .idle)
        #expect(sut.paymentState.card == .processingPayment)

        // Then: subsequent card events continue to update card state naturally
        service.paymentEvent = .idle
        #expect(sut.paymentState.card == .idle)
        #expect(sut.isActive == true)
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

    // MARK: - Cash Payment and Reader Connection

    @Test("startCashPayment while disconnected prevents card collection on reconnect")
    @MainActor
    func startCashPayment_whenDisconnected_preventsCardCollectionOnReconnect() async {
        // Given
        let service = MockCardPresentPaymentService()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        // Start payment while disconnected - installs startPaymentOnCardReaderConnection
        await sut.startPayment()
        #expect(service.collectPaymentWasCalled == false)

        // When: enter cash payment while still disconnected
        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // Then: reconnecting the reader should NOT trigger card collection
        service.collectPaymentWasCalled = false

        // Wait for cardReaderConnectionStatus to update, proving the Combine
        // chain fully processed the connection event.
        await fireOnce { fire in
            withObservationTracking {
                _ = sut.cardReaderConnectionStatus
            } onChange: {
                Task { @MainActor in fire() }
            }
            service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        }

        #expect(service.collectPaymentWasCalled == false)
        #expect(sut.paymentState.cash == .collectingCash)
    }

    // MARK: - Card Events During Cash Flow

    @Test("preparingReader card event during cash flow does not exit cash")
    @MainActor
    func preparingReaderEvent_during_cashFlow_doesNotExitCash() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: a stale preparingReader event arrives
        service.paymentEvent = .show(eventDetails: .preparingForPayment(cancelPayment: {}))

        // Then: cash should NOT be exited
        #expect(sut.paymentState.cash == .collectingCash)
    }

    @Test("validatingOrder card event during cash flow does not exit cash")
    @MainActor
    func validatingOrderEvent_during_cashFlow_doesNotExitCash() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: a stale validatingOrder event arrives
        service.paymentEvent = .show(eventDetails: .validatingOrder(cancelPayment: {}))

        // Then: cash should NOT be exited
        #expect(sut.paymentState.cash == .collectingCash)
    }

    @Test("acceptingCard event during cash flow does not exit cash")
    @MainActor
    func acceptingCardEvent_during_cashFlow_doesNotExitCash() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: a stale acceptingCard event arrives
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        // Then: cash should NOT be exited
        #expect(sut.paymentState.cash == .collectingCash)
    }

    @Test("cardInserted event during cash flow exits cash - card physically committed")
    @MainActor
    func cardInsertedEvent_during_cashFlow_exitsCash() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: card is physically inserted - this is an irreversible user action
        service.paymentEvent = .show(eventDetails: .cardInserted(cancelPayment: {}))

        // Then: cash SHOULD be exited to handle the card payment
        #expect(sut.paymentState.cash == .idle)
        #expect(sut.paymentState.card == .cardInserted)
    }

    @Test("processingPayment event during cash flow exits cash")
    @MainActor
    func processingPaymentEvent_during_cashFlow_exitsCash() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        sut.startCashPayment()

        // When
        service.paymentEvent = .show(eventDetails: .processing)

        // Then
        #expect(sut.paymentState.cash == .idle)
        #expect(sut.paymentState.card == .processingPayment)
    }

    // MARK: - Reader Disconnect

    @Test("reader disconnect during preparingReader resets card state to idle")
    @MainActor
    func readerDisconnect_during_preparingReader_resetsCardStateToIdle() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        // Move to preparingReader state
        service.paymentEvent = .show(eventDetails: .preparingForPayment(cancelPayment: {}))
        #expect(sut.paymentState.card == .preparingReader)

        // When: reader disconnects
        service.connectedReader = nil

        // Then: card state should reset to idle so cash button becomes available
        #expect(sut.paymentState.card == .idle)
        #expect(sut.paymentState.allowsCashPayment == true)
    }

    @Test("reader disconnect during acceptingCard resets card state to idle")
    @MainActor
    func readerDisconnect_during_acceptingCard_resetsCardStateToIdle() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        #expect(sut.paymentState.card == .acceptingCard)

        // When: reader disconnects
        service.connectedReader = nil

        // Then: card state should reset to idle
        #expect(sut.paymentState.card == .idle)
        #expect(sut.paymentState.allowsCashPayment == true)
    }

    @Test("reader disconnect during processingPayment does NOT reset card state")
    @MainActor
    func readerDisconnect_during_processingPayment_doesNotResetCardState() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .processing)
        #expect(sut.paymentState.card == .processingPayment)

        // When: reader disconnects
        service.connectedReader = nil

        // Then: card state should NOT be reset - payment may still complete
        #expect(sut.paymentState.card == .processingPayment)
    }

    // MARK: - Cash Cancel and Card Restart

    @Test("cancelCashPayment awaits background cancel before restarting card flow")
    @MainActor
    func cancelCashPayment_awaitsBackgroundCancel_beforeRestartingCardFlow() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        await sut.startPayment()

        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        // Record cancel calls order
        var cancelCallOrder: [String] = []
        service.onCancelPaymentCalled = {
            cancelCallOrder.append("cancel")
        }

        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: cancel cash payment and restart card flow
        service.collectPaymentWasCalled = false
        await sut.cancelCashPayment()

        #expect(service.collectPaymentWasCalled == true)
    }

    @Test("cancelCashPayment with disconnected reader sets up subscription to collect on connect")
    @MainActor
    func cancelCashPayment_when_readerDisconnected_then_collectsOnConnect() async {
        // Given
        let service = MockCardPresentPaymentService()
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider)

        // Start payment with no reader - sets up connection subscription
        await sut.startPayment()
        #expect(service.collectPaymentWasCalled == false)

        // Enter cash flow - cancels the connection subscription
        sut.startCashPayment()
        #expect(sut.paymentState.cash == .collectingCash)

        // When: cancel cash payment while reader is still disconnected
        await sut.cancelCashPayment()

        // Then: subscription should be restored - connecting a reader triggers payment
        #expect(service.collectPaymentWasCalled == false)

        await fireOnce { fire in
            service.onCollectPaymentCalled = { fire() }
            service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        }

        #expect(service.collectPaymentWasCalled == true)
    }

    @Test("connection success alert is shown when not waiting to start payment")
    @MainActor
    func connectionSuccessAlert_isShown_whenNotWaitingToStartPayment() async {
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

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
    // MARK: - Connect Card Reader Concurrency

    @Test("connectCardReader called twice only triggers one connectReader call on the service")
    @MainActor
    func test_connectCardReader_when_called_twice_while_first_is_in_progress_then_only_one_connectReader_call() async {
        // Given
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        // When
        await fireOnce { fire in
            service.onConnectReaderCalled = { fire() }
            sut.connectCardReader()
            sut.connectCardReader()
        }

        // Then - only one call made; guard rejected the second
        #expect(service.connectReaderCallCount == 1)
    }

    @Test("connectCardReader can be called again after first connection completes")
    @MainActor
    func test_connectCardReader_when_called_after_first_completes_then_second_call_succeeds() async {
        // Given
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        // When - first connect call completes
        await fireOnce { fire in
            service.onConnectReaderCalled = { fire() }
            sut.connectCardReader()
        }
        #expect(service.connectReaderCallCount == 1)

        // When - second connect call after first completed
        await fireOnce { fire in
            service.onConnectReaderCalled = { fire() }
            sut.connectCardReader()
        }

        // Then - service should have been called twice (once per completed cycle)
        #expect(service.connectReaderCallCount == 2)
    }

    // MARK: - TTP Explicit Payment Start Gate

    @Test("TTP: events before startPaymentWithMethod are suppressed by the gate")
    @MainActor
    func startPaymentWithMethod_TTP_when_event_arrives_before_explicit_start_then_card_state_stays_idle() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            preferredConnectionMethod: .tapToPay)

        // When: startPayment pre-connects but does NOT open the gate
        await sut.startPayment()

        // Then: a payment event arriving before the merchant taps a method is suppressed
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        #expect(sut.paymentState.card == .idle)
        #expect(sut.cardPresentPaymentInlineMessage == nil)
    }

    @Test("TTP: events after startPaymentWithMethod(.tapToPay) are propagated")
    @MainActor
    func startPaymentWithMethod_TTP_when_event_arrives_after_explicit_start_then_card_state_updates() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            preferredConnectionMethod: .tapToPay)

        await sut.startPayment()

        // Confirm gate is closed: event before explicit start is suppressed
        service.paymentEvent = .show(eventDetails: .preparingForPayment(cancelPayment: {}))
        #expect(sut.paymentState.card == .idle)

        // When: merchant explicitly taps "Tap to Pay" — opens the gate
        await sut.startPaymentWithMethod(.tapToPay)

        // Then: events propagate through the now-open gate. The mock's
        // `collectPayment` auto-fires a `paymentSuccess` event — a terminal
        // state that reaches `paymentState.card` because the TTP path only
        // suppresses *intermediate* states (`.acceptingCard`, `.preparingReader`,
        // etc.) so the merchant's UI doesn't flicker behind Apple's modal.
        // The `.idle → .cardPaymentSuccessful` transition is unreachable
        // without an open gate, so observing it here proves propagation.
        #expect(sut.paymentState.card == .cardPaymentSuccessful)

        // And the TTP intermediate-state filter is active: a subsequent
        // `acceptingCard` event does not roll state backward.
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("TTP: cancelledOnReader resets card state to idle and re-arms the gate")
    @MainActor
    func cancelledOnReader_TTP_when_event_arrives_then_card_state_resets_and_gate_re_arms() async {
        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            preferredConnectionMethod: .tapToPay)

        await sut.startPayment()

        // Open the gate: merchant taps Tap to Pay. The mock's `collectPayment`
        // auto-fires a terminal `paymentSuccess` event (intermediate states are
        // filtered on TTP — see `subscribeToPaymentSessionEvents`).
        await sut.startPaymentWithMethod(.tapToPay)
        #expect(sut.paymentState.card == .cardPaymentSuccessful)

        // When: merchant cancels on reader
        service.paymentEvent = .show(eventDetails: .cancelledOnReader)

        // Then: card state resets to idle AND inline message is cleared.
        // The cancelledOnReader sink runs unconditionally on the TTP path
        // (no gate check), so cancellation resets even a terminal state.
        #expect(sut.paymentState.card == .idle)
        #expect(sut.cardPresentPaymentInlineMessage == nil)

        // And the gate is re-armed: events are suppressed again until next explicit tap
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))
        #expect(sut.paymentState.card == .idle)
    }

    @Test("BT: events are always propagated without waiting for startPaymentWithMethod")
    @MainActor
    func startPayment_BT_when_event_arrives_then_card_state_updates_without_explicit_start() async {
        // Given: Bluetooth path — gate is never applied
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            preferredConnectionMethod: .bluetooth)

        // When: start payment (BT path opens gate immediately)
        await sut.startPayment()

        // Then: events propagate without needing startPaymentWithMethod
        service.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(
            inputMethods: [.tap, .swipe, .insert],
            cancelPayment: {}))

        #expect(sut.paymentState.card == .acceptingCard)
    }

    // MARK: - Subscriber Ordering Regression

    @Test("TTP: after cancelledOnReader a subsequent startPaymentWithMethod opens the gate cleanly")
    @MainActor
    func cancelledOnReader_TTP_when_subsequent_startPaymentWithMethod_then_gate_is_open_not_stale() async {
        // This test is a regression guard for the subscriber-ordering invariant in
        // subscribeToPaymentSessionEvents: the cancelledOnReader sink MUST close the
        // gate (isAwaitingExplicitPaymentStart = true) before the card-state sink
        // evaluates shouldPropagatePaymentEvent. If the two sinks are ever reordered,
        // the card-state sink would run first and the cancelledOnReader event would
        // advance paymentState.card to a non-idle state before the gate closes,
        // causing the subsequent startPaymentWithMethod to see a stale (open) gate.

        // Given
        let service = MockCardPresentPaymentService()
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)
        let orderProvider = MockPOSPaymentOrderProvider()
        orderProvider.orderToReturn = Order.fake().copy(total: "10.00")
        orderProvider.totalDecimalToReturn = 10

        let sut = makePaymentController(
            cardPresentPaymentService: service,
            orderProvider: orderProvider,
            preferredConnectionMethod: .tapToPay)

        await sut.startPayment()

        // Round 1: open gate, reach a terminal state, then cancel on reader.
        // (Intermediates like `.acceptingCard` are filtered on TTP; the mock's
        // auto-fired `paymentSuccess` is the terminal state that lands.)
        await sut.startPaymentWithMethod(.tapToPay)
        #expect(sut.paymentState.card == .cardPaymentSuccessful)

        // When: merchant cancels on reader — gate must close and state must reset
        service.paymentEvent = .show(eventDetails: .cancelledOnReader)

        // Then: state is idle immediately
        #expect(sut.paymentState.card == .idle)

        // Re-attach the mock reader for Round 2. `connectTapToPayReader` (kicked off
        // by Round 1's `startPayment`) disconnected the mock — the mock's
        // `connectReader` returns a `.connected` result but doesn't update
        // `connectedReader`, so the publisher stays at `.disconnected`. Without this
        // reset, `startPaymentFlow`'s `guard case .connected` would short-circuit and
        // collectPayment wouldn't fire in Round 2, masking the invariant we're testing.
        service.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

        // Round 2: a subsequent startPaymentWithMethod must succeed (gate re-opens
        // and the mock auto-fires `paymentSuccess` again).
        await sut.startPaymentWithMethod(.tapToPay)

        // If subscriber ordering were inverted — card-state sink before
        // cancelledOnReader sink — `cancelledOnReader` would have advanced
        // `paymentState.card` past `.idle` (terminal states bypass the filter),
        // and `startPaymentWithMethod`'s `guard paymentState.card == .idle` would
        // have short-circuited Round 2, leaving us stuck at the prior terminal
        // state without the second auto-fired `paymentSuccess` ever running.
        // Reaching `.cardPaymentSuccessful` again proves Round 2 actually proceeded.
        #expect(sut.paymentState.card == .cardPaymentSuccessful)
    }

    @Test("connectCardReader skips a second call while the first is in flight")
    @MainActor
    func test_connectCardReader_when_called_again_while_in_flight_then_skips_second() async {
        // Given
        let service = MockCardPresentPaymentService()
        let sut = makePaymentController(cardPresentPaymentService: service)

        // When/Then: while the first call's mock body is running, a second
        // call hits the SUT's task guard and is skipped.
        await fireOnce { fire in
            service.onConnectReaderCalled = {
                sut.connectCardReader()
                #expect(service.connectReaderCallCount == 1)
                fire()
            }
            sut.connectCardReader()
        }

        // After the first connect propagates to cardReaderConnectionStatus,
        // verify no observer reactions caused a spurious re-call.
        let reader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.85)
        await fireOnce { fire in
            withObservationTracking {
                _ = sut.cardReaderConnectionStatus
            } onChange: {
                Task { @MainActor in
                    if case .connected = sut.cardReaderConnectionStatus {
                        fire()
                    }
                }
            }
            service.connectedReader = reader
        }
        #expect(service.connectReaderCallCount == 1)
    }
}

// MARK: - Factory

@MainActor
private func makePaymentController(
    cardPresentPaymentService: CardPresentPaymentFacade = MockCardPresentPaymentService(),
    orderProvider: POSPaymentOrderProviding = MockPOSPaymentOrderProvider(),
    cashPaymentHandler: POSCashPaymentHandling = MockPOSCashPaymentHandler(),
    scanToPayHandler: POSScanToPayHandling = MockPOSScanToPayHandler(),
    scanToPayVerifier: POSScanToPayVerifying? = nil,
    markAsPaidHandler: POSMarkAsPaidHandling = MockPOSMarkAsPaidHandler(),
    receiptSender: POSReceiptSending = MockPOSReceiptSender(),
    postPaymentStep: (() async throws -> Void)? = nil,
    configuration: POSPaymentFlowConfiguration = .cart(onNewOrder: {}, onEditOrder: {}),
    analytics: POSAnalyticsProviding = MockPOSAnalytics(),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    celebration: PaymentCaptureCelebrationProtocol = MockPaymentCaptureCelebration(),
    scanToPayPollInterval: TimeInterval = 3,
    preferredConnectionMethod: CardReaderConnectionMethod = .bluetooth,
    paymentState: PointOfSalePaymentState = .idle
) -> POSPaymentModel {
    POSPaymentModel(
        cardPresentPaymentService: cardPresentPaymentService,
        orderProvider: orderProvider,
        cashPaymentHandler: cashPaymentHandler,
        scanToPayHandler: scanToPayHandler,
        scanToPayVerifier: scanToPayVerifier,
        markAsPaidHandler: markAsPaidHandler,
        receiptSender: receiptSender,
        postPaymentStep: postPaymentStep,
        configuration: configuration,
        analytics: analytics,
        collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
        celebration: celebration,
        scanToPayPollInterval: scanToPayPollInterval,
        preferredConnectionMethod: preferredConnectionMethod,
        paymentState: paymentState)
}
