import CocoaLumberjackSwift
import Foundation
import Combine
import Observation

import protocol Yosemite.POSOrderableItem
import protocol WooFoundation.Analytics
import struct Networking.Order
import struct Yosemite.OrderItem
import struct Yosemite.POSCoupon
import enum Yosemite.POSItem
import enum Yosemite.SystemStatusAction
import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItemType
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import enum Yosemite.PointOfSaleBarcodeScanError
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import class Yosemite.POSCatalogSyncCoordinator
import enum Yosemite.CardReaderSoftwareUpdateState
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation
import protocol Yosemite.POSStoreAPICheckoutServiceProtocol
import struct Yosemite.POSCart
import struct Yosemite.POSStoreAPICheckoutResult
import struct Yosemite.POSGiftCardItemInfo

protocol PointOfSaleAggregateModelProtocol {
    var cart: Cart { get }
    func addToCart(_ item: POSItem)

    func saveSearchTerm(_ term: String, for itemType: POSItemType)
}

@Observable final class PointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    private(set) var orderStage: PointOfSaleOrderStage = .building

    private(set) var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
    private(set) var cardReaderUpdateState: CardReaderSoftwareUpdateState = .none
    private(set) var paymentState: PointOfSalePaymentState
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    var cardPresentPaymentOnboardingViewContainer: CardPresentPaymentOnboardingViewContainer?
    private var onOnboardingCancellation: (() -> Void)?

    var isCardReaderUpdateAvailable: Bool {
        if case .available = cardReaderUpdateState {
            return true
        }
        return false
    }

    private(set) var cart: Cart = .init()

    var orderState: PointOfSaleOrderState { orderController.orderState.externalState }
    private var internalOrderState: PointOfSaleInternalOrderState { orderController.orderState }

    let entryPointController: POSEntryPointController
    let purchasableItemsController: PointOfSaleItemsControllerProtocol
    let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol
    let couponsController: PointOfSaleCouponsControllerProtocol
    let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol
    let settingsController: POSSettingsControllerProtocol

    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let analytics: POSAnalyticsProviding
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    let searchHistoryService: POSSearchHistoryProviding
    private let barcodeScanService: PointOfSaleBarcodeScanServiceProtocol
    private let siteID: Int64
    private let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol?
    private let storeAPICheckoutService: POSStoreAPICheckoutServiceProtocol?

    /// Result from Store API checkout, used for card payment capture.
    private var storeAPICheckoutResult: POSStoreAPICheckoutResult?

    private var startPaymentOnCardReaderConnection: AnyCancellable?
    private var cardReaderDisconnection: AnyCancellable?

    private let soundPlayer: PointOfSaleSoundPlayerProtocol

    /// Indicates whether the local catalog feature is enabled for this store
    let isLocalCatalogEligible: Bool

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

    // Track stale sync warning (only relevant when using local catalog)
    var isSyncStale: Bool = false
    var isStaleSyncWarningDismissed: Bool = false

    // Billing email for downloadable products checkout
    private(set) var billingEmail: String = ""

    /// Whether checkout requires an email (cart contains downloadable items)
    var requiresEmailForCheckout: Bool {
        cart.containsDownloadableItems
    }

    /// Whether the email is valid (basic validation)
    private var isValidEmail: Bool {
        billingEmail.contains("@") && billingEmail.contains(".")
    }

    // Gift card info per cart item (keyed by Cart.PurchasableItem UUID)
    private(set) var giftCardInfo: [UUID: GiftCardInfo] = [:]

    /// Whether checkout requires gift card info (cart contains gift cards)
    var requiresGiftCardInfoForCheckout: Bool {
        cart.containsGiftCards
    }

    /// Whether all gift cards in the cart have their required info
    var allGiftCardsHaveInfo: Bool {
        cart.giftCardItems.allSatisfy { item in
            giftCardInfo[item.id] != nil
        }
    }

    /// Whether checkout can proceed (all required data is present)
    var canProceedWithCheckout: Bool {
        let emailOK = !requiresEmailForCheckout || isValidEmail
        let giftCardOK = !requiresGiftCardInfoForCheckout || allGiftCardsHaveInfo
        return emailOK && giftCardOK
    }

    var showStaleSyncWarning: Bool {
        // Only show warning if using local catalog
        guard isLocalCatalogEligible else {
            return false
        }
        return isSyncStale && !isStaleSyncWarningDismissed
    }

    init(entryPointController: POSEntryPointController,
         itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         settingsController: POSSettingsControllerProtocol,
         analytics: POSAnalyticsProviding,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularPurchasableItemsController: PointOfSaleItemsControllerProtocol,
         barcodeScanService: PointOfSaleBarcodeScanServiceProtocol,
         soundPlayer: PointOfSaleSoundPlayerProtocol = PointOfSaleSoundPlayer(),
         paymentState: PointOfSalePaymentState = .idle,
         siteID: Int64,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = nil,
         isLocalCatalogEligible: Bool = false,
         storeAPICheckoutService: POSStoreAPICheckoutServiceProtocol? = nil) {
        self.entryPointController = entryPointController
        self.purchasableItemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.settingsController = settingsController
        self.analytics = analytics
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.paymentState = paymentState
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.barcodeScanService = barcodeScanService
        self.soundPlayer = soundPlayer
        self.siteID = siteID
        self.catalogSyncCoordinator = catalogSyncCoordinator
        self.isLocalCatalogEligible = isLocalCatalogEligible
        self.storeAPICheckoutService = storeAPICheckoutService

        publishCardReaderConnectionStatus()
        publishCardReaderUpdateState()
        publishPaymentMessages()
        setupReaderReconnectionObservation()
        setupPaymentSuccessObservation()
        performInitialSyncIfNeeded()
    }
}

