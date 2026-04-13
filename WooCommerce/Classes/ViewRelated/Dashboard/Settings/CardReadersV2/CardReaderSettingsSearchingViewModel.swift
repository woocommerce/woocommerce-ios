import Foundation
import Combine
import Yosemite

final class CardReaderSettingsSearchingViewModel: PaymentSettingsFlowPresentedViewModel {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?
    var learnMoreURL: URL

    private(set) var noConnectedReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }

    private(set) var readerReconnectionInProgress: Bool = false
    private(set) var skipAutoSearchAfterReconnectionEnds: Bool = false

    private(set) var knownReaderProvider: CardReaderSettingsKnownReaderProvider?
    private(set) var siteID: Int64

    private var subscriptions = Set<AnyCancellable>()

    private var knownReaderID: String? {
        didSet {
            didUpdate?()
        }
    }
    private var foundReader: CardReader?

    var foundReaderID: String? {
        foundReader?.id
    }

    let configuration: CardPresentPaymentsConfiguration
    let cardReaderConnectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?,
         knownReaderProvider: CardReaderSettingsKnownReaderProvider? = nil,
         stores: StoresManager = ServiceLocator.stores,
         configuration: CardPresentPaymentsConfiguration,
         cardReaderConnectionAnalyticsTracker: CardReaderConnectionAnalyticsTracker) {
        self.didChangeShouldShow = didChangeShouldShow
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        self.knownReaderProvider = knownReaderProvider
        self.configuration = configuration
        self.cardReaderConnectionAnalyticsTracker = cardReaderConnectionAnalyticsTracker
        self.learnMoreURL = CardPresentPaymentsPlugin.wcPay.manageCardReaderLearnMoreURL

        beginKnownReaderObservation()
        beginConnectedReaderObservation()
        beginReconnectionObservation()
        updateLearnMoreUrl(stores: stores)
    }

    deinit {
        subscriptions.removeAll()
    }

    func hasKnownReader() -> Bool {
        knownReaderID != nil
    }

    func shouldSkipAutoSearch() -> Bool {
        skipAutoSearchAfterReconnectionEnds
    }

    func clearSkipAutoSearch() {
        skipAutoSearchAfterReconnectionEnds = false
    }

    /// Monitor for a known reader
    ///
    private func beginKnownReaderObservation() {
        guard knownReaderProvider != nil else {
            self.knownReaderID = nil
            self.reevaluateShouldShow()
            return
        }

        knownReaderProvider?.knownReader
            .sink(receiveValue: { [weak self] readerID in
                self?.knownReaderID = readerID
                self?.reevaluateShouldShow()
            })
            .store(in: &subscriptions)
    }

    /// Set up to observe readers connecting / disconnecting
    ///
    private func beginConnectedReaderObservation() {
        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.noConnectedReader = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(connectedAction)
    }

    /// Set up to observe reader reconnection state
    ///
    private func beginReconnectionObservation() {
        let reconnectionAction = CardPresentPaymentAction.observeCardReaderReconnectionState { reconnectionEvents in
            reconnectionEvents
                .sink { [weak self] state in
                    guard let self = self else { return }

                    switch state {
                    case .reconnecting:
                        self.readerReconnectionInProgress = true
                        self.skipAutoSearchAfterReconnectionEnds = false
                    case .succeeded:
                        self.readerReconnectionInProgress = false
                        self.skipAutoSearchAfterReconnectionEnds = false
                    case .failed, .idle:
                        if self.readerReconnectionInProgress {
                            self.skipAutoSearchAfterReconnectionEnds = true
                        }
                        self.readerReconnectionInProgress = false
                    }
                    self.reevaluateShouldShow()
                }
                .store(in: &self.subscriptions)
        }
        ServiceLocator.stores.dispatch(reconnectionAction)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifies the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        let newShouldShow: CardReaderSettingsTriState
        if readerReconnectionInProgress {
            newShouldShow = .isFalse
        } else {
            newShouldShow = noConnectedReader
        }

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }

    /// Load active payment gateway plugin from the payment store and update learn more url
    ///
    private func updateLearnMoreUrl(stores: StoresManager) {
        let loadLearnMoreUrlAction = CardPresentPaymentAction
            .loadActivePaymentGatewayExtension() { [weak self] result in
                self?.learnMoreURL = result.manageCardReaderLearnMoreURL
            }
        stores.dispatch(loadLearnMoreUrlAction)
    }
}
