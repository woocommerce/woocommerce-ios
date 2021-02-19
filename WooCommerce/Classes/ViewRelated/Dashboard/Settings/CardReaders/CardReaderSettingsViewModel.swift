import Foundation
import Combine

struct CardReader {
    var name: String
}

enum CardReaderSettingsViewSummaryState {
    case cleanSlate
    case connected
    case notConnected
}

enum CardReaderSettingsViewInteractiveState {
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
    @Published var summaryState: CardReaderSettingsViewSummaryState
    @Published var interactiveState: CardReaderSettingsViewInteractiveState
    @Published var knownReaders: [CardReader]
    @Published var foundReader: CardReader?
    @Published var connectedReader: CardReader?

    init() {
        // TODO fetch initial state from Yosemite.CardReader
        self.summaryState = .cleanSlate
        self.interactiveState = .searching
        self.knownReaders = []
        self.foundReader = nil
        self.connectedReader = nil
    }

    func startSearch() {
        // TODO dispatch an action to start searching
        if knownReaders.count == 0 {
            summaryState = .cleanSlate
        } else {
            summaryState = .notConnected
        }
        interactiveState = .searching
    }

    func stopSearch() {
        // TODO dispatch an action to stop searching
        if knownReaders.count == 0 {
            summaryState = .cleanSlate
        } else {
            summaryState = .notConnected
        }
        interactiveState = .none
    }

    func connect() {
        // TODO dispatch an action to connect.
    }

    func updateSoftware() {
        // TODO dispatch an action to update software on the connected reader
    }
}
