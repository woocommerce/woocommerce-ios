import Foundation
import Yosemite

final class CardReaderSettingsUnknownViewModel: CardReaderSettingsPresentedViewModel {
    var shouldShow: Bool
    var didChangeShouldShow: ((Bool) -> Void)?

    private var noConnectedReaders: Bool
    private var noKnownReaders: Bool

    init(didChangeShouldShow: ((Bool) -> Void)?) {

        // Default shouldShow to true, since we don't know if there are any known or connected readers
        // TODO: Decide if we want a flag to reflect this initial state and use it to drive a loading indicator

        self.shouldShow = true
        self.didChangeShouldShow = didChangeShouldShow
        self.noConnectedReaders = true
        self.noKnownReaders = true

        beginObservation()
    }

    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of known
    /// and connected readers.
    ///
    private func beginObservation() {

        // This completion should be called repeatedly as the list of known readers changes
        let knownAction = CardPresentPaymentAction.observeKnownReaders() { [weak self] readers in
            self?.noKnownReaders = readers.isEmpty
            self?.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(knownAction)

        // This completion should be called repeatedly as the list of connected readers changes
        let connectedAction = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            self?.noConnectedReaders = readers.isEmpty
            self?.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(connectedAction)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {

        let newShouldShow = noKnownReaders && noConnectedReaders

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }
}
