import Combine
import Foundation
import Storage
import SwiftUI

public enum CardReaderConnectionResult {
    case connected(CardReader)
    case canceled(CardReaderConnectionCancellationSource)
}

public enum CardReaderConnectionCancellationSource: String {
    // TODO: move raw value to analytics extension
    case appleTOSAcceptance = "apple_tap_to_pay_terms_acceptance"
    case reader = "card_reader"
    case selectReaderType = "preflight_select_reader_type"
    case searchingForReader = "searching_for_reader"
    case foundReader = "found_reader"
    case foundSeveralReaders = "found_several_readers"
    case paymentValidatingOrder = "payment_validating_order"
    case paymentPreparingReader = "payment_preparing_reader"
    case paymentWaitingForInput = "payment_waiting_for_input"
    case connectionError = "connection_error"
    case readerSoftwareUpdate = "reader_software_update"
    case other = "unknown"
}

/// Facilitates connecting to a card reader
///
public class CardReaderConnectionController {
    public enum UIState {
        case scanningForReader(cancel: () -> Void)
        case connectingToReader
        case connectingFailed(error: Error,
                              retrySearch: () -> Void,
                              cancelSearch: () -> Void)
        case connectingFailedIncompleteAddress(adminUrlForWCSettings: URL?,
                                               showIncompleteAddressErrorWithRefreshButton: () -> Void,
                                               retrySearch: () -> Void,
                                               cancelSearch: () -> Void)

        /// Defines an alert indicating connecting failed because their postal code needs updating.
        /// The user may try again or cancel
        ///
        case connectingFailedInvalidPostalCode(retrySearch: () -> Void,
                                               cancelSearch: () -> Void)
        case connectingFailedCriticallyLowBattery(retrySearch: () -> Void,
                                                  cancelSearch: () -> Void)
        case foundReader(name: String,
                         connect: () -> Void,
                         continueSearch: () -> Void,
                         cancelSearch: () -> Void)
        case foundSeveralReaders(readerIDs: [String],
                                 connect: (String) -> Void,
                                 cancelSearch: () -> Void)
        case updateSeveralReadersList(readerIDs: [String])
        case updateInProgress(requiredUpdate: Bool,
                              progress: Float,
                              cancel: (() -> Void)?)
        case updatingFailed(tryAgain: (() -> Void)?, close: () -> Void)
        case updatingFailedLowBattery(batteryLevel: Double?,
                                      close: () -> Void)
        case scanningFailed(error: Error, close: () -> Void)
        case dismissed
    }

    private enum ControllerState {
        /// Initial state of the controller
        ///
        case idle

        /// Initializing (fetching payment gateway accounts)
        ///
        case initializing

        /// Preparing for search (fetching the list of any known readers)
        ///
        case preparingForSearch

        /// Begin search for card readers
        ///
        case beginSearch

        /// Searching for a card reader
        ///
        case searching

        /// Found one card reader
        ///
        case foundReader

        /// Found two or more card readers
        ///
        case foundSeveralReaders

        /// Attempting to connect to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `True` result if successful, after which the view controller
        /// passed to `searchAndConnect` will be dereferenced and the state set to `idle`
        ///
        case connectToReader

        /// A failure occurred while connecting. The search may continue or be canceled. At this time we
        /// do not present the detailed error from the service.
        ///
        case connectingFailed(Error)

        /// A mandatory update is being installed
        ///
        case updating(progress: Float)

        /// User chose to retry the connection to the card reader. Starts the search again, by dismissing modals and initializing from scratch
        ///
        case retry

        /// User cancelled search/connecting to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `False` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case cancel(source: CardReaderConnectionCancellationSource)

        /// A failure occurred. The completion passed to `searchAndConnect`
        /// will be called with a `failure` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case discoveryFailed(Error)
    }

    @Published public private(set) var uiState: UIState?

    private let storageManager: StorageManagerType
    private let stores: StoresManager

    private var state: ControllerState {
        didSet {
            didSetState()
        }
    }

    private let siteID: Int64
    private let knownCardReaderProvider: CardReaderSettingsKnownReaderProvider
    private let configuration: CardPresentPaymentsConfiguration

    /// Reader(s) discovered by the card reader service
    ///
    private var foundReaders: [CardReader]

    /// Reader(s) known to us (i.e. we've connected to them in the past)
    ///
    private var knownReaderID: String?

