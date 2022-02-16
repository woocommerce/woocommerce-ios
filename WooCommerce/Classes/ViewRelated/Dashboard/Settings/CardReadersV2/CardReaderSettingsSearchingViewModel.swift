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

    /// The connected gateway ID (plugin slug) - useful for the view controller's tracks events
    var connectedGatewayID: String?

    /// The datasource that will be used to help render the related screens
    ///
    private(set) lazy var dataSource: CardReaderSettingsDataSource = {
        return CardReaderSettingsDataSource(siteID: siteID)
    }()

    init(didChangeShouldShow: ((CardReaderSettingsTriState) -> Void)?, knownReaderProvider: CardReaderSettingsKnownReaderProvider? = nil) {
        self.didChangeShouldShow = didChangeShouldShow
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min
        self.knownReaderProvider = knownReaderProvider

        configureResultsControllers()
        loadPaymentGatewayAccounts()
        beginKnownReaderObservation()
        beginConnectedReaderObservation()
    }


    private func configureResultsControllers() {
        dataSource.configureResultsControllers(onReload: { [weak self] in
            guard let self = self else { return }
            self.connectedGatewayID = self.dataSource.cardPresentPaymentGatewayID()
        })
    }

    private func loadPaymentGatewayAccounts() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID else {
            return
        }

        /// No need for a completion here. We will be notified of storage changes in `onDidChangeContent`
        ///
        let action = CardPresentPaymentAction.loadAccounts(siteID: siteID) {_ in}
        ServiceLocator.stores.dispatch(action)
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
}
