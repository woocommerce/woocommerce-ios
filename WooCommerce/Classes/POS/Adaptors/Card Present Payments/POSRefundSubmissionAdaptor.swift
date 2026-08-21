import Combine
import Foundation
import PointOfSale
import protocol Storage.StorageManagerType
import UIKit
import Yosemite
import WooFoundation

/// Prepares, previews and submits POS refunds.
///
/// Holds the second of the two checks a `compute_totals` create needs. `POSRefundFlowResolver`
/// checks the site's WooCommerce version, which decides whether a preview runs at all. A successful
/// preview stores its total under the selection it was calculated for. `submitRefund` sends
/// computed line items only when a total exists for the selection being submitted. Every other case
/// uses the classic v3 create.
///
@MainActor
final class POSRefundSubmissionAdaptor: POSRefundSubmissionProcessing {
    let stateModel = POSRefundSubmissionModel()

    private struct PreparedRefundSnapshot {
        let preparation: POSRefundPreparation
        let context: POSRefundSubmissionMapping.PreparedRefundContext
    }

    private let orderService: POSOrderServiceProtocol
    private let refundService: RefundServiceProtocol
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter
    private let refundMapping: POSRefundSubmissionMapping
    private let analytics: Analytics
    private let refundOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol
    private let serverRefundPreviewUseCase: POSServerRefundPreviewUseCase

    private var preloadedRefundSnapshots: [Int64: PreparedRefundSnapshot] = [:]
    private var preloadTasks: [Int64: (id: UUID, task: Task<PreparedRefundSnapshot, Error>)] = [:]
    private var preparedContexts: [Int64: POSRefundSubmissionMapping.PreparedRefundContext] = [:]
    /// Identifies one refund selection within an order. Two selections of the same items are the
    /// same key, and any change to which units are selected produces a different one.
    private struct SelectionKey: Hashable {
        let orderID: Int64
        private let selectedItemIDs: Set<String>

        init(orderID: Int64, selectedItems: [POSRefundSelectableItem]) {
            self.orderID = orderID
            self.selectedItemIDs = Set(selectedItems.map(\.id))
        }
    }

    /// Server-calculated totals from a successful preview, keyed by the selection they were
    /// calculated for. Keying by selection rather than by order is what makes the displayed total
    /// and the submitted total the same value: a preview for a superseded selection cannot be read
    /// back for a different one, so overlapping previews resolving out of order can no longer leave
    /// the submit path using a total the cashier never saw.
    private var serverPreviewTotals: [SelectionKey: Decimal] = [:]
    private var submissionUseCase: RefundSubmissionUseCase<CardPresentPaymentBluetoothReaderConnectionAlertsProvider, POSRefundCardPresentPaymentAlertsPresenter>?
    private var onboardingSubscription: AnyCancellable?

    init(orderService: POSOrderServiceProtocol,
         refundService: RefundServiceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         refundOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol = OrderRefundsOptionsDeterminer(),
         serverRefundPreviewUseCase: POSServerRefundPreviewUseCase) {
        self.orderService = orderService
        self.refundService = refundService
        self.stores = stores
        self.storageManager = storageManager
        self.currencySettings = currencySettings
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.currencyFormatter = currencyFormatter
        self.refundMapping = POSRefundSubmissionMapping(currencyFormatter: currencyFormatter)
        self.analytics = analytics
        self.refundOptionsDeterminer = refundOptionsDeterminer
        self.serverRefundPreviewUseCase = serverRefundPreviewUseCase
    }

    func preloadRefund(for order: POSOrder) async {
        removePreloadedRefunds(except: order.id)

        guard preloadedRefundSnapshots[order.id] == nil,
              preloadTasks[order.id] == nil else {
            return
        }

        let preloadID = UUID()
        let preloadTask = Task { @MainActor in
            try await loadPreparedRefundSnapshot(for: order)
        }
        preloadTasks[order.id] = (id: preloadID, task: preloadTask)

        do {
            let snapshot = try await preloadTask.value
            guard preloadTasks[order.id]?.id == preloadID else {
                return
            }
            preloadedRefundSnapshots[order.id] = snapshot
            preloadTasks[order.id] = nil
        } catch {
            guard preloadTasks[order.id]?.id == preloadID else {
                return
            }
            preloadTasks[order.id] = nil
        }
    }

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        stateModel.state = .loading
        defer {
            stateModel.reset()
        }