    /// Reader(s) discovered by the card reader service that the merchant declined to connect to
    ///
    private var skippedReaderIDs: [String]

    /// The reader we want the user to consider connecting to
    ///
    private var candidateReader: CardReader?

    // TODO: update tracker to protocol
    /// Tracks analytics for card reader connection events
    ///
//    private let analyticsTracker: CardReaderConnectionAnalyticsTracker

    /// Since the number of readers can go greater than 1 and then back to 1, and we don't
    /// want to keep changing the UI from the several-readers-found list to a single prompt
    /// and back (as this would be visually quite annoying), this flag will tell us that we've
    /// already switched to list format for this discovery flow, so that stay in list mode
    /// even if the number of found readers drops to less than 2
    private var showSeveralFoundReaders: Bool = false

    private var softwareUpdateCancelable: FallibleCancelable? = nil

    private var subscriptions = Set<AnyCancellable>()

    private var onCompletion: ((Result<CardReaderConnectionResult, Error>) -> Void)?

    private(set) lazy var dataSource: CardReaderSettingsDataSource = {
        return CardReaderSettingsDataSource(siteID: siteID, storageManager: storageManager)
    }()

    /// Gateway ID to include in tracks events
    private var gatewayID: String? {
        didSet {
            didSetGatewayID()
//            analyticsTracker.setGatewayID(gatewayID: gatewayID)
        }
    }

    public init(
        siteID: Int64,
        storageManager: StorageManagerType,
        stores: StoresManager,
        knownReaderProvider: CardReaderSettingsKnownReaderProvider,
        configuration: CardPresentPaymentsConfiguration
    ) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        state = .idle
        knownCardReaderProvider = knownReaderProvider
        foundReaders = []
        knownReaderID = nil
        skippedReaderIDs = []
        self.configuration = configuration

        configureResultsControllers()
    }

    deinit {
        subscriptions.removeAll()
    }

    public func searchAndConnect(onCompletion: @escaping (Result<CardReaderConnectionResult, Error>) -> Void) {
        Task { @MainActor [weak self] in
            self?.onCompletion = onCompletion
            self?.state = .initializing
        }
    }
}

private extension CardReaderConnectionController {
    func configureResultsControllers() {
        dataSource.configureResultsControllers(onReload: { [weak self] in
            guard let self = self else { return }
            self.gatewayID = self.dataSource.cardPresentPaymentGatewayID()
        })
        // Sets gateway ID from initial fetch.
        gatewayID = dataSource.cardPresentPaymentGatewayID()
    }

    func didSetState() {
        switch state {
        case .idle:
            onIdle()
        case .initializing:
            onInitialization()
        case .preparingForSearch:
            onPreparingForSearch()
        case .beginSearch:
            onBeginSearch()
        case .searching:
            onSearching()
        case .foundReader:
            onFoundReader()
        case .foundSeveralReaders:
            onFoundSeveralReaders()
        case .retry:
            onRetry()
        case .cancel(let cancellationSource):
            onCancel(from: cancellationSource)
        case .connectToReader:
            onConnectToReader()
        case .connectingFailed(let error):
            onConnectingFailed(error: error)
        case .discoveryFailed(let error):
            onDiscoveryFailed(error: error)
        case .updating(progress: let progress):
            onUpdateProgress(progress: progress)
        }
    }

    /// Once the gatewayID arrives (during initialization) it is OK to proceed with search preparations
    ///
    func didSetGatewayID() {
        if case .initializing = state {
            state = .preparingForSearch
        }
    }

    /// To avoid presenting the "Do you want to connect to reader XXXX" prompt
    /// repeatedly for the same reader, keep track of readers the user has tapped
    /// "Keep Searching" for.
    ///
    /// If we have switched to the list view, however, don't prune
    ///
    func pruneSkippedReaders() {
        guard !showSeveralFoundReaders else {
            return
        }
        foundReaders = foundReaders.filter({!skippedReaderIDs.contains($0.id)})
    }

    /// Returns any found reader which is also known
    ///
    func getFoundKnownReader() -> CardReader? {
        foundReaders.filter({knownReaderID == $0.id}).first
    }

    /// A helper to return an array of found reader IDs
    ///
    func getFoundReaderIDs() -> [String] {
        foundReaders.compactMap({$0.id})
    }

