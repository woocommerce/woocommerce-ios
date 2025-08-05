import Foundation
import Combine
import Observation

import protocol Yosemite.POSOrderableItem
import protocol WooFoundation.Analytics
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCoupon
import enum Yosemite.POSItem
import enum Yosemite.SystemStatusAction
import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItemType
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import enum Yosemite.PointOfSaleBarcodeScanError

@available(iOS 17.0, *)
protocol PointOfSaleAggregateModelProtocol {
    var orderStage: PointOfSaleOrderStage { get }

    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus { get }
    func connectCardReader()
    func disconnectCardReader()
    var paymentState: PointOfSalePaymentState { get }
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? { get set }
    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { get }
    var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel? { get set }
    func cancelCardPaymentsOnboarding()
    func trackCardPaymentsOnboardingShown()

    var purchasableItemsController: PointOfSaleItemsControllerProtocol { get }
    var purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol { get }
    var couponsController: PointOfSaleCouponsControllerProtocol { get }
    var couponsSearchController: PointOfSaleSearchingItemsControllerProtocol { get }

    var cart: Cart { get }
    func barcodeScanned(_ result: Result<String, HIDBarcodeParserError>)
    func addToCart(_ item: POSItem)
    func remove(cartItem: CartItem)
    func removeAllItemsFromCart(types: [CartItemType])
    func addMoreToCart()
    func startNewCart()

    func saveSearchTerm(_ term: String, for itemType: POSItemType)
    func searchHistory(for itemType: POSItemType) -> [String]

    var orderState: PointOfSaleOrderState { get }
    func checkOut() async

    func pointOfSaleClosed()
}

@available(iOS 17.0, *)
@Observable final class PointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    private(set) var orderStage: PointOfSaleOrderStage = .building

    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel?
    private var onOnboardingCancellation: (() -> Void)?

    private(set) var cart: Cart = .init()

    var orderState: PointOfSaleOrderState { orderController.orderState.externalState }
    private var internalOrderState: PointOfSaleInternalOrderState { orderController.orderState }

    let entryPointController: POSEntryPointController
    let purchasableItemsController: PointOfSaleItemsControllerProtocol
    let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol
    let couponsController: PointOfSaleCouponsControllerProtocol
    let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol

    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let analytics: Analytics
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    let searchHistoryService: POSSearchHistoryProviding
    private let barcodeScanService: PointOfSaleBarcodeScanServiceProtocol

    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?

    private let soundPlayer: PointOfSaleSoundPlayerProtocol

    private var cancellables: Set<AnyCancellable> = []

    // Private storage of the concrete coordinator
    private let _viewStateCoordinator = PointOfSaleViewStateCoordinator()

    // Interface that only exposes reset functionality, for use in the aggregate model
    private var viewStateCoordinator: PointOfSaleViewStateResettable {
        _viewStateCoordinator
    }

    // Type-safe accessor specifically for the view
    var viewStateCoordinatorForView: PointOfSaleViewStateCoordinator {
        _viewStateCoordinator
    }

    init(entryPointController: POSEntryPointController,
         itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         analytics: Analytics = ServiceLocator.analytics,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularPurchasableItemsController: PointOfSaleItemsControllerProtocol,
         barcodeScanService: PointOfSaleBarcodeScanServiceProtocol,
         soundPlayer: PointOfSaleSoundPlayerProtocol = PointOfSaleSoundPlayer(),
         paymentState: PointOfSalePaymentState = .idle) {
        self.entryPointController = entryPointController
        self.purchasableItemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.analytics = analytics
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.paymentState = paymentState
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.barcodeScanService = barcodeScanService
        self.soundPlayer = soundPlayer

        publishCardReaderConnectionStatus()
        publishPaymentMessages()
        setupReaderReconnectionObservation()
    }
}

// MARK: - Cart
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    func addToCart(_ item: POSItem) {
        trackCustomerInteractionStarted()
        cart.add(item)
    }

    func remove(cartItem: CartItem) {
        switch cartItem.type {
        case .purchasableItem:
            cart.purchasableItems.removeAll { $0.id == cartItem.id }
        case .coupon:
            cart.coupons.removeAll { $0.id == cartItem.id }
        }
    }

    func cancelLoadingItem(id: UUID) {
        cart.removeItem(id: id)
    }

    func removeAllItemsFromCart(types: [CartItemType] =  CartItemType.allCases) {
        for type in types {
            switch type {
            case .purchasableItem:
                cart.purchasableItems.removeAll()
            case .coupon:
                cart.coupons.removeAll()
            }
        }
    }

    func addMoreToCart() {
        setStateForEditing()
    }

    func startNewCart() {
        removeAllItemsFromCart()
        Task {
            await orderController.clearOrder()
        }
        setStateForEditing()
        viewStateCoordinator.reset()
    }

    private func setStateForEditing() {
        orderStage = .building
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
    }
}