        let snapshot = try await preparedRefundSnapshot(for: order)
        preparedContexts[snapshot.preparation.orderID] = snapshot.context

        return snapshot.preparation
    }

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) async throws -> POSRefundReviewData {
        guard let context = preparedContexts[preparation.orderID] else {
            throw POSRefundSubmissionAdaptorError.missingPreparedRefund
        }

        // Reset only this selection's total. Other selections keep theirs, so a preview that
        // resolves late cannot invalidate the selection the cashier is actually looking at.
        let selectionKey = SelectionKey(orderID: preparation.orderID, selectedItems: selectedItems)
        serverPreviewTotals[selectionKey] = nil

        let lineItems = refundMapping.refundPreviewLineItems(from: selectedItems, context: context)
        let previewResult = await serverRefundPreviewUseCase.previewRefund(siteID: context.order.siteID,
                                                                           orderID: context.order.orderID,
                                                                           lineItems: lineItems)
        try Task.checkCancellation()

        switch previewResult {
        case .serverCalculated(let preview):
            serverPreviewTotals[selectionKey] = preview.total
            return reviewData(subtotal: preview.subtotal,
                              tax: preview.tax,
                              total: preview.total,
                              context: context,
                              preparation: preparation,
                              selectedItems: selectedItems,
                              reason: reason)
        case .fallbackToLocal:
            serverPreviewTotals[selectionKey] = nil
            let components = refundMapping.refundComponents(from: selectedItems, context: context)
            let values = refundMapping.refundValues(items: components.items, fees: components.fees)
            return reviewData(subtotal: values.subtotal,
                              tax: values.tax,
                              total: values.total,
                              context: context,
                              preparation: preparation,
                              selectedItems: selectedItems,
                              reason: reason)
        case .rejected(let rejection):
            // The server rejected this selection with an actionable code; the typed rejection
            // carries the cashier-facing copy shown inline on the selection step.
            throw rejection
        case .error:
            // The use case has already logged the underlying error; the cashier sees the generic
            // preview failure with a retry affordance.
            throw POSRefundSubmissionError.refundPreviewFailed
        }
    }

    private func reviewData(subtotal: Decimal,
                            tax: Decimal,
                            total: Decimal,
                            context: POSRefundSubmissionMapping.PreparedRefundContext,
                            preparation: POSRefundPreparation,
                            selectedItems: [POSRefundSelectableItem],
                            reason: String?) -> POSRefundReviewData {
        POSRefundReviewData(itemsCount: selectedItems.count,
                            formattedItemsSubtotal: currencyFormatter.formatAmount(subtotal, with: context.order.currency) ?? "",
                            formattedTax: currencyFormatter.formatAmount(tax, with: context.order.currency) ?? "",
                            formattedRefundTotal: currencyFormatter.formatAmount(total, with: context.order.currency) ?? "",
                            paymentMethodDescription: preparation.paymentMethodDescription,
                            customerEmail: preparation.customerEmail,
                            refundReason: reason,
                            isFullRefund: selectedItems.count == preparation.selectableItems.count)
    }

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws {
        guard submissionUseCase == nil else {
            throw POSRefundSubmissionAdaptorError.refundAlreadyInProgress
        }

        guard let context = preparedContexts[preparation.orderID] else {
            throw POSRefundSubmissionAdaptorError.missingPreparedRefund
        }

        let components = refundMapping.refundComponents(from: selectedItems, context: context)
        let values = refundMapping.refundValues(items: components.items, fees: components.fees)
        // A server-computed create is only allowed when this exact selection was previewed
        // successfully; otherwise the classic v3 create path is used.
        let serverPreviewTotal = serverPreviewTotals[SelectionKey(orderID: preparation.orderID,
                                                                 selectedItems: selectedItems)]
        let serverLineItems = serverPreviewTotal != nil ? refundMapping.computedRefundLineItems(from: selectedItems, context: context) : nil
        let amount = refundMapping.apiAmountString(for: serverPreviewTotal ?? values.total)
        let refund = RefundCreationUseCase(amount: amount,
                                           reason: reason,
                                           automaticallyRefundsPayment: refundMapping.gatewaySupportsAutomaticRefunds(context: context),
                                           items: components.items,
                                           shippingLines: [],
                                           fees: components.fees,
                                           currencyFormatter: currencyFormatter)
            .createRefund()

        let requiresCardPresentRefund = refundMapping.requiresCardPresentRefund(context: context)
        let submittingState: POSRefundSubmissionState = requiresCardPresentRefund ? .submittingCardPresent : .submitting
        stateModel.state = submittingState
        let cancellationState = POSRefundCancellationState()

        let onboardingPresenter = CardPresentPaymentsOnboardingPresenterAdaptor(stores: stores)
        observe(onboardingPresenter: onboardingPresenter,
                submittingState: submittingState,
                cancellationState: cancellationState)

        let alertPresenter = POSRefundCardPresentPaymentAlertsPresenter(
            stateModel: stateModel,
            onCancelRequested: cancellationState.markCancelled,
            isPresentationAllowed: { !cancellationState.wasCancelledByMerchant }
        )
        let submissionUseCase = RefundSubmissionUseCase(
            details: .init(order: context.order,
                           charge: context.charge,
                           amount: amount,
                           paymentGatewayAccount: context.paymentGatewayAccount,
                           serverLineItems: serverLineItems),
            rootViewController: NullViewControllerPresenting(),
            alerts: POSRefundOrderDetailsPaymentAlerts(
                stateModel: stateModel,
                onCancelRequested: cancellationState.markCancelled,
                isPresentationAllowed: { !cancellationState.wasCancelledByMerchant }
            ),
            cardPresentConfiguration: CardPresentConfigurationLoader().configuration,
            cardReaderConnectionAlerts: CardPresentPaymentBluetoothReaderConnectionAlertsProvider(),
            alertPresenter: alertPresenter,
            dependencies: .init(currencyFormatter: currencyFormatter,
                                currencySettings: currencySettings,
                                cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                stores: stores,
                                storageManager: storageManager,
                                analytics: analytics,
                                refundService: refundService))

        self.submissionUseCase = submissionUseCase
        defer {
            self.submissionUseCase = nil
            self.onboardingSubscription = nil
        }

        do {
            try await withCheckedThrowingContinuation { continuation in
                var continuation: CheckedContinuation<Void, Error>? = continuation
                submissionUseCase.submitRefund(refund, showInProgressUI: { [weak self] in
                    Task { @MainActor in
                        self?.stateModel.state = submittingState
                    }
                }, onCompletion: { result in
                    continuation?.resume(with: result)
                    continuation = nil
                })
            }
        } catch {
            if cancellationState.wasCancelledByMerchant || error.isRefundSubmissionCancellation {
                stateModel.reset()
                throw POSRefundSubmissionError.canceledByUser
            }
            throw error
        }

        stateModel.state = .completed
        removePreloadedRefund(for: preparation.orderID)
    }
}

