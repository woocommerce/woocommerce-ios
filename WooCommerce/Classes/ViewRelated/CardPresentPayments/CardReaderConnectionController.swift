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

        /// Ending search for card readers
        ///
        case endSearch

        /// Found a card reader
        ///
        case foundReader

        /// Attempting to connect to a card reader
        ///
        case connectToReader

        /// Connected successfully to a card reader
        ///
        case connectedToReader

        /// A failure occurred during search or connection
        ///
        case failed(Error)
    }

    private var state: ControllerState {
        didSet {
            didSetState()
        }
    }
    private var fromController: UIViewController
    private var siteID: Int64
    private var knownCardReadersProvider: CardReaderSettingsKnownReadersProvider

    private var foundReader: CardReader?
    private var knownReaderIDs: [String]
    private var subscriptions = Set<AnyCancellable>()

    private lazy var alerts: CardReaderSettingsAlerts = {
        CardReaderSettingsAlerts()
    }()

    init(
        from: UIViewController,
        forSiteID: Int64,
        knownReadersProvider: CardReaderSettingsKnownReadersProvider
    ) {
        state = .idle
        fromController = from
        siteID = forSiteID
        knownCardReadersProvider = knownReadersProvider
        knownReaderIDs = []
    }

    deinit {
        subscriptions.removeAll()
    }

    func start() {
        self.state = .initializing

        /// Subscribe to the list of known readers
        ///
        knownCardReadersProvider.knownReaders.sink(receiveValue: { [weak self] readerIDs in
            self?.knownReaderIDs = readerIDs
            /// We are now ready to actually begin the search
            self?.state = .beginSearch
        }).store(in: &subscriptions)

    }
}

private extension CardReaderConnectionController {
    func didSetState() {
        switch state {
        case .beginSearch:
            onBeginSearch()
        case .searching:
            onSearching()
        case .endSearch:
            onEndSearch()
        case .foundReader:
            onFoundReader()
        case .connectToReader:
            onConnectToReader()
        case .failed(let error):
            onFailed(error: error)
        default:
            dismissAnyModal()
        }
    }

    /// Begin the search for a card reader
    ///
    func onBeginSearch() {
        self.state = .searching
        let action = CardPresentPaymentAction.startCardReaderDiscovery(
            siteID: siteID,
            onReaderDiscovered: { [weak self] cardReaders in
                /// Surprisingly, onReaderDiscovered may be called with an empty array
                ///
                guard cardReaders.count > 0 else {
                    return
                }

                /// For now, we only work with the first card reader returned
                /// When we stop using proximity, we'll need more elaborate logic as we
                /// won't be able to do that anymore
                ///
                self?.foundReader = cardReaders.first

                guard let foundReaderID = self?.foundReader?.id else {
                    DDLogWarn("onBeginSearch unexpectedly handled a nil found reader")
                    self?.state = .endSearch
                    return
                }

                /// If we know this reader, automatically connect to it
                ///
                let knownReaderIDs = self?.knownReaderIDs ?? []
                if knownReaderIDs.contains(foundReaderID) {
                    self?.state = .connectToReader
                } else {
                    self?.state = .foundReader
                }
            },
            onError: { [weak self] error in
                ServiceLocator.analytics.track(.cardReaderDiscoveryFailed, withError: error)
                self?.state = .failed(error)
            })

        ServiceLocator.stores.dispatch(action)
    }

    /// A search is in progress
    ///
    func onSearching() {
        alerts.scanningForReader(from: fromController, cancel: {
            self.state = .endSearch
        })
    }

    /// End the search for a card reader
    ///
    func onEndSearch() {
        let action = CardPresentPaymentAction.cancelCardReaderDiscovery() {_ in
            self.state = .idle
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// A reader has been found
    ///
    func onFoundReader() {
        guard foundReader != nil else {
            DDLogWarn("onFoundReader unexpectedly called with no found reader")
            self.state = .endSearch
            return
        }

        guard let name = foundReader?.id else {
            DDLogWarn("Found reader unexpectedly had no id (name)")
            self.state = .endSearch
            return
        }

        alerts.foundReader(
            from: fromController,
            name: name,
            connect: {
                self.state = .connectToReader
            },
            continueSearch: {
                self.state = .searching
            })
    }

    /// Connect to a card reader
    ///
    func onConnectToReader() {
        guard let reader = foundReader else {
            DDLogWarn("No found reader to connect to")
            self.state = .endSearch
            return
        }

        let action = CardPresentPaymentAction.connect(reader: reader) { [weak self] result in
            switch result {
            case .success(let reader):
                self?.knownCardReadersProvider.rememberCardReader(cardReaderID: reader.id)
                // If the reader does not have a battery, or the battery level is unknown, it will be nil
                let properties = reader.batteryLevel
                    .map { ["battery_level": $0] }
                ServiceLocator.analytics.track(.cardReaderConnectionSuccess, withProperties: properties)
                self?.state = .connectedToReader
            case .failure(let error):
                ServiceLocator.analytics.track(.cardReaderConnectionFailed, withError: error)
                self?.state = .failed(error)
            }
        }
        ServiceLocator.stores.dispatch(action)
        alerts.connectingToReader(from: fromController)
    }

    /// An error has occurred
    ///
    private func onFailed(error: Error) {
        alerts.scanningFailed(from: fromController, error: error) { [weak self] in
            self?.state = .idle
        }
    }

    private func dismissAnyModal() {
        alerts.dismiss()
    }
}