    /// A helper to return a specific CardReader instance based on the reader ID
    ///
    func getFoundReaderByID(readerID: String) -> CardReader? {
        foundReaders.first(where: {$0.id == readerID})
    }

    /// Updates the show multiple readers flag to indicate that, for this discovery flow,
    /// we have already shown the multiple readers UI (so we don't switch back to the
    /// single reader found UI for this particular discovery)
    ///
    func updateShowSeveralFoundReaders() {
        if foundReaders.containsMoreThanOne {
            showSeveralFoundReaders = true
        }
    }

    /// Initial state of the controller
    ///
    func onIdle() {
    }

    /// Searching for a reader is about to begin. Wait, if needed, for the gateway ID to be provided from the FRC
    ///
    func onInitialization() {
        if gatewayID != nil {
            state = .preparingForSearch
        }
    }

    /// In preparation for search, initiates a fetch for the list of known readers
    /// Does NOT open any modal
    /// Transitions state to `.beginSearch` after receiving the known readers list
    ///
    func onPreparingForSearch() {
        /// Always start fresh - i.e. we haven't skipped connecting to any reader yet
        ///
        skippedReaderIDs = []
        candidateReader = nil
        showSeveralFoundReaders = false

        /// Fetch the list of known readers - i.e. readers we should automatically connect to when we see them
        ///
        knownCardReaderProvider.knownReader
            .subscribe(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] readerID in
            guard let self = self else {
                return
            }

            self.knownReaderID = readerID

            /// Only kick off search if we received a known reader update
            if case .preparingForSearch = self.state {
                self.state = .beginSearch
            }
        }).store(in: &subscriptions)
    }

    /// Begins the search for a card reader
    /// Does NOT open any modal
    /// Transitions state to `.searching`
    /// Later, when a reader is found, state transitions to
    /// `.foundReader` if one unknown reader is found,
    /// `.foundMultipleReaders` if two or more readers are found,
    /// or  to `.connectToReader` if one known reader is found
    ///
    func onBeginSearch() {
        self.state = .searching
        var didAutoAdvance = false

        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            discoveryMethod: .bluetoothScan,
            onReaderDiscovered: { [weak self] cardReaders in
                guard let self = self else {
                    return
                }

                /// Update our copy of the foundReaders, evaluate if we should switch to the list view,
                /// and prune skipped ones
                ///
                self.foundReaders = cardReaders
                self.updateShowSeveralFoundReaders()
                self.pruneSkippedReaders()

                /// Note: This completion will be called repeatedly as the list of readers
                /// discovered changes, so some care around state must be taken here.
                ///

                /// If the found-several-readers view is already presenting, update its list of found readers
                ///
                if case .foundSeveralReaders = self.state {
                    uiState = .updateSeveralReadersList(readerIDs: getFoundReaderIDs())
                }

                /// To avoid interrupting connecting to a known reader, ensure we are
                /// in the searching state before proceeding further
                ///
                guard case .searching = self.state else {
                    return
                }

                /// If we have a known reader, and we haven't auto-advanced to connect
                /// already, advance immediately to connect.
                /// We only auto-advance once to avoid loops in case the known reader
                /// is having connectivity issues (e.g low battery)
                ///
                if let foundKnownReader = self.getFoundKnownReader() {
                    if !didAutoAdvance {
                        didAutoAdvance = true
                        self.candidateReader = foundKnownReader
                        self.state = .connectToReader
                        return
                    }
                }

                /// If we have found multiple readers, advance to foundMultipleReaders
                ///
                if self.showSeveralFoundReaders {
                    self.state = .foundSeveralReaders
                    return
                }

                /// If we have a found reader, advance to foundReader
                ///
                if self.foundReaders.isNotEmpty {
                    self.candidateReader = self.foundReaders.first
                    self.state = .foundReader
                    return
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }

//                self.analyticsTracker.discoveryFailed(error: error)
                self.state = .discoveryFailed(error)
            })

        stores.dispatch(action)
    }

    /// Opens the scanning for reader modal
    /// If the user cancels the modal will trigger a transition to `.endSearch`
    ///
    func onSearching() {
        /// If we enter this state and another reader was discovered while the
        /// "Do you want to connect to" modal was being displayed and if that reader
        /// is known and the merchant tapped keep searching on the first
        /// (unknown) reader, auto-connect to that known reader
        if let foundKnownReader = self.getFoundKnownReader() {
            self.candidateReader = foundKnownReader
            self.state = .connectToReader
            return
        }

        /// If we already have found readers
        /// display the list view if so enabled, or...
        ///
        if showSeveralFoundReaders {
            self.state = .foundSeveralReaders
            return
        }

        /// Display the single view and ask the merchant if they'd
        /// like to connect to it
        ///
        if foundReaders.isNotEmpty {
            self.candidateReader = foundReaders.first
            self.state = .foundReader
            return
        }

        /// If all else fails, display the "scanning" modal and
        /// stay in this state
        ///
        uiState = .scanningForReader(cancel: { [weak self] in
            self?.state = .cancel(source: .searchingForReader)
        })
    }

    /// A (unknown) reader has been found
    /// Opens a confirmation modal for the user to accept the candidate reader (or keep searching)
    ///
    func onFoundReader() {
        guard let candidateReader = candidateReader else {
            return
        }

        uiState = .foundReader(name: candidateReader.id,
                               connect: { [weak self] in
            self?.state = .connectToReader
        },
                               continueSearch: { [weak self] in
            guard let self else { return }
            skippedReaderIDs.append(candidateReader.id)
            self.candidateReader = nil
            pruneSkippedReaders()
            state = .searching
        },
                               cancelSearch: { [weak self] in
            self?.state = .cancel(source: .foundReader)
        })
    }

    /// Several readers have been found
    /// Opens a continually updating list modal for the user to pick one (or cancel the search)
    ///
    func onFoundSeveralReaders() {
        uiState = .foundSeveralReaders(
            readerIDs: getFoundReaderIDs(),
            connect: { [weak self] readerID in
                guard let self = self else {
                    return
                }
                self.candidateReader = self.getFoundReaderByID(readerID: readerID)
                self.state = .connectToReader
            },
            cancelSearch: { [weak self] in
                self?.state = .cancel(source: .foundSeveralReaders)
            }
        )
    }

    /// A mandatory update is being installed
    ///
    func onUpdateProgress(progress: Float) {
        let cancel = softwareUpdateCancelable.map { cancelable in
            return { [weak self] in
                guard let self = self else { return }
                self.state = .cancel(source: .readerSoftwareUpdate)
//                self.analyticsTracker.cardReaderSoftwareUpdateCancelTapped()
                cancelable.cancel { [weak self] result in
                    if case .failure(let error) = result {
                        DDLogError("💳 Error: canceling software update \(error)")
                    } else {
//                        self?.analyticsTracker.cardReaderSoftwareUpdateCanceled()
                    }
                }
            }
        }

        uiState = .updateInProgress(requiredUpdate: true,
                                    progress: progress,
                                    cancel: cancel)
    }

    /// Retry a search for a card reader
    ///
    func onRetry() {
        uiState = .dismissed
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { [weak self] _ in
            self?.state = .beginSearch
        }
        stores.dispatch(action)
    }

    /// End the search for a card reader
    ///
    func onCancel(from cancellationSource: CardReaderConnectionCancellationSource) {
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { [weak self] _ in
            self?.returnSuccess(result: .canceled(cancellationSource))
        }
        stores.dispatch(action)
    }

    /// Connect to the candidate card reader
    ///
    func onConnectToReader() {
        guard let candidateReader = candidateReader else {
            return
        }

//        analyticsTracker.setCandidateReader(candidateReader)

        let softwareUpdateAction = CardPresentPaymentAction.observeCardReaderUpdateState { [weak self] softwareUpdateEvents in
            guard let self = self else { return }

            softwareUpdateEvents
                .subscribe(on: DispatchQueue.main)
                .sink { [weak self] event in
                guard let self = self else { return }

                switch event {
                case .started(cancelable: let cancelable):
                    self.softwareUpdateCancelable = cancelable
                    self.state = .updating(progress: 0)
                case .installing(progress: let progress):
                    if progress >= 0.995 {
                        self.softwareUpdateCancelable = nil
                    }
                    self.state = .updating(progress: progress)
                case .completed:
                    self.softwareUpdateCancelable = nil
                    self.state = .updating(progress: 1)
                default:
                    break
                }
            }
            .store(in: &self.subscriptions)
        }
        stores.dispatch(softwareUpdateAction)

        let action = CardPresentPaymentAction.connect(reader: candidateReader) { [weak self] result in
            guard let self = self else { return }

//            self.analyticsTracker.setCandidateReader(nil)

            switch result {
            case .success(let reader):
                self.knownCardReaderProvider.rememberCardReader(cardReaderID: reader.id)
//                self.analyticsTracker.connectionSuccess(batteryLevel: reader.batteryLevel,
//                                                        cardReaderModel: reader.readerType.model)
                // If we were installing a software update, introduce a small delay so the user can
                // actually see a success message showing the installation was complete
                if case .updating(progress: 1) = self.state {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.returnSuccess(result: .connected(reader))
                    }
                } else {
                    self.returnSuccess(result: .connected(reader))
                }
            case .failure(let error):
//                self.analyticsTracker.connectionFailed(error: error,
//                                                       cardReaderModel: candidateReader.readerType.model)
                self.state = .connectingFailed(error)
            }
        }
        stores.dispatch(action)

        uiState = .connectingToReader
    }

    /// An error occurred while connecting
    ///
    private func onConnectingFailed(error: Error) {
        /// Clear our copy of found readers to avoid connecting to a reader that isn't
        /// there while we wait for `onReaderDiscovered` to receive an update.
        /// See also https://github.com/stripe/stripe-terminal-ios/issues/104#issuecomment-916285167
        ///
        self.foundReaders = []

        if case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: _) = error,
           underlyingError.isSoftwareUpdateError {
            return onUpdateFailed(error: error)
        }
        showConnectionFailed(error: error)
    }

    private func onUpdateFailed(error: Error) {
        guard case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: let batteryLevel) = error else {
            return
        }

        switch underlyingError {
            case .readerSoftwareUpdateFailedInterrupted:
                // Update was cancelled, don't treat this as an error
                return
            case .readerSoftwareUpdateFailedBatteryLow:
                uiState = .updatingFailedLowBattery(batteryLevel: batteryLevel,
                                                    close: { [weak self] in
                    self?.state = .searching
                })
            default:
                // TODO: consider removing `tryAgain` if we're only passing nil
                uiState = .updatingFailed(tryAgain: nil, close: { [weak self] in
                    self?.state = .searching
                })
        }
    }

    private func showConnectionFailed(error: Error) {
        let retrySearch = {
            self.state = .retry
        }

        let continueSearch = {
            self.state = .searching
        }

        let cancelSearch = {
            self.state = .cancel(source: .connectionError)
        }
        guard case CardReaderServiceError.connection(let underlyingError) = error else {
            return uiState = .connectingFailed(error: error,
                                               retrySearch: continueSearch,
                                               cancelSearch: cancelSearch)
        }

        switch underlyingError {
            case .incompleteStoreAddress(let adminUrl):
                // TODO: make sure to test this scenario
                uiState = .connectingFailedIncompleteAddress(adminUrlForWCSettings: adminUrl,
                                                             showIncompleteAddressErrorWithRefreshButton: showIncompleteAddressErrorWithRefreshButton,
                                                             retrySearch: retrySearch,
                                                             cancelSearch: cancelSearch)
            case .invalidPostalCode:
                uiState = .connectingFailedInvalidPostalCode(retrySearch: retrySearch,
                                                             cancelSearch: cancelSearch)
            case .bluetoothConnectionFailedBatteryCriticallyLow:
                uiState = .connectingFailedCriticallyLowBattery(retrySearch: retrySearch,
                                                                cancelSearch: cancelSearch)
            default:
                // We continueSearch here from a button labeled `Try again`, rather than retrying from the beginning,
                // this is because the original reader can be re-discovered in the same process.
                uiState = .connectingFailed(error: error,
                                            retrySearch: continueSearch,
                                            cancelSearch: cancelSearch)
        }
    }

    private func showIncompleteAddressErrorWithRefreshButton() {
        showConnectionFailed(error: CardReaderServiceError.connection(underlyingError: .incompleteStoreAddress(adminUrl: nil)))
    }

    /// An error occurred during discovery
    /// Presents the error in a modal
    ///
    private func onDiscoveryFailed(error: Error) {
        uiState = .scanningFailed(error: error,
                                  close: { [weak self] in
            self?.returnFailure(error: error)
        })
    }

    /// Calls the completion with a success result
    ///
    private func returnSuccess(result: CardReaderConnectionResult) {
        onCompletion?(.success(result))
        state = .idle
    }

    /// Calls the completion with a failure result
    ///
    private func returnFailure(error: Error) {
        onCompletion?(.failure(error))
        state = .idle
    }
}