private extension POSRefundSubmissionAdaptor {
    func removePreloadedRefund(for orderID: Int64) {
        preloadedRefundSnapshots[orderID] = nil
        preloadTasks[orderID]?.task.cancel()
        preloadTasks[orderID] = nil
        serverPreviewTotals = serverPreviewTotals.filter { $0.key.orderID != orderID }
        // Prepared contexts hold the full order, charge, and refundable items, so they are dropped
        // alongside the rest of the refund's state instead of accumulating for the whole session.
        preparedContexts[orderID] = nil
    }

    func removePreloadedRefunds(except orderID: Int64) {
        preloadedRefundSnapshots = preloadedRefundSnapshots.filter { $0.key == orderID }
        serverPreviewTotals = serverPreviewTotals.filter { $0.key.orderID == orderID }
        preparedContexts = preparedContexts.filter { $0.key == orderID }
        for preloadedOrderID in Array(preloadTasks.keys) where preloadedOrderID != orderID {
            removePreloadedRefund(for: preloadedOrderID)
        }
    }

    private func preparedRefundSnapshot(for order: POSOrder) async throws -> PreparedRefundSnapshot {
        if let snapshot = preloadedRefundSnapshots.removeValue(forKey: order.id) {
            return snapshot
        }

        if let preloadTask = preloadTasks.removeValue(forKey: order.id) {
            return try await preloadTask.task.value
        }

        return try await loadPreparedRefundSnapshot(for: order)
    }

