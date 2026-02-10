import CocoaLumberjackSwift
import Foundation
import Combine
import Observation

import protocol Yosemite.POSOrderableItem
import protocol Yosemite.PaymentCaptureCelebrationProtocol
import class Yosemite.PaymentCaptureCelebration
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
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import class Yosemite.POSCatalogSyncCoordinator
import enum Yosemite.CardReaderSoftwareUpdateState
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

protocol PointOfSaleAggregateModelProtocol {
    var cart: Cart { get }
    func addToCart(_ item: POSItem)

    func saveSearchTerm(_ term: String, for itemType: POSItemType)
}

@Observable final class PointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    private(set) var orderStage: PointOfSaleOrderStage = .building

    let paymentModel: POSPaymentModel

    var cardReaderConnectionStatus: CardPresentPaymentReaderConnectionStatus { paymentModel.cardReaderConnectionStatus }
    private(set) var cardReaderUpdateState: CardReaderSoftwareUpdateState = .none
    var paymentState: PointOfSalePaymentState { paymentModel.paymentState }
    var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType? {
        get { paymentModel.cardPresentPaymentAlertViewModel }
        set { paymentModel.cardPresentPaymentAlertViewModel = newValue }
    }
    var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType? { paymentModel.cardPresentPaymentInlineMessage }
    var cardPresentPaymentOnboardingViewContainer: CardPresentPaymentOnboardingViewContainer? {
        get { paymentModel.cardPresentPaymentOnboardingViewContainer }
        set { paymentModel.cardPresentPaymentOnboardingViewContainer = newValue }
    }

    var isCardReaderUpdateAvailable: Bool {
        if case .available = cardReaderUpdateState {
            return true
        }
        return false
    }

    private(set) var cart: Cart = .init()

    var orderState: PointOfSaleOrderState { orderController.orderState.externalState }

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
         receiptSender: POSReceiptSending,
         soundPlayer: PointOfSaleSoundPlayerProtocol = PointOfSaleSoundPlayer(),
         celebration: PaymentCaptureCelebrationProtocol = PaymentCaptureCelebration(),
         paymentState: PointOfSalePaymentState = .idle,
         siteID: Int64,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol? = nil,
         isLocalCatalogEligible: Bool = false) {
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
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.barcodeScanService = barcodeScanService
        self.soundPlayer = soundPlayer
        self.siteID = siteID
        self.catalogSyncCoordinator = catalogSyncCoordinator
        self.isLocalCatalogEligible = isLocalCatalogEligible

        // Payment controller is created with cart-specific dependencies.
        // The weak self captures below are safe because paymentModel is owned by self.
        var weakSelf: PointOfSaleAggregateModel?
        self.paymentModel = POSPaymentModel(
            cardPresentPaymentService: cardPresentPaymentService,
            orderProvider: POSCartPaymentOrderProvider(orderController: orderController),
            cashPaymentHandler: POSCartCashPaymentHandler(orderController: orderController),
            receiptSender: receiptSender,
            configuration: .cart(
                onNewOrder: { weakSelf?.startNewCart() },
                onEditOrder: { weakSelf?.addMoreToCart() }),
            analytics: analytics,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
            celebration: celebration,
            paymentState: paymentState)
        weakSelf = self

        publishCardReaderUpdateState()
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
    }

    private func setStateForEditing() {
        orderStage = .building
        paymentModel.reset()
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

// MARK: - Payment (delegated to POSPaymentModel)
extension PointOfSaleAggregateModel {
    private func publishCardReaderUpdateState() {
        cardPresentPaymentService.cardReaderUpdateStatePublisher
            .sink(receiveValue: { [weak self] updateState in
                self?.cardReaderUpdateState = updateState
            })
            .store(in: &cancellables)
    }

    func connectCardReader() {
        paymentModel.connectCardReader()
    }

    func disconnectCardReader() {
        paymentModel.disconnectCardReader()
    }

    func updateCardReaderSoftware() {
        paymentModel.updateCardReaderSoftware()
    }

    func startCashPayment() async {
        await paymentModel.startCashPayment()
    }

    func cancelCashPayment() async {
        await paymentModel.cancelCashPayment()
    }

    func collectCashPayment(changeDueAmount: String?) async throws {
        try await paymentModel.collectCashPayment(changeDueAmount: changeDueAmount)
    }

    func sendReceipt(to emailAddress: String) async throws {
        try await paymentModel.sendReceipt(to: emailAddress)
    }

    func cancelThenCollectPayment() {
        paymentModel.cancelThenCollectPayment()
    }

    func cancelThenCollectPayment() async {
        await paymentModel.cancelThenCollectPayment()
    }

    func cancelCardPaymentsOnboarding() {
        paymentModel.cancelCardPaymentsOnboarding()
    }

    func trackCardPaymentsOnboardingShown() {
        paymentModel.trackCardPaymentsOnboardingShown()
    }

    @Sendable private func setupReaderReconnectionObservation() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            switch orderStage {
                case .building:
                    paymentModel.cancelReaderReconnectionObservation()
                case .finalizing:
                    paymentModel.observeReaderReconnection()
            }
        } onChange: { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async(execute: setupReaderReconnectionObservation)
        }
    }
}

// MARK: - Order syncing
extension PointOfSaleAggregateModel {
    @MainActor
    func checkOut() async {
        collectOrderPaymentAnalyticsTracker.trackCheckoutTapped()
        orderStage = .finalizing
        let syncOrderResult = await orderController.syncOrder(for: cart, retryHandler: { [weak self] in
            await self?.checkOut()
        })
        trackOrderSyncState(syncOrderResult)
        await removeMissingProductsFromCatalogAfterSync()
        await paymentModel.startPayment()
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
        // Before exiting Point of Sale, we warn the merchant about losing their in-progress order.
        // We need to clear it down as any accidental retention can cause issues especially when reconnecting card readers.
        orderController.clearOrder()

        // Ideally, we could rely on the POS being deallocated to cancel all these. Since we have memory leak issues,
        // cancelling them explicitly helps reduce the risk of user-visible bugs while we work on the memory leaks.
        paymentModel.tearDown()
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
        paymentModel.setPreviewState(paymentState: paymentState, inlineMessage: inlineMessage)
    }
}
#endif
