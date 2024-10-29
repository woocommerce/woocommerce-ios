import SwiftUI
import Combine
import struct Yosemite.POSCartItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

import struct Yosemite.Order

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    @Published var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel?
    @Published var cardPresentPaymentOnboardingURL: URL?
    private var onOnboardingCancellation: (() -> Void)?
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    @Published private(set) var isShowingCardReaderStatus: Bool = false
    @Published private(set) var isShowingTotalsFields: Bool = false

    private var totalsCalculator: OrderTotalsCalculator? {
        guard let order else {
            return nil
        }
        return OrderTotalsCalculator(for: order, using: currencyFormatter)
    }

    var formattedCartTotalPrice: String? {
        formattedPrice(totalsCalculator?.itemsTotal.stringValue, currency: order?.currency)
    }

    var formattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    var order: Order? {
        posModel.order
    }

    var orderState: PointOfSaleOrderState {
        posModel.orderState
    }

    var isShimmering: Bool {
        orderState.isSyncing
    }

    var isSubtotalFieldRedacted: Bool {
        formattedCartTotalPrice == nil || orderState.isSyncing
    }

    var isTaxFieldRedacted: Bool {
        formattedOrderTotalTaxPrice == nil || orderState.isSyncing
    }

    var isTotalPriceFieldRedacted: Bool {
        formattedOrderTotalPrice == nil || orderState.isSyncing
    }

    private let currencyFormatter: CurrencyFormatter

    private var posModel: PointOfSaleAggregateModel

    private var cancellables: Set<AnyCancellable> = []

    init(posModel: PointOfSaleAggregateModel,
         currencyFormatter: CurrencyFormatter) {
        self.posModel = posModel
        self.currencyFormatter = currencyFormatter

        // Initialize all properties before calling methods
        self.observeConnectedReaderForStatus()
        self.observeCardPresentPaymentEvents()
        self.observeOrderStage()
    }

    private var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }

    func startNewOrder() {
        cardPresentPaymentInlineMessage = nil
        posModel.startNewOrder()
    }

    /// Called when the onboarding UI is dismissed.
    func cancelOnboarding() {
        onOnboardingCancellation?()
    }

    private func editOrder() {
        cardPresentPaymentInlineMessage = nil
        posModel.editOrder()
    }

    func onTotalsViewDisappearance() {
        // This is a backup – it's not called until transitions are complete when using the back button.
        // The delay can lead to race conditions with tapping a card.
        // It's likely that the payment will already have been cancelled due to the change of orderStage.
        posModel.cancelReaderPreparation()
    }

    func startShowingTotalsView() {
        posModel.observeReaderReconnection()
    }

    func stopShowingTotalsView() {
        posModel.cancelReaderPreparation()
    }
}

// MARK: - Price formatters

private extension TotalsViewModel {
    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        return currencyFormatter.formatAmount(price, with: currency)
    }
}

// MARK: - Payment collection

private extension TotalsViewModel {
    @MainActor
    func collectPayment() async {
        await posModel.collectPayment()
    }
}

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        Publishers.CombineLatest4(posModel.$connectionStatus, posModel.$orderState, $cardPresentPaymentInlineMessage, posModel.$order)
            .map { connectionStatus, orderState, message, order in
                guard order != nil,
                      orderState.isLoaded
                        else {
                    // When the order's being created or synced, we only show the shimmering totals.
                    // Before the order exists, we don’t want to show the card payment status, as it will
                    // show for a second initially, then disappear the moment we start syncing the order.
                    return false
                }

                switch connectionStatus {
                case .connected, .disconnecting, .cancellingConnection:
                    return message != nil
                case .disconnected:
                    // Since the reader is disconnected, this will show the "Connect your reader" CTA button view.
                    return true
                }
            }
            .assign(to: &$isShowingCardReaderStatus)
    }

    func observeCardPresentPaymentEvents() {
        posModel.cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> CardPresentPaymentsOnboardingViewModel? in
                guard let self else { return nil }
                guard case let .showOnboarding(viewModel, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return viewModel
            }
            .assign(to: &$cardPresentPaymentOnboardingViewModel)

        posModel.cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentAlertType? in
                guard let self else { return nil }
                guard case let .show(eventDetails) = event,
                      case let .alert(alertType) = presentationStyle(for: eventDetails)
                else {
                    return nil
                }
                return alertType
            }
            .assign(to: &$cardPresentPaymentAlertViewModel)

        posModel.cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .assign(to: &$cardPresentPaymentInlineMessage)

        posModel.$paymentState
            .map { paymentState in
                switch paymentState {
                case .idle,
                        .acceptingCard,
                        .validatingOrder,
                        .validatingOrderError,
                        .preparingReader:
                    return true
                case .processingPayment,
                        .paymentError,
                        .cardPaymentSuccessful:
                    return false
                }
            }
            .assign(to: &$isShowingTotalsFields)
    }

    func observeOrderStage() {
        posModel.$orderStage
            .removeDuplicates()
            .sink { [weak self] stage in
            guard let self else { return }

            switch stage {
            case .building:
                stopShowingTotalsView()
            case .finalizing:
                startShowingTotalsView()
            }
        }
        .store(in: &cancellables)
    }
}

private extension TotalsViewModel {
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

        return PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: cancelThenCollectPaymentWithWeakSelf,
            nonRetryableErrorExitAction: cancelThenCollectPaymentWithWeakSelf,
            formattedOrderTotalPrice: formattedOrderTotalPrice,
            paymentCaptureErrorTryAgainAction: cancelThenCollectPaymentWithWeakSelf,
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.startNewOrder()
            },
            paymentIntentCreationErrorEditOrderAction: { [weak self] in
                self?.editOrder()
            },
            dismissReaderConnectionModal: { [weak self] in
                self?.cardPresentPaymentAlertViewModel = nil
            }
        )
    }

    func cancelThenCollectPayment() {
        posModel.cancelThenCollectPayment()
    }
}
