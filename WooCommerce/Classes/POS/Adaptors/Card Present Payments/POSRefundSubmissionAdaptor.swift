import Combine
import Foundation
import PointOfSale
import protocol Storage.StorageManagerType
import UIKit
import Yosemite
import WooFoundation

@MainActor
final class POSRefundSubmissionAdaptor: POSRefundSubmissionProcessing {
    let stateModel = POSRefundSubmissionModel()

    private let orderService: POSOrderServiceProtocol
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    private let currencyFormatter: CurrencyFormatter
    private let refundMapping: POSRefundSubmissionMapping
    private let analytics: Analytics
    private let refundOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol

    private var preparedContexts: [Int64: POSRefundSubmissionMapping.PreparedRefundContext] = [:]
    private var submissionUseCase: RefundSubmissionUseCase<CardPresentPaymentBluetoothReaderConnectionAlertsProvider, POSRefundCardPresentPaymentAlertsPresenter>?
    private var onboardingSubscription: AnyCancellable?

    init(orderService: POSOrderServiceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         refundOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol = OrderRefundsOptionsDeterminer()) {
        self.orderService = orderService
        self.stores = stores
        self.storageManager = storageManager
        self.currencySettings = currencySettings
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.currencyFormatter = currencyFormatter
        self.refundMapping = POSRefundSubmissionMapping(currencyFormatter: currencyFormatter)
        self.analytics = analytics
        self.refundOptionsDeterminer = refundOptionsDeterminer
    }

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        stateModel.state = .loading

        let fullOrder = try await orderService.loadOrder(orderID: order.id)
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
        preparedContexts[fullOrder.orderID] = context
        stateModel.reset()

        return POSRefundPreparation(orderID: fullOrder.orderID,
                                    selectableItems: selectableItems,
                                    paymentMethodDescription: refundMapping.paymentMethodDescription(for: fullOrder, charge: charge),
                                    customerEmail: fullOrder.billingAddress?.email,
                                    requiresCardPresentRefund: refundMapping.requiresCardPresentRefund(context: context))
    }

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) -> POSRefundReviewData? {
        guard let context = preparedContexts[preparation.orderID] else {
            return nil
        }

        let components = refundMapping.refundComponents(from: selectedItems, context: context)
        let values = refundMapping.refundValues(items: components.items, fees: components.fees)
        return POSRefundReviewData(itemsCount: selectedItems.count,
                                   formattedItemsSubtotal: currencyFormatter.formatAmount(values.subtotal, with: context.order.currency) ?? "",
                                   formattedTax: currencyFormatter.formatAmount(values.tax, with: context.order.currency) ?? "",
                                   formattedRefundTotal: currencyFormatter.formatAmount(values.total, with: context.order.currency) ?? "",
                                   paymentMethodDescription: preparation.paymentMethodDescription,
                                   customerEmail: preparation.customerEmail,
                                   refundReason: reason,
                                   isFullRefund: selectedItems.count == preparation.selectableItems.count)
    }

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws {
        guard let context = preparedContexts[preparation.orderID] else {
            throw POSRefundSubmissionAdaptorError.missingPreparedRefund
        }

        let components = refundMapping.refundComponents(from: selectedItems, context: context)
        let values = refundMapping.refundValues(items: components.items, fees: components.fees)
        let amount = refundMapping.apiAmountString(for: values.total)
        let refund = RefundCreationUseCase(amount: amount,
                                           reason: reason,
                                           automaticallyRefundsPayment: refundMapping.gatewaySupportsAutomaticRefunds(context: context),
                                           items: components.items,
                                           shippingLine: nil,
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

        let alertPresenter = POSRefundCardPresentPaymentAlertsPresenter(stateModel: stateModel,
                                                                        onCancelRequested: cancellationState.markCancelled)
        let submissionUseCase = RefundSubmissionUseCase(
            details: .init(order: context.order,
                           charge: context.charge,
                           amount: amount,
                           paymentGatewayAccount: context.paymentGatewayAccount),
            rootViewController: NullViewControllerPresenting(),
            alerts: POSRefundOrderDetailsPaymentAlerts(stateModel: stateModel,
                                                       onCancelRequested: cancellationState.markCancelled),
            cardPresentConfiguration: CardPresentConfigurationLoader(stores: stores).configuration,
            cardReaderConnectionAlerts: CardPresentPaymentBluetoothReaderConnectionAlertsProvider(),
            alertPresenter: alertPresenter,
            dependencies: .init(currencyFormatter: currencyFormatter,
                                currencySettings: currencySettings,
                                cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                stores: stores,
                                storageManager: storageManager,
                                analytics: analytics))

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

        stateModel.state = requiresCardPresentRefund ? .submittingCardPresent : .completed
    }
}

private extension POSRefundSubmissionAdaptor {
    func loadDetailedRefunds(for order: Order) async throws -> [Refund] {
        let refundIDs = order.refunds.map(\.refundID)
        if refundIDs.isNotEmpty {
            try await withCheckedThrowingContinuation { continuation in
                var continuation: CheckedContinuation<Void, Error>? = continuation
                let action = RefundAction.retrieveRefunds(siteID: order.siteID,
                                                          orderID: order.orderID,
                                                          refundIDs: refundIDs,
                                                          deleteStaleRefunds: true) { error in
                    if let error {
                        continuation?.resume(throwing: error)
                    } else {
                        continuation?.resume()
                    }
                    continuation = nil
                }
                stores.dispatch(action)
            }
        }

        return storageManager.viewStorage
            .loadRefunds(siteID: order.siteID, orderID: order.orderID)
            .map { $0.toReadOnly() }
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

    var errorDescription: String? {
        switch self {
        case .missingPreparedRefund:
            return NSLocalizedString(
                "pos.refundSubmissionAdaptor.error.missingPreparedRefund",
                value: "The refund could not be prepared. Please try again.",
                comment: "Error shown when POS tries to submit a refund without prepared refund data."
            )
        }
    }
}
