import SwiftUI
import Combine
import protocol WooFoundation.Analytics
import protocol Yosemite.POSItem

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {
    @Published var cardPresentPaymentOnboardingViewModel: CardPresentPaymentsOnboardingViewModel?
    private var onOnboardingCancellation: (() -> Void)?
    @Published private(set) var isShowingCardReaderStatus: Bool = false

    @Published private(set) var connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected

    @ObservedObject var posModel: PointOfSaleAggregateModel

    var isShimmering: Bool {
        posModel.orderState.isSyncing
    }

    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let analytics: Analytics

    init(posModel: PointOfSaleAggregateModel,
         cardPresentPaymentService: CardPresentPaymentFacade,
         analytics: Analytics = ServiceLocator.analytics) {
        self.posModel = posModel
        self.cardPresentPaymentService = cardPresentPaymentService
        self.analytics = analytics

        // Initialize all properties before calling methods
        self.observeConnectedReaderForStatus()
        self.observeCardPresentPaymentEvents()
    }

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
        posModel.startNewCart()
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

    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
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
}

// MARK: - Payment collection

private extension TotalsViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPaymentService.readerConnectionStatusPublisher
            .assign(to: &$connectionStatus)

        Publishers.CombineLatest3(posModel.$cardReaderConnectionStatus, posModel.$orderState, posModel.$cardPresentPaymentInlineMessage)
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
    }
}
