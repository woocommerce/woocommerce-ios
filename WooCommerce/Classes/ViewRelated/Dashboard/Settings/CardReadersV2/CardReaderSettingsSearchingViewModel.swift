import Foundation
import Combine
import Yosemite

final class CardReaderSettingsSearchingViewModel: CardReaderSettingsPresentedViewModel {
    private(set) var shouldShow: CardReaderSettingsTriState = .isUnknown
    var didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?
    var didUpdate: (() -> Void)?
    var learnMoreURL: URL? = nil
    let stores: StoresManager

    private(set) var noConnectedReader: CardReaderSettingsTriState = .isUnknown {
        didSet {
            didUpdate?()
        }
    }

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

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?, knownReaderProvider: CardReaderSettingsKnownReaderProvider? = nil,
         stores: StoresManager = ServiceLocator.stores
    ) {
        self.stores = stores
        self.didChangeShouldShow = didChangeShouldShow
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        self.knownReaderProvider = knownReaderProvider

        beginKnownReaderObservation()
        beginConnectedReaderObservation()
        updateLearnMoreURL()
    }

    deinit {
        subscriptions.removeAll()
    }

    func hasKnownReader() -> Bool {
        knownReaderID != nil
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
    
    private func updateLearnMoreURL() {
        let loadLearnMoreUrlAction = CardPresentPaymentAction
            .loadLearnMoreURL(preferredPaymentGateway: nil) { [weak self] result in
                self?.learnMoreURL = result
            }
        stores.dispatch(loadLearnMoreUrlAction)
    }
}
