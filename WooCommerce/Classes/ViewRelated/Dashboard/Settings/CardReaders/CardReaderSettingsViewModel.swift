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

    func startSearch() {
        activeAlert = .searching

        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: siteID, onCompletion: { [weak self] cardReaders in
            self?.discoveredReader(cardReaders: cardReaders)
        })

        ServiceLocator.stores.dispatch(action)
    }

    private func discoveredReader(cardReaders: [CardReader]) -> Void {
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

    func stopSearch() {
        // TODO dispatch an action to stop searching.
        activeAlert = .none
    }

    func connect() {
        // TODO dispatch an action to connect.
        activeAlert = .connecting
    }

    func stopConnect() {
        // TODO dispatch an action to interrupt connecting.
        activeAlert = .none
    }

    func disconnectAndForget() {
        // TODO dispatch an action to disconnect.
        connectedReader = nil
        activeView = .connectYourReader
        activeAlert = .none
    }

    func updateSoftware() {
        // TODO dispatch an action to update software on the connected reader
    }
}