    private func loadPreparedRefundSnapshot(for order: POSOrder) async throws -> PreparedRefundSnapshot {
        let fullOrder = try await orderService.loadOrder(orderID: order.id)
        if let eligibilityFailure = fullOrder.refundEligibilityFailure {
            throw eligibilityFailure
        }
        let refunds = try await loadDetailedRefunds(for: fullOrder)
        let fetchedCharge = try await fetchChargeIfNeeded(for: fullOrder)
        let charge = fetchedCharge.map { refundMapping.normalizedForPOSInteracRefund(charge: $0) }
        let paymentGateway = loadPaymentGateway(for: fullOrder)
        let paymentGatewayAccount = await loadSelectedOrStoredPaymentGatewayAccount(for: fullOrder)
        let refundableItems = refundOptionsDeterminer.determineRefundableOrderItems(from: fullOrder, with: refunds)
        let refundableFees = refundMapping.determineRefundableFees(from: fullOrder, with: refunds)
        let selectableItems = refundMapping.makeSelectableItems(refundableItems: refundableItems,
                                                                fees: refundableFees,
                                                                currency: fullOrder.currency)
        let context = POSRefundSubmissionMapping.PreparedRefundContext(order: fullOrder,
                                                                       charge: charge,
                                                                       paymentGateway: paymentGateway,
                                                                       paymentGatewayAccount: paymentGatewayAccount,
                                                                       refundableItems: refundableItems,
                                                                       refundableFees: refundableFees)
        let preparation = POSRefundPreparation(orderID: fullOrder.orderID,
                                               selectableItems: selectableItems,
                                               paymentMethodDescription: refundMapping.paymentMethodDescription(for: fullOrder, charge: charge),
                                               customerEmail: fullOrder.billingAddress?.email,
                                               requiresCardPresentRefund: refundMapping.requiresCardPresentRefund(context: context))
        return PreparedRefundSnapshot(preparation: preparation, context: context)
    }

    /// Loads the order's refunds straight from the network so each refund's fee lines keep their
    /// `_refunded_item_id` meta. The Core Data `OrderFeeLine` entity does not persist `refundedItemID`,
    /// so reading refunds back from storage drops the link between a refund's fee line and the original
    /// order fee — which left already-refunded custom amounts incorrectly selectable for a new refund.
    /// `RefundAction.retrieveRefund` returns the freshly decoded refund, preserving that link.
    func loadDetailedRefunds(for order: Order) async throws -> [Refund] {
        var refunds: [Refund] = []
        for refundID in order.refunds.map(\.refundID) {
            if let refund = try await retrieveRefund(siteID: order.siteID, orderID: order.orderID, refundID: refundID) {
                refunds.append(refund)
            }
        }
        return refunds
    }

    func retrieveRefund(siteID: Int64, orderID: Int64, refundID: Int64) async throws -> Refund? {
        try await withCheckedThrowingContinuation { continuation in
            var continuation: CheckedContinuation<Refund?, Error>? = continuation
            let action = RefundAction.retrieveRefund(siteID: siteID, orderID: orderID, refundID: refundID) { refund, error in
                if let error {
                    continuation?.resume(throwing: error)
                } else {
                    continuation?.resume(returning: refund)
                }
                continuation = nil
            }
            stores.dispatch(action)
        }
    }