// MARK: - Cart
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
        orderController.clearOrder()
        setStateForEditing()
        viewStateCoordinator.reset()
        billingEmail = ""
        giftCardInfo = [:]
    }

    func setBillingEmail(_ email: String) {
        billingEmail = email
    }

    func setGiftCardInfo(_ info: GiftCardInfo, for itemID: UUID) {
        giftCardInfo[itemID] = info
    }

    func removeGiftCardInfo(for itemID: UUID) {
        giftCardInfo[itemID] = nil
    }

    private func setStateForEditing() {
        orderStage = .building
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
    }

    /// Removes missing products from the cart only (catalog is auto-cleaned when errors are detected)
    /// - Parameters:
    ///   - productIDs: Product IDs to remove (for simple products)
    ///   - variationIDs: Variation IDs to remove (for variations)
    func removeMissingProductsFromCart(productIDs: Set<Int64>, variationIDs: Set<Int64>) {
        cart.purchasableItems.removeAll { item in
            guard case .loaded(let orderableItem) = item.state else { return false }

            // Check if it's a simple product matching the product IDs
            if let simpleProduct = orderableItem as? POSSimpleProduct {
                return productIDs.contains(simpleProduct.productID)
            }
            // Check if it's a variation matching the variation IDs
            else if let variation = orderableItem as? POSVariation {
                return variationIDs.contains(variation.productVariationID)
            }
            return false
        }
    }

    /// Removes identified missing products from the catalog only (not from cart)
    /// - Parameter missingProducts: Array of missing product info
    private func removeIdentifiedMissingProductsFromCatalog(_ missingProducts: [PointOfSaleOrderState.OrderStateError.MissingProductInfo]) async {
        let (productIDs, variationIDs) = missingProducts.extractProductAndVariationIDs()

        // Remove from local catalog only if we have identifiable products
        guard !productIDs.isEmpty || !variationIDs.isEmpty else { return }

        if let catalogSyncCoordinator {
            do {
                try await catalogSyncCoordinator.deleteProductsFromCatalog(
                    Array(productIDs),
                    variationIDs: Array(variationIDs),
                    siteID: siteID
                )
                DDLogInfo("🗑️ Auto-removed \(productIDs.count) products and \(variationIDs.count) variations from local catalog (unavailable items)")
            } catch {
                DDLogError("⚠️ Failed to auto-remove unavailable products from local catalog: \(error)")
            }
        }
    }
}

