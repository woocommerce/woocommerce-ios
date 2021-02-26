import Foundation
import Combine

struct CardReader {
    var name: String
}

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
    @Published var activeView: CardReaderSettingsViewActiveView
    @Published var activeAlert: CardReaderSettingsViewActiveAlert

    var knownReaders: [CardReader]
    var foundReader: CardReader?
    var connectedReader: CardReader?

    var timer: Timer? // TODO Remove

    init() {
        // TODO fetch initial state from Yosemite.CardReader.
        // The initial activeView and alert will be based on the knownReaders, connectedReaders and serviceState
        self.activeView = .connectYourReader
        self.activeAlert = .none
        self.knownReaders = []
        self.foundReader = nil
        self.connectedReader = nil
        self.timer = nil // TODO Remove
    }

    func startSearch() {
        // TODO dispatch an action to start searching.
        activeAlert = .searching

        // TODO Remove - simulates searching with a timer
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(dummyFoundReader), userInfo: nil, repeats: false)
    }

    // TODO Remove
    @objc private func dummyFoundReader() {
        self.foundReader = CardReader(name: "CHB204909001234")
        self.activeAlert = .foundReader
    }

    func stopSearch() {
        // TODO dispatch an action to stop searching.
        timer?.invalidate() // TODO Remove
        activeAlert = .none
    }

    func connect() {
        // TODO dispatch an action to connect.
        activeAlert = .connecting

        // TODO Remove - simulates connecting with a timer
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(dummyConnectedReader), userInfo: nil, repeats: false)
    }

    func stopConnect() {
        // TODO dispatch an action to interrupt connecting.
        activeAlert = .none
    }

    // TODO Remove
    @objc private func dummyConnectedReader() {
        self.connectedReader = self.foundReader
        self.activeView = .connectedToReader
        self.activeAlert = .none
    }

    func updateSoftware() {
        // TODO dispatch an action to update software on the connected reader
    }
}
