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

        /// Found a card reader
        ///
        case foundReader

        /// Attempting to connect to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `True` result if successful, after which the view controller
        /// passed to `searchAndConnect` will be dereferenced and the state set to `idle`
        ///
        case connectToReader

        /// A failure occurred while connecting. The search may continue or be canceled. At this time we
        /// do not present the detailed error from the service.
        ///
        case connectingFailed(Error)

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
    private var knownCardReadersProvider: CardReaderSettingsKnownReadersProvider
    private var alerts: CardReaderSettingsAlertsProvider

    /// Reader(s) discovered by the card reader service
    ///
    private var foundReaders: [CardReader]

    /// Reader(s) known to us (i.e. we've connected to them in the past)
    ///
    private var knownReaderIDs: [String]

    /// Reader(s) discovered by the card reader service that the merchant declined to connect to
    ///
    private var skippedReaderIDs: [String]

    /// The reader we want the user to consider connecting to
    ///
    private var candidateReader: CardReader?

    private var subscriptions = Set<AnyCancellable>()

    private var onCompletion: ((Result<Bool, Error>) -> Void)?

    init(
        forSiteID: Int64,
        knownReadersProvider: CardReaderSettingsKnownReadersProvider,
        alertsProvider: CardReaderSettingsAlertsProvider
    ) {
        state = .idle
        siteID = forSiteID
        knownCardReadersProvider = knownReadersProvider
        alerts = alertsProvider
        foundReaders = []
        knownReaderIDs = []
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
        case .cancel:
            onCancel()
        case .connectToReader:
            onConnectToReader()
        case .connectingFailed(let error):
            onConnectingFailed(error: error)
        case .discoveryFailed(let error):
            onDiscoveryFailed(error: error)
        }
    }

    /// Updates the found readers list by removing any the user has asked
    /// us to ignore (aka keep searching) during this discovery session
    ///
    func pruneSkippedReaders() {
        self.foundReaders = self.foundReaders.filter({!skippedReaderIDs.contains($0.id)})
    }

    /// Returns the list of found readers which are also known
    ///
    func getFoundKnownReaders() -> [CardReader] {
        self.foundReaders.filter({knownReaderIDs.contains($0.id)})
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

        /// Fetch the list of known readers - i.e. readers we should automatically connect to when we see them
        ///
        knownCardReadersProvider.knownReaders.sink(receiveValue: { [weak self] readerIDs in
            guard let self = self else {
                return
            }

            self.knownReaderIDs = readerIDs

            /// Only kick off search if we received a known reader update during intializaton
            if case .initializing = self.state {
                self.state = .beginSearch
            }
        }).store(in: &subscriptions)
    }

    /// Begins the search for a card reader
    /// Does NOT open any modal
    /// Transitions state to `.searching`
    /// Later, when a reader is found, state transitions to `.foundReader` if it is unknown,
    /// or  to `.connectToReader` if it is known
    ///
    func onBeginSearch() {
        self.state = .searching
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            onReaderDiscovered: { [weak self] cardReaders in
                guard let self = self else {
                    return
                }

                /// First, update our copy of the foundReaders and prune
                /// skipped ones
                ///
                self.foundReaders = cardReaders
                self.pruneSkippedReaders()

                /// This completion can be called repeatedly as more readers
                /// become discovered. To avoid interrupting connecting to
                /// a known reader, or interrupting the user prompt for a unknown
                /// reader, ensure we are in the searching state first
                ///
                guard case .searching = self.state else {
                    return
                }

                /// If we have a known reader, advance immediately to connect
                ///
                if self.getFoundKnownReaders().isNotEmpty {
                    self.candidateReader = self.getFoundKnownReaders().first
                    self.state = .connectToReader
                    return
                }

                /// If we have a found (but unknown) reader, advance to foundReader
                ///
                if self.foundReaders.isNotEmpty {
                    self.candidateReader = self.foundReaders.first
                    self.state = .foundReader
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

        /// In the case of multiple found readers, we may have another reader to show
        /// to the user at this point, so don't open the searching modal, but go to
        /// onFoundReader
        if foundReaders.isNotEmpty {
            self.candidateReader = foundReaders.first
            self.state = .foundReader
            return
        }

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
        /// We always work with the first reader in the foundReaders array
        /// The array will have already had skipped (aka "keep searching") readers removed
        /// by time we get here
        ///
        guard let candidateReader = candidateReader else {
            return
        }

        guard let from = fromController else {
            return
        }

        let action = CardPresentPaymentAction.connect(reader: candidateReader) { result in
            switch result {
            case .success(let reader):
                self.knownCardReadersProvider.rememberCardReader(cardReaderID: reader.id)
                // If the reader does not have a battery, or the battery level is unknown, it will be nil
                let properties = reader.batteryLevel
                    .map { ["battery_level": $0] }
                ServiceLocator.analytics.track(.cardReaderConnectionSuccess, withProperties: properties)
                self.returnSuccess(connected: true)
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

        alerts.connectingFailed(
            from: from,
            continueSearch: {
                self.state = .searching
            }, cancelSearch: {
                self.state = .cancel
            }
        )
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
