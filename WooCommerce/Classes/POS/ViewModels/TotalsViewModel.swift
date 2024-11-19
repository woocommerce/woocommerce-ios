import SwiftUI
import Combine
import protocol WooFoundation.Analytics
import protocol Yosemite.POSItem
import Yosemite

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    enum PaymentState {
        case idle
        case acceptingCard
        case validatingOrder
        case validatingOrderError
        case preparingReader
        case processingPayment
        case paymentError
        case cardPaymentSuccessful
        case creatingReceipt
    }

    @Published var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel?
    private var onOnboardingCancellation: (() -> Void)?
    @Published var cardPresentPaymentAlertViewModel: PointOfSaleCardPresentPaymentAlertType?
    @Published private(set) var cardPresentPaymentInlineMessage: PointOfSaleCardPresentPaymentMessageType?
    @Published private(set) var isShowingCardReaderStatus: Bool = false
    @Published private(set) var isShowingTotalsFields: Bool = false

    @Published private(set) var paymentState: PaymentState

    func fakePaymentSuccess() {
        paymentState = .cardPaymentSuccessful
    }

    @Published private(set) var connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    @ObservedObject var posModel: PointOfSaleAggregateModel

    var isShimmering: Bool {
        posModel.orderState.isSyncing
    }

    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let analytics: Analytics

    init(posModel: PointOfSaleAggregateModel,
         cardPresentPaymentService: CardPresentPaymentFacade,
         paymentState: PaymentState,
         analytics: Analytics = ServiceLocator.analytics) {
        self.posModel = posModel
        self.cardPresentPaymentService = cardPresentPaymentService
        self.paymentState = paymentState
        self.analytics = analytics

        // Initialize all properties before calling methods
        self.observeConnectedReaderForStatus()
        self.observeCardPresentPaymentEvents()
    }

    var paymentStatePublisher: Published<PaymentState>.Publisher { $paymentState }
    private var cardPresentPaymentAlertViewModelPublisher: Published<PointOfSaleCardPresentPaymentAlertType?>.Publisher { $cardPresentPaymentAlertViewModel }
    private var connectionStatusPublisher: Published<CardPresentPaymentReaderConnectionStatus>.Publisher { $connectionStatus }

    func connectReaderTapped() {
        Task { @MainActor in
            do {
                let _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
            } catch {
                DDLogError("🔴 POS reader connection error: \(error)")
            }
        }
    }

    func startNewOrder() {
        paymentState = .acceptingCard
        cardPresentPaymentInlineMessage = nil
        posModel.startNewCart()
    }

    func createReceipt(order: Yosemite.Order) {
        paymentState = .creatingReceipt
        // TODO: 
        // This won't be full-screen quite yet, visibility needs to be handled in the TotalViews as well.
        cardPresentPaymentInlineMessage = .creatingReceipt(viewModel: PointOfSaleCardPresentCreatingReceiptMessageViewModel(order: order))
    }

    /// Called when the onboarding UI is dismissed.
    /// For external dismissal (tapping CTA to dismiss), this method is called twice - the first time to dismiss the onboarding UI
    /// by setting `cardPresentPaymentOnboardingViewModel` to nil, the second time triggered by internal dismissal.
    /// For internal dismissal (tapping outside the modal), this method is called once.
    /// This method is used to reset the internal state of the onboarding UI and track the dismissal event.
    func cancelOnboarding() {
        guard let onboardingViewModel = cardPresentPaymentOnboardingViewModel else {
            return
        }
        analytics.track(event: .PointOfSale.paymentsOnboardingDismissed(onboardingState: onboardingViewModel.state))
        cardPresentPaymentOnboardingViewModel = nil
        onOnboardingCancellation?()
    }

    /// Tracks when the onboarding UI is shown.
    func trackOnboardingShown() {
        analytics.track(event: .PointOfSale.paymentsOnboardingShown())
    }

    private func editOrder() {
        paymentState = .idle
        cardPresentPaymentInlineMessage = nil
        posModel.addMoreToCart()
    }

    // These three functions could potentially move to posModel and be based on orderStage.
    func onTotalsViewDisappearance() {
        // This is a backup – it's not called until transitions are complete when using the back button.
        // The delay can lead to race conditions with tapping a card.
        // It's likely that the payment will already have been cancelled due to the change of orderStage.
        posModel.cancelCardReaderPreparation()
    }

    func startShowingTotalsView() {
        posModel.observeReaderReconnection()
    }

    func stopShowingTotalsView() {
        posModel.cancelCardReaderPreparation()
    }
}