    func fetchChargeIfNeeded(for order: Order) async throws -> WCPayCharge? {
        guard let chargeID = order.chargeID, chargeID.isNotEmpty else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            var continuation: CheckedContinuation<WCPayCharge, Error>? = continuation
            let action = CardPresentPaymentAction.fetchWCPayCharge(siteID: order.siteID, chargeID: chargeID) { result in
                continuation?.resume(with: result)
                continuation = nil
            }
            stores.dispatch(action)
        }
    }

    func loadPaymentGateway(for order: Order) -> PaymentGateway? {
        storageManager.viewStorage
            .loadPaymentGateway(siteID: order.siteID, gatewayID: order.paymentMethodID)?
            .toReadOnly()
    }

    func loadSelectedOrStoredPaymentGatewayAccount(for order: Order) async -> PaymentGatewayAccount? {
        if let selectedAccount = await selectedPaymentGatewayAccount() {
            return selectedAccount
        }
        if let storedAccount = storedCardPresentPaymentGatewayAccount(siteID: order.siteID) {
            return storedAccount
        }

        await loadPaymentGatewayAccounts(siteID: order.siteID)
        return storedCardPresentPaymentGatewayAccount(siteID: order.siteID)
    }

    func selectedPaymentGatewayAccount() async -> PaymentGatewayAccount? {
        await withCheckedContinuation { continuation in
            var continuation: CheckedContinuation<PaymentGatewayAccount?, Never>? = continuation
            stores.dispatch(CardPresentPaymentAction.selectedPaymentGatewayAccount { account in
                continuation?.resume(returning: account)
                continuation = nil
            })
        }
    }

    func loadPaymentGatewayAccounts(siteID: Int64) async {
        await withCheckedContinuation { continuation in
            var continuation: CheckedContinuation<Void, Never>? = continuation
            stores.dispatch(CardPresentPaymentAction.loadAccounts(siteID: siteID) { _ in
                continuation?.resume()
                continuation = nil
            })
        }
    }

    func storedCardPresentPaymentGatewayAccount(siteID: Int64) -> PaymentGatewayAccount? {
        storageManager.viewStorage
            .loadPaymentGatewayAccounts(siteID: siteID)
            .map { $0.toReadOnly() }
            .first { $0.isCardPresentEligible && $0.gatewayID == WCPayAccount.gatewayID }
    }

    func observe(onboardingPresenter: CardPresentPaymentsOnboardingPresenterAdaptor,
                 submittingState: POSRefundSubmissionState,
                 cancellationState: POSRefundCancellationState) {
        onboardingSubscription = onboardingPresenter.onboardingScreenViewModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                guard !cancellationState.wasCancelledByMerchant else { return }
                switch event {
                case .showOnboarding(let factory, let onCancel):
                    self.stateModel.state = .onboarding(factory: factory, onCancel: {
                        cancellationState.markCancelled()
                        onCancel()
                    })
                case .onboardingComplete:
                    self.stateModel.state = submittingState
                }
            }
    }
}

private final class POSRefundCancellationState {
    private(set) var wasCancelledByMerchant = false

    func markCancelled() {
        wasCancelledByMerchant = true
    }
}

private extension Error {
    var isRefundSubmissionCancellation: Bool {
        (self as? RefundSubmissionUseCaseSubmissionError) == .canceledByUser
    }
}

private enum POSRefundSubmissionAdaptorError: LocalizedError {
    case missingPreparedRefund
    case refundAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .missingPreparedRefund:
            return NSLocalizedString(
                "pos.refundSubmissionAdaptor.error.missingPreparedRefund",
                value: "The refund could not be prepared. Please try again.",
                comment: "Error shown when POS tries to submit a refund without prepared refund data."
            )
        case .refundAlreadyInProgress:
            return NSLocalizedString(
                "pos.refundSubmissionAdaptor.error.refundAlreadyInProgress",
                value: "A refund is already in progress. Please wait for it to finish.",
                comment: "Error shown when POS tries to submit a second refund while another refund is in progress."
            )
        }
    }
}
