import Foundation
import Yosemite

enum CardReaderSettingsUnknownViewModelDiscoveryState {
    case notSearching
    case searching
    // TODO add foundReader and connecting states in 4055
}

final class CardReaderSettingsUnknownViewModel: CardReaderSettingsPresentedViewModel {

    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private var noConnectedReaders: CardReaderSettingsTriState = .isUnknown
    private var noKnownReaders: CardReaderSettingsTriState = .isUnknown

    private var siteID: Int64 = Int64.min

    var discoveryState: CardReaderSettingsUnknownViewModelDiscoveryState = .notSearching

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

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: siteID) { _ in
            // TODO prompt as readers become found in 4055
        }
        ServiceLocator.stores.dispatch(action)
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
