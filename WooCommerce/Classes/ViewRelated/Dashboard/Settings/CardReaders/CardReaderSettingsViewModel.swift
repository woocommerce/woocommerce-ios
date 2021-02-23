import Foundation
import Combine

struct CardReader {
    var name: String
}

enum CardReaderSettingsViewActiveView {
    case connectYourReader
    case manageYourReader
    case noReaderFound
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
    @Published var activeView: CardReaderSettingsViewActiveView
    @Published var activeAlert: CardReaderSettingsViewActiveAlert

    var knownReaders: [CardReader]
    var foundReader: CardReader?
    var connectedReader: CardReader?

    init() {
        // TODO fetch initial state from Yosemite.CardReader.
        // The initial activeView and alert will be based on the knownReaders, connectedReaders and serviceState
        self.activeView = .connectYourReader
        self.activeAlert = .none
        self.knownReaders = []
        self.foundReader = nil
        self.connectedReader = nil
    }

    func startSearch() {
        // TODO dispatch an action to start searching.
        activeAlert = .searching
    }

    func stopSearch() {
        // TODO dispatch an action to stop searching.
        activeAlert = .none
    }

    func connect() {
        // TODO dispatch an action to connect.
    }

    func updateSoftware() {
        // TODO dispatch an action to update software on the connected reader
    }
}