// MARK: - Barcode Scanning
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    func barcodeScanned(_ result: Result<String, HIDBarcodeParserError>) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch result {
            case .success(let barcode):
                await handleSuccessfulScan(barcode: barcode)
            case .failure(let error):
                await handleFailedScan(error: error)
            }
        }
    }

    @MainActor
    private func handleSuccessfulScan(barcode: String) async {
        let placeholderItemID = cart.addLoadingItem().id

        analytics.track(
            event: .PointOfSale.addItemToCart(
                sourceViewType: .scanner,
                itemType: .loading
            )
        )

        do throws(PointOfSaleBarcodeScanError) {
            let item = try await barcodeScanService.getItem(barcode: barcode)
            if let cartItem = cart.updateLoadingItem(id: placeholderItemID, with: item) {
                analytics.track(
                    event: .PointOfSale.addItemToCart(
                        sourceViewType: .scanner,
                        itemType: .product,
                        productType: .init(cartItem: cartItem)
                    )
                )

                cart.accessibilityFocusedItemID = cartItem.id
            }
        } catch {
            DDLogInfo("Failed to find item by barcode: \(error)")
            if let _ = cart.updateLoadingItem(id: placeholderItemID, with: error) {
                await handleErrorItemAdded(error)
            }
        }
    }

    @MainActor
    private func handleFailedScan(error: Error) async {
        let scanError = switch error {
        case HIDBarcodeParserError.scanTooShort(let barcode):
            PointOfSaleBarcodeScanError.scanTooShort(scannedCode: barcode)
        case HIDBarcodeParserError.timedOut(let barcode):
            PointOfSaleBarcodeScanError.timedOut(scannedCode: barcode)
        default:
            PointOfSaleBarcodeScanError.parsingError(underlyingError: error)
        }

        cart.addErrorItem(error: scanError)
        await handleErrorItemAdded(scanError)
    }

    @MainActor
    private func handleErrorItemAdded(_ error: PointOfSaleBarcodeScanError) async {
        // Only play a sound and track analytics if the item still exists in the cart.
        await soundPlayer.playSound(.barcodeScanFailure)

        analytics.track(
            event: .PointOfSale.addItemToCart(
                sourceViewType: .scanner,
                itemType: .error,
                error: error
            )
        )
    }
}

// MARK: - Search
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    func saveSearchTerm(_ term: String, for itemType: POSItemType) {
        searchHistoryService.saveSuccessfulSearch(term: term, for: itemType)
    }

    func searchHistory(for itemType: POSItemType) -> [String] {
        return searchHistoryService.searchHistory(for: itemType)
    }
}

// MARK: - Track events
@available(iOS 17.0, *)
private extension PointOfSaleAggregateModel {
    func trackCustomerInteractionStarted() {
        // At the moment we're assumming that an interaction starts simply when the cart is zero
        // but a more complex logic will be needed for other cases
        if cart.isEmpty {
            collectOrderPaymentAnalyticsTracker.trackCustomerInteractionStarted()
        }
    }

    // Tracks when the order is created successfully
    // pdfdoF-6hn#comment-7625-p2
    func trackOrderSyncState(_ result: Result<SyncOrderState, Error>) {
        switch result {
        case .success(let syncState):
            switch syncState {
            case .newOrder:
                collectOrderPaymentAnalyticsTracker.trackOrderSyncSuccess()
            default:
                break
            }
        case .failure:
            break
        }
    }
}

