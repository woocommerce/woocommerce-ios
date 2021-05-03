import Foundation
import Yosemite

final class CardReaderSettingsConnectedViewModel: CardReaderSettingsPresentedViewModel {

    var shouldShow: CardReaderSettingsTriState
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?

    private var didGetConnectedReaders: Bool
    private var connectedReaders: [CardReader]

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?) {

        self.didChangeShouldShow = didChangeShouldShow
        self.shouldShow = .isUnknown
        self.didGetConnectedReaders = false
        self.connectedReaders = []

        beginObservation()
    }

    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of
    /// connected readers.
    ///
    private func beginObservation() {

        // This completion should be called repeatedly as the list of connected readers changes
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            guard let self = self else {
                return
            }
            self.didGetConnectedReaders = true
            self.connectedReaders = readers
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {

        var newShouldShow: CardReaderSettingsTriState = .isUnknown

        if !didGetConnectedReaders {
            newShouldShow = .isUnknown
        } else if connectedReaders.isEmpty {
            newShouldShow = .isFalse
        } else {
            newShouldShow = .isTrue
        }

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }
}
