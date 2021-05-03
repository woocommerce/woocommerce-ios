import Foundation
import Yosemite

final class CardReaderSettingsUnknownViewModel: CardReaderSettingsPresentedViewModel {

    var shouldShow: CardReaderSettingsTriState
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?

    private var noConnectedReaders: CardReaderSettingsTriState
    private var noKnownReaders: CardReaderSettingsTriState

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?) {

        self.didChangeShouldShow = didChangeShouldShow
        self.shouldShow = .isUnknown
        self.noConnectedReaders = .isUnknown
        self.noKnownReaders = .isUnknown

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
