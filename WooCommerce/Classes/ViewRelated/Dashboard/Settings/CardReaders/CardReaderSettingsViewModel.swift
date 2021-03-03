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

final class CardReaderSettingsViewModel: ObservableObject {
    /// Followed by CardReaderSettingsViewController to select child views and show/hide alerts.
    @Published var activeView: CardReaderSettingsViewActiveView
    @Published var activeAlert: CardReaderSettingsViewActiveAlert
    @Published var connectedReader: CardReader?

    var knownReaders: [CardReader]
    var foundReader: CardReader?

    init() {
        // TODO fetch initial state from Yosemite.CardReader.
        // The initial activeView and alert will be based on the knownReaders, connectedReaders and serviceState
        activeView = .connectYourReader
        activeAlert = .none
        knownReaders = []
        foundReader = nil
        connectedReader = nil
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
        if activeAlert == .foundReader {
            return
        }

        if cardReaders.isEmpty {
            return
        }

        // TODO - show the multiple-readers-found UITableView when more than one reader is found
        // For now, just show the tail of the array
        foundReader = cardReaders.last
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
