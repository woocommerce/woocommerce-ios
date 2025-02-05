import Foundation
import Yosemite
import Combine
import protocol WooFoundation.Analytics

final class SetUpTapToPayCompleteViewModel: PaymentSettingsFlowPresentedViewModel, ObservableObject {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var doneWasTapped: Bool = false

    private(set) var connectedReader: CardReaderSettingsTriState = .isUnknown

    private let connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker
    private let stores: StoresManager

    private let analytics: Analytics = ServiceLocator.analytics

    private var subscriptions = Set<AnyCancellable>()
    private(set) var learnMoreURL: URL

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?,
         connectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker,
         stores: StoresManager = ServiceLocator.stores) {
        self.didChangeShouldShow = didChangeShouldShow
        self.connectionAnalyticsTracker = connectionAnalyticsTracker
        /// The `learnMoreURL` will be updated when a reader connects
        self.learnMoreURL = CardPresentPaymentsPlugin.wcPay.setUpTapToPayLearnMoreURL
        self.stores = stores

        beginConnectedReaderObservation()
    }

    /// Set up to observe readers connecting / disconnecting
    ///
    private func beginConnectedReaderObservation() {
        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self else { return }
            connectedReader = readers.isNotEmpty ? .isTrue : .isFalse
            reevaluateShouldShow()
            updateLearnMoreURL()
        }
        stores.dispatch(connectedAction)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifies the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        let newShouldShow: CardReaderSettingsTriState

        if doneWasTapped {
            newShouldShow = .isFalse
        } else {
            newShouldShow = connectedReader
        }

        let didChange = newShouldShow != shouldShow

        if didChange {
            shouldShow = newShouldShow
            didChangeShouldShow?(shouldShow)
        }
    }

    private func updateLearnMoreURL() {
        let action = CardPresentPaymentAction.loadActivePaymentGatewayExtension { [weak self] paymentGateway in
            self?.learnMoreURL = paymentGateway.setUpTapToPayLearnMoreURL
        }
        stores.dispatch(action)
    }

    func doneTapped() {
        analytics.track(.tapToPaySetupSuccessDoneTapped)
        doneWasTapped = true
        reevaluateShouldShow()
    }

    deinit {
        subscriptions.removeAll()
    }
}
