import Combine
import Foundation
import UIKit
import Yosemite

/// Facilitates connecting to a card reader
///
final class CardReaderConnectionController {
    private enum ControllerState {
        /// Initial state of the controller
        ///
        case idle

        /// Initializing (fetching the list of any known readers)
        ///
        case initializing

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

        /// User cancelled search/connecting to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `False` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case cancel

        /// A failure occurred. The completion passed to `searchAndConnect`
        /// will be called with a `failure` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case discoveryFailed(Error)
    }

    private var state: ControllerState {
        didSet {
            didSetState()
        }
    }
    private var fromController: UIViewController?
    private var siteID: Int64
    private var knownCardReaderProvider: CardReaderSettingsKnownReaderProvider
    private var alerts: CardReaderSettingsAlertsProvider

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

    /// Since the number of readers can go greater than 1 and then back to 1, and we don't
    /// want to keep changing the UI from the several-readers-found list to a single prompt
    /// and back (as this would be visually quite annoying), this flag will tell us that we've
    /// already switched to list format for this discovery flow, so that stay in list mode
    /// even if the number of found readers drops to less than 2
    private var showSeveralFoundReaders: Bool = false

    private var softwareUpdateCancelable: FallibleCancelable? = nil

    private var subscriptions = Set<AnyCancellable>()

    private var onCompletion: ((Result<Bool, Error>) -> Void)?

    init(
        forSiteID: Int64,
        knownReaderProvider: CardReaderSettingsKnownReaderProvider,
        alertsProvider: CardReaderSettingsAlertsProvider
    ) {
        state = .idle
        siteID = forSiteID
        knownCardReaderProvider = knownReaderProvider
        alerts = alertsProvider
        foundReaders = []
        knownReaderID = nil
        skippedReaderIDs = []
    }

    deinit {
        subscriptions.removeAll()
    }

    func searchAndConnect(from: UIViewController?, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        guard from != nil else {
            return
        }

        self.fromController = from
        self.onCompletion = onCompletion
        self.state = .initializing
    }
}

