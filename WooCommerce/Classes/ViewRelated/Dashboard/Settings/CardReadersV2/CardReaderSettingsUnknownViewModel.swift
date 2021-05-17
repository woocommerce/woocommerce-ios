import Foundation
import Combine
import Yosemite

enum CardReaderSettingsUnknownViewModelDiscoveryState {
    case notSearching
    case searching
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

    private var cancellables: Set<AnyCancellable> = []

    var discoveryState: CardReaderSettingsUnknownViewModelDiscoveryState = .notSearching
    var foundReaderSerialNumber: String?

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

        ServiceLocator.connectedCardReaders
            .sink { [weak self] readers in
                guard let self = self else {
                    return
                }
                self.noConnectedReaders = readers.isEmpty ? .isTrue : .isFalse
                self.reevaluateShouldShow()
            }
            .store(in: &cancellables)
    }

    private func updateProperties() {
        guard let foundReader = foundReader else {
            foundReaderSerialNumber = nil
            return
        }

        foundReaderSerialNumber = foundReader.serial
    }

    /// Dispatch a request to start reader discovery
    ///
    func startReaderDiscovery() {
        discoveryState = .searching
        updateProperties()
        didUpdate?()

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: siteID) { [weak self] cardReaders in
            self?.didDiscoverReaders(cardReaders: cardReaders)
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Alert the user we have a found reader
    ///
    func didDiscoverReaders(cardReaders: [CardReader]) {
        /// If we are already presenting a foundReader alert to the user, ignore the found reader
        guard discoveryState != .foundReader else {
            return
        }

        /// Just in case we were called with an empty set
        guard cardReaders.count > 0 else {
            return
        }

        /// This viewmodel and view supports single reader discovery only.
        /// TODO: Add another viewmodel and view to handle multiple discovered readers.
        guard let cardReader = cardReaders.first else {
            return
        }

        foundReader = cardReader
        discoveryState = .foundReader
        updateProperties()
        didUpdate?()
    }

    /// Dispatch a request to cancel reader discovery
    ///
    func cancelReaderDiscovery() {
        discoveryState = .notSearching
        updateProperties()
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
        updateProperties()
        didUpdate?()

        let action = CardPresentPaymentAction.connect(reader: foundReader) { _ in
            /// Nothing to do here because, when the observed connectedReaders mutates, the
            /// connected view will be shown automatically.
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Discard the found reader and keep searching
    ///
    func continueSearch() {
        discoveryState = .searching
        foundReader = nil
        updateProperties()
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