// MARK: - Barcode Scanning
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
extension PointOfSaleAggregateModel {
    func saveSearchTerm(_ term: String, for itemType: POSItemType) {
        searchHistoryService.saveSuccessfulSearch(term: term, for: itemType)
    }
}

// MARK: - Track events
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
extension PointOfSaleAggregateModel {
    private func publishCardReaderConnectionStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .sink(receiveValue: { [weak self] connectionStatus in
                self?.cardReaderConnectionStatus = connectionStatus
            })
            .store(in: &cancellables)
    }

    private func publishCardReaderUpdateState() {
        cardPresentPaymentService.cardReaderUpdateStatePublisher
            .sink(receiveValue: { [weak self] updateState in
                self?.cardReaderUpdateState = updateState
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

    func updateCardReaderSoftware() {
        //TODO: analytics.track(.cardReaderUpdateTapped)
        Task { @MainActor [weak self] in
            try? await self?.cardPresentPaymentService.updateCardReaderSoftware()
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
        // If we have a Store API checkout result, use that for payment
        if let checkoutResult = storeAPICheckoutResult,
           let checkoutService = storeAPICheckoutService {
            do {
                try await collectPOSPaymentViaStoreAPI(
                    checkoutResult: checkoutResult,
                    checkoutService: checkoutService
                )
            } catch {
                DDLogError("Error taking POS Store API payment: \(error)")
            }
            return
        }

        // Fall back to REST API order-based payment
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

    /// Collects card payment using Store API for capture.
    ///
    @MainActor
    private func collectPOSPaymentViaStoreAPI(
        checkoutResult: POSStoreAPICheckoutResult,
        checkoutService: POSStoreAPICheckoutServiceProtocol
    ) async throws {
        // Get the order from createOrderAndTotals (reusing the same order we set on orderController)
        let (order, _) = createOrderAndTotals(from: checkoutResult)

        // Create capture handler that uses Store API checkout
        let captureHandler: (String) async throws -> Void = { [checkoutService] paymentIntentID in
            DDLogInfo("🔄 Capturing POS payment via Store API with payment intent: \(paymentIntentID)")
            _ = try await checkoutService.captureCardPayment(paymentIntentID: paymentIntentID)
            DDLogInfo("✅ POS payment captured successfully")
        }

        _ = try await cardPresentPaymentService.collectPOSPayment(
            for: order,
            using: .bluetooth,
            captureHandler: captureHandler
        )

        // Clear the checkout result after successful payment
        storeAPICheckoutResult = nil
    }

    // Prevents card payments from the moment the merchant decides we start collecting cash
    // Once we get the callback from the card service, we switch to cash collection state
    @MainActor
    func startCashPayment() async {
        analytics.track(.pointOfSaleCheckoutCashPaymentTapped)
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
    /// by setting `cardPresentPaymentOnboardingViewContainer` to nil, the second time triggered by internal dismissal.
    /// For internal dismissal (tapping outside the modal), this method is called once.
    /// This method is used to reset the internal state of the onboarding UI and track the dismissal event.
    func cancelCardPaymentsOnboarding() {
        guard let onboardingViewContainer = cardPresentPaymentOnboardingViewContainer else {
            return
        }
        analytics.track(event: .PointOfSale.paymentsOnboardingDismissed(onboardingState: onboardingViewContainer.configuration.state))
        cardPresentPaymentOnboardingViewContainer = nil
        onOnboardingCancellation?()
    }

    /// Tracks when the onboarding UI is shown.
    func trackCardPaymentsOnboardingShown() {
        analytics.track(event: .PointOfSale.paymentsOnboardingShown())
    }
}

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
            .map { [weak self] event -> CardPresentPaymentOnboardingViewContainer? in
                guard let self else { return nil }
                guard case let .showOnboarding(factory, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return factory
            }
            .sink(receiveValue: { [weak self] factory in
                self?.cardPresentPaymentOnboardingViewContainer = factory
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
extension PointOfSaleAggregateModel {
    @MainActor
    func checkOut() async {
        collectOrderPaymentAnalyticsTracker.trackCheckoutTapped()
        orderStage = .finalizing

        // Guard for downloadable products - checkout button should be disabled
        // when email is required but not provided, but this is a safety check
        guard canProceedWithCheckout else {
            return
        }

        await performCheckout()
    }

    @MainActor
    private func performCheckout() async {
        // Use Store API checkout if service is available
        if let storeAPICheckoutService {
            await checkOutViaStoreAPI(checkoutService: storeAPICheckoutService)
        } else {
            // Fall back to REST API order sync
            let syncOrderResult = await orderController.syncOrder(for: cart, retryHandler: { [weak self] in
                await self?.checkOut()
            })
            trackOrderSyncState(syncOrderResult)
            await removeMissingProductsFromCatalogAfterSync()
            await startPaymentWhenCardReaderConnected()
        }
    }

    /// Performs checkout via Store API for card payments.
    ///
    /// This creates a pending order using Store API checkout with `pos_card` payment method.
    /// The order is completed when the card payment is captured.
    ///
    @MainActor
    private func checkOutViaStoreAPI(checkoutService: POSStoreAPICheckoutServiceProtocol) async {
        do {
            let posCart = POSCart(cart: cart)

            // Convert local GiftCardInfo to POSGiftCardItemInfo for the API
            let posGiftCardInfo = giftCardInfo.mapValues { info in
                POSGiftCardItemInfo(recipientEmail: info.recipientEmail, senderName: info.senderName)
            }

            // Call Store API checkout with pos_card to create pending order
            // Pass billing email for downloadable product fulfillment
            // Pass gift card info for gift card products
            let checkoutResult = try await checkoutService.checkout(
                cart: posCart,
                paymentMethod: .card,
                billingEmail: billingEmail.isEmpty ? nil : billingEmail,
                giftCardInfo: posGiftCardInfo
            )

            DDLogInfo("✅ Store API checkout created order \(checkoutResult.checkoutResponse.orderID)")

            // Store the checkout result for use in card payment capture
            storeAPICheckoutResult = checkoutResult

            // Create the order and totals for the UI
            let (order, totals) = createOrderAndTotals(from: checkoutResult)
            orderController.setOrderState(totals: totals, order: order)

            // Track analytics for order sync success
            collectOrderPaymentAnalyticsTracker.trackOrderSyncSuccess()

            // Start payment collection when card reader is connected
            await startPaymentWhenCardReaderConnected()
        } catch {
            DDLogError("⛔️ Store API checkout failed: \(error)")
            // TODO: Handle error state - for now, fall back to REST API
            let syncOrderResult = await orderController.syncOrder(for: cart, retryHandler: { [weak self] in
                await self?.checkOut()
            })
            trackOrderSyncState(syncOrderResult)
            await removeMissingProductsFromCatalogAfterSync()
            await startPaymentWhenCardReaderConnected()
        }
    }

    /// Creates an Order and PointOfSaleOrderTotals from Store API checkout result.
    ///
    private func createOrderAndTotals(from checkoutResult: POSStoreAPICheckoutResult) -> (Order, PointOfSaleOrderTotals) {
        let cartTotals = checkoutResult.cartTotals

        // Create Order object with properly formatted totals
        let order = Order(
            siteID: siteID,
            orderID: checkoutResult.checkoutResponse.orderID,
            parentID: 0,
            customerID: 0,
            orderKey: checkoutResult.checkoutResponse.orderKey,
            isEditable: false,
            needsPayment: true,
            needsProcessing: false,
            number: String(checkoutResult.checkoutResponse.orderID),
            status: .pending,
            currency: cartTotals.currencyCode,
            currencySymbol: cartTotals.currencySymbol,
            customerNote: nil,
            dateCreated: Date(),
            dateModified: Date(),
            datePaid: nil,
            discountTotal: cartTotals.formatAsDecimalString(cartTotals.totalDiscount),
            discountTax: cartTotals.formatAsDecimalString(cartTotals.totalDiscountTax),
            shippingTotal: cartTotals.formatAsDecimalString(cartTotals.totalShipping),
            shippingTax: cartTotals.formatAsDecimalString(cartTotals.totalShippingTax),
            total: cartTotals.formatAsDecimalString(cartTotals.totalPrice),
            totalTax: cartTotals.formatAsDecimalString(cartTotals.totalTax),
            paymentMethodID: "pos_card",
            paymentMethodTitle: "POS Card",
            paymentURL: nil,
            chargeID: nil,
            items: [],
            billingAddress: nil,
            shippingAddress: nil,
            shippingLines: [],
            coupons: [],
            refunds: [],
            fees: [],
            taxes: [],
            customFields: [],
            renewalSubscriptionID: nil,
            appliedGiftCards: [],
            attributionInfo: nil,
            shippingLabels: [],
            createdVia: "store-api"
        )

        // Create formatted totals for display
        let totals = PointOfSaleOrderTotals(
            cartTotal: cartTotals.formatAsCurrencyString(cartTotals.totalItems),
            orderTotal: cartTotals.formatAsCurrencyString(cartTotals.totalPrice),
            taxTotal: cartTotals.formatAsCurrencyString(cartTotals.totalTax),
            orderTotalDecimal: cartTotals.totalPriceDecimal,
            discountTotal: Int(cartTotals.totalDiscount) ?? 0 > 0 ? cartTotals.formatAsCurrencyString(cartTotals.totalDiscount) : nil
        )

        return (order, totals)
    }

    /// Removes unavailable products from the local catalog after detecting them during order sync
    @MainActor
    private func removeMissingProductsFromCatalogAfterSync() async {
        // If we identified specific missing products, remove them from the catalog immediately
        if case .error(.missingProducts(let missingProducts), _) = orderController.orderState.externalState {
            await removeIdentifiedMissingProductsFromCatalog(missingProducts)
        }
    }
}

// MARK: - Lifecycle
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
        orderController.clearOrder()

        // Ideally, we could rely on the POS being deallocated to cancel all these. Since we have memory leak issues,
        // cancelling them explicitly helps reduce the risk of user-visible bugs while we work on the memory leaks.
        resetCardReaderObservation()
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Incremental catalog sync on payment success

private extension PointOfSaleAggregateModel {
    @Sendable private func setupPaymentSuccessObservation() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            if paymentState.isSuccess {
                performIncrementalSync()
            }
        } onChange: { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async(execute: setupPaymentSuccessObservation)
        }
    }

    private func performIncrementalSync() {
        guard let catalogSyncCoordinator else { return }
        let popularPurchasableItemsController = popularPurchasableItemsController
        let siteID = siteID
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    try? await catalogSyncCoordinator.performIncrementalSync(for: siteID)
                }
                group.addTask {
                    await popularPurchasableItemsController.refreshItems(base: .root)
                }
            }
        }
    }

    private func performInitialSyncIfNeeded() {
        guard let catalogSyncCoordinator else { return }
        Task {
            try? await catalogSyncCoordinator.performSmartSync(for: siteID)
        }
    }
}

// MARK: - Stale Sync Warning
extension PointOfSaleAggregateModel {
    var staleSyncThresholdDays: Int {
        Constants.staleSyncThresholdDays
    }

    func dismissStaleSyncWarning() {
        isStaleSyncWarningDismissed = true
    }

    func checkStaleSyncStatus() async {
        guard let catalogSyncCoordinator else { return }
        isSyncStale = await catalogSyncCoordinator.isSyncStale(for: siteID, maxDays: Constants.staleSyncThresholdDays)
    }

    /// Calculates the number of hours since the last catalog sync
    /// - Returns: Hours since last sync, or nil if no sync date is available
    func hoursSinceLastSync() async -> Int? {
        guard let catalogSyncCoordinator else { return nil }
        return await catalogSyncCoordinator.hoursSinceLastSync(for: siteID)
    }
}

// MARK: - Constants
private enum Constants {
    /// Number of days before showing a stale catalog sync warning
    static let staleSyncThresholdDays: Int = 7
}

#if DEBUG
extension PointOfSaleAggregateModel {
    func setPreviewState(paymentState: PointOfSalePaymentState, inlineMessage: PointOfSaleCardPresentPaymentMessageType?) {
        self.paymentState = paymentState
        self.cardPresentPaymentInlineMessage = inlineMessage
    }
}
#endif