// MARK: - Card payments
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    private func publishCardReaderConnectionStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .sink(receiveValue: { [weak self] connectionStatus in
                self?.cardReaderConnectionStatus = connectionStatus
            })
            .store(in: &cancellables)
    }

    func connectCardReader() {
        analytics.track(.pointOfSaleCardReaderConnectionTapped)
        Task { @MainActor [weak self] in
            _ = try await self?.cardPresentPaymentService.connectReader(using: .bluetooth)
        }
    }

    func disconnectCardReader() {
        analytics.track(.cardReaderDisconnectTapped)
        Task { @MainActor [weak self] in
            await self?.cardPresentPaymentService.disconnectReader()
        }
    }

    /// Starts a payment immediately if a reader is connected.
    /// Otherwise, schedules a payment to start the next time a reader connects.
    /// Note that any scheduled payments are cancelled by `cancelReaderPreparation`
    /// e.g. when the TotalsView goes offscreen.
    private func startPaymentWhenCardReaderConnected() async {
        guard case .connected = cardReaderConnectionStatus else {
            return startPaymentOnCardReaderConnection = cardPresentPaymentService.readerConnectionStatusPublisher
                .filter { status in
                    switch status {
                    case .connected:
                        return true
                    case .disconnected, .disconnecting, .cancellingConnection:
                        return false
                    }
                }
                .removeDuplicates()
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        await self?.collectCardPayment()
                    }
                }
        }
        await collectCardPayment()
    }

    @MainActor
    private func collectCardPayment() async {
        guard case let .loaded(totals, order) = internalOrderState,
              totals.orderTotalDecimal > 0.0
        else {
            return
            // Should this throw?
        }
        do {
            try await collectPayment(for: order)
        } catch {
            DDLogError("Error taking payment: \(error)")
        }
    }

    // Prevents card payments from the moment the merchant decides we start collecting cash
    // Once we get the callback from the card service, we switch to cash collection state
    @MainActor
    func startCashPayment() async {
        analytics.track(.pointOfSaleCashPaymentTapped)
        try? await cardPresentPaymentService.cancelPayment()
        paymentState.cash = .collectingCash
    }

    @MainActor
    func cancelCashPayment() async {
        analytics.track(.pointOfSaleBackToCheckoutFromCashTapped)
        paymentState.cash = .idle
        if case .connected = cardReaderConnectionStatus {
            await collectCardPayment()
        }
    }

    private func cashPaymentSuccess() {
        paymentState.cash = .paymentSuccess
        collectOrderPaymentAnalyticsTracker.trackSuccessfulCashPayment()
    }

    @MainActor
    func collectCashPayment(changeDueAmount: String?) async throws {
        try await orderController.collectCashPayment(changeDueAmount: changeDueAmount)
        cashPaymentSuccess()
    }

    @MainActor
    func sendReceipt(to emailAddress: String) async throws {
        try await orderController.sendReceipt(recipientEmail: emailAddress)
    }

    @MainActor
    private func collectPayment(for order: Order) async throws {
        _ = try await cardPresentPaymentService.collectPayment(for: order, using: .bluetooth, channel: .pos)
    }

    func cancelThenCollectPayment() {
        Task { [weak self] in
            guard let self else { return }
            await cancelThenCollectPayment()
        }
    }

    func cancelThenCollectPayment() async {
        try? await cardPresentPaymentService.cancelPayment()
        await collectCardPayment()
    }

    @Sendable private func setupReaderReconnectionObservation() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            switch orderStage {
                case .building:
                    cancelCardReaderPreparation()
                case .finalizing:
                    observeReaderReconnection()
            }
        } onChange: { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async(execute: setupReaderReconnectionObservation)
        }
    }

    private func cancelCardReaderPreparation() {
        cardPresentPaymentService.cancelPayment()
        resetCardReaderObservation()
    }

    private func resetCardReaderObservation() {
        // We set these to nil, so that we can check them when showing `Reader connected` on the Totals screen.
        startPaymentOnCardReaderConnection?.cancel()
        startPaymentOnCardReaderConnection = nil
        cardReaderDisconnection?.cancel()
        cardReaderDisconnection = nil
    }

    private func observeReaderReconnection() {
        cardReaderDisconnection = cardPresentPaymentService.readerConnectionStatusPublisher
            .filter({ $0 == .disconnected })
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.startPaymentWhenCardReaderConnected()
                }
            }
    }

    /// Called when the onboarding UI is dismissed.
    /// For external dismissal (tapping CTA to dismiss), this method is called twice - the first time to dismiss the onboarding UI
    /// by setting `cardPresentPaymentOnboardingViewModel` to nil, the second time triggered by internal dismissal.
    /// For internal dismissal (tapping outside the modal), this method is called once.
    /// This method is used to reset the internal state of the onboarding UI and track the dismissal event.
    func cancelCardPaymentsOnboarding() {
        guard let onboardingViewModel = cardPresentPaymentOnboardingViewModel else {
            return
        }
        analytics.track(event: .PointOfSale.paymentsOnboardingDismissed(onboardingState: onboardingViewModel.state))
        cardPresentPaymentOnboardingViewModel = nil
        onOnboardingCancellation?()
    }

    /// Tracks when the onboarding UI is shown.
    func trackCardPaymentsOnboardingShown() {
        analytics.track(event: .PointOfSale.paymentsOnboardingShown())
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleAggregateModel {
    func publishPaymentMessages() {
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentAlertType? in
                guard let self else { return nil }
                guard case let .show(eventDetails) = event,
                      case let .alert(alertType) = presentationStyle(for: eventDetails)
                else {
                    return nil
                }

                // Filter connection success alerts when we're immediately starting a payment
                if case .connectionSuccess = eventDetails,
                   startPaymentOnCardReaderConnection != nil {
                    return nil
                }

                return alertType
            }
            .sink(receiveValue: { [weak self] alertType in
                self?.cardPresentPaymentAlertViewModel = alertType
            })
            .store(in: &cancellables)

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .sink(receiveValue: { [weak self] message in
                self?.cardPresentPaymentInlineMessage = message
            })
            .store(in: &cancellables)

        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent -> PointOfSaleCardPaymentState? in
                guard let self else { return nil }

                let newCardPaymentState = PointOfSaleCardPaymentState(from: paymentEvent,
                                                                      using: presentationStyleDeterminerDependencies)

                if case .acceptingCard = newCardPaymentState {
                    collectOrderPaymentAnalyticsTracker.trackCardReaderReady()
                }

                if case .processingPayment = newCardPaymentState {
                    collectOrderPaymentAnalyticsTracker.trackCardReaderTapped()
                }

                return newCardPaymentState
            }
            .sink(receiveValue: { [weak self] cardPaymentState in
                self?.paymentState.card = cardPaymentState
            })
            .store(in: &cancellables)

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> CardPresentPaymentsOnboardingViewModel? in
                guard let self else { return nil }
                guard case let .showOnboarding(viewModel, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return viewModel
            }
            .sink(receiveValue: { [weak self] onboardingViewModel in
                self?.cardPresentPaymentOnboardingViewModel = onboardingViewModel
            })
            .store(in: &cancellables)
    }

    /// Maps PaymentEvent to POSMessageType and annonates additional information if necessary
    /// - Parameter event: CardPresentPaymentEvent
    /// - Returns: PointOfSaleCardPresentPaymentMessageType
    func mapCardPresentPaymentEventToMessageType(_ event: CardPresentPaymentEvent) -> PointOfSaleCardPresentPaymentMessageType? {
        guard case let .show(eventDetails) = event,
              case let .message(messageType) = presentationStyle(for: eventDetails) else {
            return nil
        }

        return messageType
    }

    func presentationStyle(for eventDetails: CardPresentPaymentEventDetails) -> PointOfSaleCardPresentPaymentEventPresentationStyle? {
        PointOfSaleCardPresentPaymentEventPresentationStyle(
            for: eventDetails,
            dependencies: presentationStyleDeterminerDependencies)
    }

    var presentationStyleDeterminerDependencies: PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies {
        let cancelThenCollectPaymentWithWeakSelf: () -> Void = { [weak self] in
            self?.cancelThenCollectPayment()
        }

        var orderTotal: String?
        if case .loaded(let totals) = orderState {
            orderTotal = totals.orderTotal
        }

        return PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: cancelThenCollectPaymentWithWeakSelf,
            nonRetryableErrorExitAction: cancelThenCollectPaymentWithWeakSelf,
            formattedOrderTotalPrice: orderTotal,
            paymentCaptureErrorTryAgainAction: cancelThenCollectPaymentWithWeakSelf,
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.startNewCart()
            },
            paymentIntentCreationErrorEditOrderAction: { [weak self] in
                self?.addMoreToCart()
            },
            dismissReaderConnectionModal: { [weak self] in
                self?.cardPresentPaymentAlertViewModel = nil
            }
        )
    }
}

