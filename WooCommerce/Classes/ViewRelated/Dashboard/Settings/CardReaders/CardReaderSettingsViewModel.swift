import Foundation
import Combine
import Yosemite

enum CardReaderSettingsViewActiveView {
    case connectYourReader
    case connectedToReader
    case noReaders
}

enum CardReaderSettingsViewActiveAlert {
    case none
    case searching
    case foundReader
    case connecting
    case tutorial
    case updateAvailable
    case updateRequired
    case updating
}

struct CardReaderViewModel {
    var displayName: String
    var batteryStatus: String

    init(_ reader: CardReader? = nil) {
        let unknownName = NSLocalizedString(
            "Unknown Name",
            comment: "Displayed in the unlikely event a card reader has an empty serial number"
        )
        let unknownBatteryStatus = NSLocalizedString(
            "Unknown Battery Level",
            comment: "Displayed in the unlikely event a card reader has an indeterminate battery status"
        )

        guard reader != nil else {
            self.displayName = unknownName
            self.batteryStatus = unknownBatteryStatus
            return
        }

        self.displayName = reader?.serial ?? unknownName

        guard let batteryLevel = reader?.batteryLevel else {
            self.batteryStatus = unknownBatteryStatus
            return
        }

        let batteryLevelPercent = Int(100 * batteryLevel)
        let batteryLevelString = NumberFormatter.localizedString(from: batteryLevelPercent as NSNumber, number: .decimal)
        let batteryLabelFormat = NSLocalizedString(
            "%1$@%% Battery",
            comment: "Card reader battery level as an integer percentage"
        )

        self.batteryStatus = String.localizedStringWithFormat(batteryLabelFormat, batteryLevelString)
    }
}

final class CardReaderSettingsViewModel: ObservableObject {
    /// Followed by CardReaderSettingsViewController to select child views and show/hide alerts.
    @Published var activeView: CardReaderSettingsViewActiveView
    @Published var activeAlert: CardReaderSettingsViewActiveAlert
    @Published var connectedReaderViewModel: CardReaderViewModel
    @Published var foundReadersViewModels: [CardReaderViewModel]

    private var connectedReader: CardReader? {
        didSet {
            updateConnectedReaderViewModel()
        }
    }
    private var foundReaders: [CardReader] {
        didSet {
            updateFoundReadersViewModels()
        }
    }

    init() {
        // TODO fetch initial state from Yosemite.CardReader.
        // The initial activeView and alert will be based on the knownReaders, connectedReaders and serviceState
        activeView = .connectYourReader
        activeAlert = .none
        connectedReaderViewModel = CardReaderViewModel()
        foundReadersViewModels = []
        connectedReader = nil
        foundReaders = []
    }

    private func updateConnectedReaderViewModel() {
        connectedReaderViewModel = CardReaderViewModel(connectedReader)
    }

    private func updateFoundReadersViewModels() {
        foundReadersViewModels = foundReaders.map { CardReaderViewModel($0) }
    }

    /// Views can call this method to start searching for readers.
    func startSearch() {
        activeAlert = .searching


        /// This sequence is here just to test that discovery can be cancelled
        /// Dispatching these two actions will be remoed soon
        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: siteID, onCompletion: { [weak self] cardReaders in
            self?.didDiscoverReaders(cardReaders: cardReaders)
        })

        ServiceLocator.stores.dispatch(action)
    }

    /// Called when a reader has been discovered (with an array of discovered readers).
    private func didDiscoverReaders(cardReaders: [CardReader]) -> Void {
        // TODO - more than one reader? sort in the manner in which we'd like the rows presented
        guard activeAlert != .foundReader else {
            return
        }

        guard cardReaders.count > 0 else {
            return
        }

        // TODO - show the multiple-readers-found UITableView when more than one reader is found
        // For now, just show the tail (last) of the array
        guard let cardReader = cardReaders.last else {
            return
        }
        foundReaders = [cardReader]
        activeAlert = .foundReader
    }

    /// Views can call this method to stop searching for readers.
    func stopSearch() -> Void {
        // TODO dispatch an action to stop searching.
        activeAlert = .none
    }

    /// Views can call this method to connect to a found reader.
    func connect() {
        activeAlert = .connecting

        let action = CardPresentPaymentAction.connect(reader: foundReaders[0], onCompletion: { [weak self] result in
            switch result {
            case .success(let cardReaders):
                self?.didConnectToReader(cardReaders: cardReaders)
            case .failure(let error):
                DDLogWarn(error.localizedDescription)
                // TODO failure message to the user?
                self?.activeAlert = .none
            }
        })

        ServiceLocator.stores.dispatch(action)
    }

    /// Views can call this method to abort connecting to a reader.
    func stopConnect() {
        // TODO dispatch an action to interrupt connecting.
        activeAlert = .none
    }

    /// Views can call this method to disconnect from the connected reader.
    func disconnectAndForget() {
        // TODO dispatch an action to disconnect.
        connectedReader = nil
        activeView = .connectYourReader
        activeAlert = .none
    }

    /// Called when a reader has been connected to.
    private func didConnectToReader(cardReaders: [CardReader]) -> Void {
        activeAlert = .none
        guard cardReaders.count > 0 else {
            // TODO log unexpected failure
            return
        }

        activeView = .connectedToReader
        self.connectedReader = cardReaders[0]
    }

    /// Views can call this method to initiate a software update on the connected reader.
    func updateSoftware() {
        // TODO dispatch an action to update software on the connected reader
    }
}
