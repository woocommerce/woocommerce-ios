import Foundation
import Combine
import Yosemite

final class CardReaderSettingsSearchingViewModel: CardReaderSettingsPresentedViewModel {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?

    private(set) var noConnectedReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }
    private(set) var noKnownReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }
    private(set) var knownReadersProvider: CardReaderSettingsKnownReadersProvider?
    private(set) var siteID: Int64

    private var subscriptions = Set<AnyCancellable>()

    private var knownReaderIDs: [String]? {
        didSet {
            guard let knownReaderIDs = knownReaderIDs else {
                noKnownReader = .isUnknown
                return
            }

            noKnownReader = knownReaderIDs.isEmpty ? .isTrue : .isFalse
        }
    }
    private var foundReader: CardReader?

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
            self.noConnectedReader = readers.isEmpty ? .isTrue : .isFalse
            self.reevaluateShouldShow()
        }
        ServiceLocator.stores.dispatch(connectedAction)
    }

    /// Updates whether the view this viewModel is associated with should be shown or not
    /// Notifes the viewModel owner if a change occurs via didChangeShouldShow
    ///
    private func reevaluateShouldShow() {
        let newShouldShow: CardReaderSettingsTriState = noConnectedReader

        let didChange = newShouldShow != shouldShow

        shouldShow = newShouldShow

        if didChange {
            didChangeShouldShow?(shouldShow)
        }
    }
}