// MARK: - Order syncing
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    @MainActor
    func checkOut() async {
        collectOrderPaymentAnalyticsTracker.trackCheckoutTapped()
        orderStage = .finalizing
        let syncOrderResult = await orderController.syncOrder(for: cart, retryHandler: { [weak self] in
            await self?.checkOut()
        })
        trackOrderSyncState(syncOrderResult)
        await startPaymentWhenCardReaderConnected()
    }
}

// MARK: - Lifecycle
@available(iOS 17.0, *)
extension PointOfSaleAggregateModel {
    func pointOfSaleClosed() {
        // We cancel any payment to prevent the reader from remaining live and awaiting a card tap. Otherwise, it would
        // wait until the timeout, which is 30-45 minutes. In that time, it uses more battery, and may result
        // in a shopper paying for the wrong order.
        Task { [cardPresentPaymentService] in
            try await cardPresentPaymentService.cancelPayment()
        }

        // Before exiting Point of Sale, we warn the merchant about losing their in-progress order.
        // We need to clear it down as any accidental retention can cause issues especially when reconnecting card readers.
        Task {
            await orderController.clearOrder()
        }

        // Ideally, we could rely on the POS being deallocated to cancel all these. Since we have memory leak issues,
        // cancelling them explicitly helps reduce the risk of user-visible bugs while we work on the memory leaks.
        resetCardReaderObservation()
        cancellables.forEach { $0.cancel() }
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleAggregateModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}