// MARK: - Payment collection

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .assign(to: &$connectionStatus)

        Publishers.CombineLatest3(posModel.$cardReaderConnectionStatus, posModel.$orderState, $cardPresentPaymentInlineMessage)
            .map { connectionStatus, orderState, message in
                guard orderState.isLoaded
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
        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> CardPresentPaymentsOnboardingViewModel? in
                guard let self else { return nil }
                guard case let .showOnboarding(viewModel, onCancel) = event else {
                    return nil
                }
                onOnboardingCancellation = onCancel
                return viewModel
            }
            .assign(to: &$cardPresentPaymentOnboardingViewModel)

        cardPresentPaymentService.paymentEventPublisher
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

        cardPresentPaymentService.paymentEventPublisher
            .map { [weak self] event -> PointOfSaleCardPresentPaymentMessageType? in
                self?.mapCardPresentPaymentEventToMessageType(event)
            }
            .assign(to: &$cardPresentPaymentInlineMessage)

        cardPresentPaymentService.paymentEventPublisher
            .compactMap { [weak self] paymentEvent in
                guard let self else { return .none }
                return PaymentState(from: paymentEvent,
                                    using: presentationStyleDeterminerDependencies) }
            .assign(to: &$paymentState)

        // This publisher currently triggers showing the totals fields views, should also handle the case for cash payments
        paymentStatePublisher
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
                        .cardPaymentSuccessful,
                        .creatingReceipt:
                    return false
                }
            }
            .assign(to: &$isShowingTotalsFields)
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
            self?.posModel.cancelThenCollectPayment()
        }

        var orderTotal: String?
        if case .loaded(let totals) = posModel.orderState {
            orderTotal = totals.orderTotal
        }

        return PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies(
            tryPaymentAgainBackToCheckoutAction: cancelThenCollectPaymentWithWeakSelf,
            nonRetryableErrorExitAction: cancelThenCollectPaymentWithWeakSelf,
            formattedOrderTotalPrice: orderTotal,
            paymentCaptureErrorTryAgainAction: cancelThenCollectPaymentWithWeakSelf,
            paymentCaptureErrorNewOrderAction: { [weak self] in
                self?.posModel.startNewCart()
            },
            paymentIntentCreationErrorEditOrderAction: { [weak self] in
                self?.editOrder()
            },
            dismissReaderConnectionModal: { [weak self] in
                self?.cardPresentPaymentAlertViewModel = nil
            }
        )
    }
}

private extension TotalsViewModel.PaymentState {
    init?(from cardPaymentEvent: CardPresentPaymentEvent,
          using paymentEventPresentationStyleDependencies: PointOfSaleCardPresentPaymentEventPresentationStyle.Dependencies) {
        switch cardPaymentEvent {
        case .idle:
            self = .idle
        case .show(.validatingOrder):
            self = .validatingOrder
        case .show(.preparingForPayment):
            self = .preparingReader
        case .show(.tapSwipeOrInsertCard):
            self = .acceptingCard
        case .show(.processing),
                .show(.displayReaderMessage):
            self = .processingPayment
        case .show(.paymentError):
            if case let .show(eventDetails) = cardPaymentEvent,
               case let .message(messageType) = PointOfSaleCardPresentPaymentEventPresentationStyle(
                for: eventDetails,
                dependencies: paymentEventPresentationStyleDependencies),
               case .validatingOrderError = messageType {
                self = .validatingOrderError
            } else {
                self = .paymentError
            }
        case .show(.paymentCaptureError):
            self = .paymentError
            // TODO:
            // We need to add a new case where the payment is successful, but unrelated to card payment.
        case .show(.paymentSuccess):
            self = .cardPaymentSuccessful
        case .show(.creatingReceipt):
            self = .creatingReceipt
        default:
            return nil
        }
    }
}
