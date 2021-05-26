import Foundation
import Yosemite

enum CardReaderSettingsUnknownViewModelDiscoveryState {
    case notSearching
    case searching
    case failed(Error)
    case foundReader
    case connectingToReader
}

final class CardReaderSettingsUnknownViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var noConnectedReaders: CardReaderSettingsTriState = .isUnknown
    private var noKnownReaders: CardReaderSettingsTriState = .isUnknown

    private var siteID: Int64 = Int64.min

    private var foundReader: CardReader?

    var discoveryState: CardReaderSettingsUnknownViewModelDiscoveryState = .notSearching
    var foundReaderSerialNumber: String? {
        foundReader?.serial
    }

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?) {
        self.didChangeShouldShow = didChangeShouldShow
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        beginObservation()
    }

    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of known
    /// and connected readers.
    ///
    private func beginObservation() {
        // This completion should be called repeatedly as the list of known readers changes
        let knownAction = CardPresentPaymentAction.observeKnownReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.noKnownReaders = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(knownAction)

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
        didUpdate?()

        ServiceLocator.analytics.track(.cardReaderDiscoveryTapped)
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            onReaderDiscovered: { [weak self] cardReaders in
                self?.didDiscoverReaders(cardReaders: cardReaders)
            },
            onError: { [weak self] error in
                self?.discoveryState = .failed(error)
                self?.didUpdate?()
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
        didUpdate?()
    }

    /// Dispatch a request to cancel reader discovery
    ///
    func cancelReaderDiscovery() {
        discoveryState = .notSearching
        didUpdate?()

        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { _ in
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Dispatch a request to connect to the found reader
    ///
    func connectToReader() {
        guard let foundReader = foundReader else {
            DDLogError("foundReader unexpectedly nil in connectToReader")
            return
        }

        discoveryState = .connectingToReader
        didUpdate?()

        ServiceLocator.analytics.track(.cardReaderConnectionTapped)
        let action = CardPresentPaymentAction.connect(reader: foundReader) { result in
            /// Nothing to do here because, when the observed connectedReaders mutates, the
            /// connected view will be shown automatically.
            switch result {
            case .success(let reader):
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
    ///
    func continueSearch() {
        discoveryState = .searching
        foundReader = nil
        didUpdate?()
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        var newShouldShow: CardReaderSettingsTriState = .isUnknown

        if ( noKnownReaders == .isUnknown ) || ( noConnectedReaders == .isUnknown ) {
            newShouldShow = .isUnknown
        } else if ( noKnownReaders == .isTrue ) && ( noConnectedReaders == .isTrue ) {
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