private extension CardReaderConnectionController {
    func didSetState() {
        switch state {
        case .idle:
            onIdle()
        case .initializing:
            onInitialization()
        case .beginSearch:
            onBeginSearch()
        case .searching:
            onSearching()
        case .foundReader:
            onFoundReader()
        case .foundSeveralReaders:
            onFoundSeveralReaders()
        case .cancel:
            onCancel()
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

    /// Begins a fetch for the list of known readers
    /// Does NOT open any modal
    /// Transitions state to `.beginSearch` after receiving the known readers list
    ///
    func onInitialization() {
        /// Always start fresh - i.e. we haven't skipped connecting to any reader yet
        ///
        skippedReaderIDs = []
        candidateReader = nil
        showSeveralFoundReaders = false

        /// Fetch the list of known readers - i.e. readers we should automatically connect to when we see them
        ///
        knownCardReaderProvider.knownReader.sink(receiveValue: { [weak self] readerID in
            guard let self = self else {
                return
            }

            self.knownReaderID = readerID

            /// Only kick off search if we received a known reader update during intializaton
            if case .initializing = self.state {
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
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
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
                    self.alerts.updateSeveralReadersList(readerIDs: self.getFoundReaderIDs())
                }

                /// To avoid interrupting connecting to a known reader, ensure we are
                /// in the searching state before proceeding further
                ///
                guard case .searching = self.state else {
                    return
                }

                /// If we have a known reader, advance immediately to connect
                ///
                if let foundKnownReader = self.getFoundKnownReader() {
                    self.candidateReader = foundKnownReader
                    self.state = .connectToReader
                    return
                }

                /// If we have found multiple readers, advance to foundMultipleReaders
                ///
                if self.showSeveralFoundReaders {
                    self.state = .foundSeveralReaders
                    return
                }

                /// If we have a found (but unknown) reader, advance to foundReader
                ///
                if self.foundReaders.isNotEmpty {
                    self.candidateReader = self.foundReaders.first
                    self.state = .foundReader
                    return
                }
            },
            onError: { [weak self] error in
                guard let self = self else {
                    return
                }

                ServiceLocator.analytics.track(.cardReaderDiscoveryFailed, withError: error)
                self.state = .discoveryFailed(error)
            })

        ServiceLocator.stores.dispatch(action)
    }

    /// Opens the scanning for reader modal
    /// If the user cancels the modal will trigger a transition to `.endSearch`
    ///
    func onSearching() {
        guard let from = fromController else {
            return
        }

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
        alerts.scanningForReader(from: from, cancel: {
            self.state = .cancel
        })
    }

    /// A (unknown) reader has been found
    /// Opens a confirmation modal for the user to accept the candidate reader (or keep searching)
    ///
    func onFoundReader() {
        guard let candidateReader = candidateReader else {
            return
        }

        guard let from = fromController else {
            return
        }

        alerts.foundReader(
            from: from,
            name: candidateReader.id,
            connect: {
                self.state = .connectToReader
            },
            continueSearch: {
                self.skippedReaderIDs.append(candidateReader.id)
                self.candidateReader = nil
                self.pruneSkippedReaders()
                self.state = .searching
            })
    }

    /// Several readers have been found
    /// Opens a continually updating list modal for the user to pick one (or cancel the search)
    ///
    func onFoundSeveralReaders() {
        guard let from = fromController else {
            return
        }

        alerts.foundSeveralReaders(
            from: from,
            readerIDs: getFoundReaderIDs(),
            connect: { [weak self] readerID in
                guard let self = self else {
                    return
                }
                self.candidateReader = self.getFoundReaderByID(readerID: readerID)
                self.state = .connectToReader
            },
            cancelSearch: { [weak self] in
                self?.state = .cancel
            }
        )
    }

    /// A mandatory update is being installed
    ///
    func onUpdateProgress(progress: Float) {
        guard let from = fromController else {
            return
        }

        let cancel = softwareUpdateCancelable.map { cancelable in
            return { [weak self] in
                self?.state = .cancel
                let analyticsProperties = [SoftwareUpdateTypeProperty.name: SoftwareUpdateTypeProperty.required.rawValue]
                ServiceLocator.analytics.track(.cardReaderSoftwareUpdateCancelTapped, withProperties: analyticsProperties)
                cancelable.cancel { result in
                    if case .failure(let error) = result {
                        print("=== error canceling software update: \(error)")
                    } else {
                        ServiceLocator.analytics.track(.cardReaderSoftwareUpdateCanceled, withProperties: analyticsProperties)
                    }
                }
            }
        }

        alerts.updateProgress(from: from,
                              requiredUpdate: true,
                              progress: progress,
                              cancel: cancel)
    }

    /// End the search for a card reader
    ///
    func onCancel() {
        alerts.dismiss()
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() { [weak self] _ in
            self?.returnSuccess(connected: false)
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Connect to the candidate card reader
    ///
    func onConnectToReader() {
        guard let candidateReader = candidateReader else {
            return
        }

        guard let from = fromController else {
            return
        }

        let softwareUpdateAction = CardPresentPaymentAction.observeCardReaderUpdateState { [weak self] softwareUpdateEvents in
            guard let self = self else { return }

            softwareUpdateEvents.sink { event in
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
        ServiceLocator.stores.dispatch(softwareUpdateAction)

        let action = CardPresentPaymentAction.connect(reader: candidateReader) { result in
            switch result {
            case .success(let reader):
                self.knownCardReaderProvider.rememberCardReader(cardReaderID: reader.id)
                // If the reader does not have a battery, or the battery level is unknown, it will be nil
                let properties = reader.batteryLevel
                    .map { ["battery_level": $0] }
                ServiceLocator.analytics.track(.cardReaderConnectionSuccess, withProperties: properties)
                // If we were installing a software update, introduce a small delay so the user can
                // actually see a success message showing the installation was complete
                if case .updating(progress: 1) = self.state {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.returnSuccess(connected: true)
                    }
                } else {
                    self.returnSuccess(connected: true)
                }
            case .failure(let error):
                ServiceLocator.analytics.track(.cardReaderConnectionFailed, withError: error)
                self.state = .connectingFailed(error)
            }
        }
        ServiceLocator.stores.dispatch(action)

        alerts.connectingToReader(from: from)
    }

    /// An error occurred while connecting
    ///
    private func onConnectingFailed(error: Error) {
        guard let from = fromController else {
            return
        }

        /// Clear our copy of found readers to avoid connecting to a reader that isn't
        /// there while we wait for `onReaderDiscovered` to receive an update.
        /// See also https://github.com/stripe/stripe-terminal-ios/issues/104#issuecomment-916285167
        ///
        self.foundReaders = []

        if case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: _) = error,
           underlyingError.isSoftwareUpdateError {
            return onUpdateFailed(error: error)
        }

        alerts.connectingFailed(
            from: from,
            continueSearch: {
                self.state = .searching
            }, cancelSearch: {
                self.state = .cancel
            }
        )
    }

    private func onUpdateFailed(error: Error) {
        guard let from = fromController,
              case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: let batteryLevel) = error else {
            return
        }

        if underlyingError == .readerSoftwareUpdateFailedBatteryLow {
            alerts.updatingFailedLowBattery(
                from: from,
                batteryLevel: batteryLevel,
                close: {
                    self.state = .searching
                }
            )
        } else {
            alerts.updatingFailed(
                from: from,
                tryAgain: nil,
                close: {
                    self.state = .searching
                })
        }
    }

    /// An error occurred during discovery
    /// Presents the error in a modal
    ///
    private func onDiscoveryFailed(error: Error) {
        guard let from = fromController else {
            return
        }

        alerts.scanningFailed(from: from, error: error) { [weak self] in
            self?.returnFailure(error: error)
        }
    }

    /// Calls the completion with a success result
    ///
    private func returnSuccess(connected: Bool) {
        self.alerts.dismiss()
        self.onCompletion?(.success(connected))
        self.fromController = nil
        self.state = .idle
    }

    /// Calls the completion with a failure result
    ///
    private func returnFailure(error: Error) {
        self.alerts.dismiss()
        self.onCompletion?(.failure(error))
        self.fromController = nil
        self.state = .idle
    }
}
