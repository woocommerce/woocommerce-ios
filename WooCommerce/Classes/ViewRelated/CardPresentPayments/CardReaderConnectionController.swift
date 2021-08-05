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

        /// User cancelled search/connecting to a card reader. The completion passed to `searchAndConnect`
        /// will be called with a `success` `Bool` `False` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case cancel

        /// A failure occurred. The completion passed to `searchAndConnect`
        /// will be called with a `failure` result. The view controller passed to `searchAndConnect` will be
        /// dereferenced and the state set to `idle`
        ///
        case failed(Error)
    }

    private var state: ControllerState {
        didSet {
            didSetState()
        }
    }
    private var fromController: UIViewController?
    private var siteID: Int64
    private var knownCardReadersProvider: CardReaderSettingsKnownReadersProvider

    private var foundReader: CardReader?
    private var knownReaderIDs: [String]
    private var subscriptions = Set<AnyCancellable>()

    private var onCompletion: ((Result<Bool, Error>) -> Void)?

    private lazy var alerts: CardReaderSettingsAlerts = {
        CardReaderSettingsAlerts()
    }()

    init(
        forSiteID: Int64,
        knownReadersProvider: CardReaderSettingsKnownReadersProvider
    ) {
        state = .idle
        siteID = forSiteID
        knownCardReadersProvider = knownReadersProvider
        knownReaderIDs = []
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
        case .failed(let error):
            onFailed(error: error)
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
        knownCardReadersProvider.knownReaders.sink(receiveValue: { [weak self] readerIDs in
            self?.knownReaderIDs = readerIDs
            self?.state = .beginSearch
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

                /// Surprisingly, onReaderDiscovered may be called with an empty array
                ///
                guard cardReaders.count > 0 else {
                    return
                }

                /// For now, we only work with the first card reader returned
                /// When we stop using proximity, we'll need more elaborate logic as we
                /// won't be able to do that anymore
                ///
                self.foundReader = cardReaders.first

                guard let foundReaderID = self.foundReader?.id else {
                    DDLogWarn("onBeginSearch unexpectedly handled a nil found reader")
                    return
                }

                let knownReaderIDs = self.knownReaderIDs
                self.state = knownReaderIDs.contains(foundReaderID) ? .connectToReader : .foundReader
            },
            onError: { [weak self] error in
                guard let self = self else {
                    return
                }

                ServiceLocator.analytics.track(.cardReaderDiscoveryFailed, withError: error)
                self.state = .failed(error)
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

        alerts.scanningForReader(from: from, cancel: {
            self.state = .cancel
        })
    }

    /// A (unknown) reader has been found
    /// Opens a confirmation modal for the user to accept the found reader (or keep searching)
    ///
    func onFoundReader() {
        guard foundReader != nil else {
            return
        }

        guard let name = foundReader?.id else {
            return
        }

        guard let from = fromController else {
            return
        }

        alerts.foundReader(
            from: from,
            name: name,
            connect: {
                self.state = .connectToReader
            },
            continueSearch: {
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

    /// Connect to the card reader
    ///
    func onConnectToReader() {
        guard let reader = foundReader else {
            return
        }

        guard let from = fromController else {
            return
        }

        let action = CardPresentPaymentAction.connect(reader: reader) { [weak self] result in
            guard let self = self else {
                return
            }

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
                self.returnFailure(error: error)
            }
        }
        ServiceLocator.stores.dispatch(action)

        alerts.connectingToReader(from: from)
    }

    /// An error has occurred
    /// Presents the error in a modal
    ///
    private func onFailed(error: Error) {
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
