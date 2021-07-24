import Foundation
import Combine
import Yosemite

enum CardReaderSettingsUnknownViewModelDiscoveryState {
    case notSearching
    case searching
    case failed(Error)
    case foundReader
    case connectingToReader
    case restartingSearch
}

final class CardReaderSettingsUnknownViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var noConnectedReaders: CardReaderSettingsTriState = .isUnknown
    private var noKnownReaders: CardReaderSettingsTriState = .isUnknown
    private let knownReadersProvider: CardReaderSettingsKnownReadersProvider?
    private let siteID: Int64

    private var subscriptions = Set<AnyCancellable>()

    private var knownReaderIDs: [String]? {
        didSet {
            guard let knownReaderIDs = knownReaderIDs else {
                noKnownReaders = .isUnknown
                return
            }

            noKnownReaders = knownReaderIDs.isEmpty ? .isTrue : .isFalse
        }
    }
    private var foundReader: CardReader?

    var discoveryState: CardReaderSettingsUnknownViewModelDiscoveryState = .notSearching {
        didSet {
            didUpdate?()
        }
    }
    var foundReaderID: String? {
        foundReader?.id
    }

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?, knownReadersProvider: CardReaderSettingsKnownReadersProvider? = nil) {
        self.didChangeShouldShow = didChangeShouldShow
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        self.knownReadersProvider = knownReadersProvider

        beginKnownReaderObservation()
        beginConnectedReaderObservation()
    }

    deinit {
        subscriptions.removeAll()
    }

    /// Monitor the list of known readers
    ///
    private func beginKnownReaderObservation() {
        guard knownReadersProvider != nil else {
            self.knownReaderIDs = []
            self.reevaluateShouldShow()
            return
        }

        knownReadersProvider?.knownReaders
            .sink(receiveValue: { [weak self] readerIDs in
                self?.knownReaderIDs = readerIDs
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
            self.noConnectedReaders = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(connectedAction)
    }

    /// Dispatch a request to start reader discovery
    ///
    func startReaderDiscovery() {
        discoveryState = .searching

        ServiceLocator.analytics.track(.cardReaderDiscoveryTapped)
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            onReaderDiscovered: { [weak self] cardReaders in
                self?.didDiscoverReaders(cardReaders: cardReaders)
            },
            onError: { [weak self] error in
                self?.discoveryState = .failed(error)
                ServiceLocator.analytics.track(.cardReaderDiscoveryFailed, withError: error)
            })

        ServiceLocator.stores.dispatch(action)
    }

    /// Alert the user we have a found reader
    ///
    func didDiscoverReaders(cardReaders: [CardReader]) {
        /// If we are already presenting a foundReader alert to the user, ignore the found reader
        guard case .searching = discoveryState else {
            return
        }

        /// The publisher for discovered readers can return an initial empty value. We'll want to ignore that.
        guard cardReaders.count > 0 else {
            return
        }

        ServiceLocator.analytics.track(.cardReaderDiscoveredReader)

        /// This viewmodel and view supports single reader discovery only.
        /// TODO: Add another viewmodel and view to handle multiple discovered readers.
        guard let cardReader = cardReaders.first else {
            return
        }

        foundReader = cardReader
        discoveryState = .foundReader
    }

    /// Dispatch a request to cancel reader discovery
    ///
    func cancelReaderDiscovery() {
        discoveryState = .notSearching
        cancelReaderDiscovery(completion: nil)
    }

    /// Dispatch a request to connect to the found reader
    ///
    func connectToReader() {
        guard let foundReader = foundReader else {
            DDLogError("foundReader unexpectedly nil in connectToReader")
            return
        }

        discoveryState = .connectingToReader

        ServiceLocator.analytics.track(.cardReaderConnectionTapped)
        let action = CardPresentPaymentAction.connect(reader: foundReader) { [weak self] result in
            switch result {
            case .success(let reader):
                self?.knownReadersProvider?.rememberCardReader(cardReaderID: reader.id)
                // If the reader does not have a battery, or the battery level is unknown, it will be nil
                let properties = reader.batteryLevel
                    .map { ["battery_level": $0] }
                ServiceLocator.analytics.track(.cardReaderConnectionSuccess, withProperties: properties)
            case .failure(let error):
                ServiceLocator.analytics.track(.cardReaderConnectionFailed, withError: error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Discard the found reader and keep searching
    /// As discussed in p91TBi-5fB-p2#comment-4849, for the first release,
    /// we will restart the discovery process again
    func continueSearch() {
        foundReader = nil
        discoveryState = .restartingSearch
        cancelReaderDiscovery { [weak self] in
            self?.startReaderDiscovery()
        }
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        var newShouldShow: CardReaderSettingsTriState = .isUnknown

        if (noKnownReaders == .isUnknown) || (noConnectedReaders == .isUnknown) {
            newShouldShow = .isUnknown
        } else if (noKnownReaders == .isTrue) && (noConnectedReaders == .isTrue) {
            newShouldShow = .isTrue
        } else {
            newShouldShow = .isFalse
        }

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }
}


private extension CardReaderSettingsUnknownViewModel {
    func cancelReaderDiscovery(completion: (()-> Void)?) {
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { _ in
            completion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}
