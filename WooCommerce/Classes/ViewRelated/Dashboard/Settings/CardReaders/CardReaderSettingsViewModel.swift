import Foundation
import Combine
import Yosemite

struct CardReader {
    var serialNumber: String
    var batteryLevel: Float
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
    /// Followed by CardReaderSettingsViewController to select child views and show/hide alerts.
    @Published var activeView: CardReaderSettingsViewActiveView
    @Published var activeAlert: CardReaderSettingsViewActiveAlert
    @Published var connectedReader: CardReader?

    var knownReaders: [CardReader]
    var foundReader: CardReader?

    var timer: Timer? // TODO Remove
    var batteryTimer: Timer? // TODO Remove

    init() {
        // TODO fetch initial state from Yosemite.CardReader.
        // The initial activeView and alert will be based on the knownReaders, connectedReaders and serviceState
        activeView = .connectYourReader
        activeAlert = .none
        knownReaders = []
        foundReader = nil
        connectedReader = nil
        timer = nil // TODO Remove

        // TODO Remove - simulates a declining battery level with a timer
        batteryTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(dummyUpdateBattery), userInfo: nil, repeats: true)
    }

    deinit {
        batteryTimer?.invalidate()
    }

    func startSearch() {
        activeAlert = .searching

        let siteID = ServiceLocator.stores.sessionManager.defaultStoreID ?? Int64.min

        let action = CardPresentPaymentAction.startCardReaderDiscovery(siteID: siteID, onCompletion: { cardReaders in
            // TODO. To be implemented
            // Leaving these prints here to help test the PR
            print("==== new card readers discovered begins ====")
            print("new readers: ", cardReaders)
            print("==== new card readers discovered ends   ====")
        })

        ServiceLocator.stores.dispatch(action)

        // TODO Remove - simulates searching with a timer
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(dummyFoundReader), userInfo: nil, repeats: false)
    }

    // TODO Remove
    @objc private func dummyFoundReader() {
        foundReader = CardReader(serialNumber: "CHB204909001234", batteryLevel: 0.885)
        activeAlert = .foundReader
    }

    // TODO Remove
    @objc private func dummyUpdateBattery() {
        guard var batteryLevel = connectedReader?.batteryLevel else {
            return
        }

        batteryLevel = batteryLevel * 0.99
        connectedReader?.batteryLevel = batteryLevel
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

    func disconnectAndForget() {
        // TODO dispatch an action to disconnect.
        connectedReader = nil
        activeView = .connectYourReader
        activeAlert = .none
    }

    // TODO Remove
    @objc private func dummyConnectedReader() {
        connectedReader = foundReader
        foundReader = nil
        activeView = .connectedToReader
        activeAlert = .none
    }

    func updateSoftware() {
        // TODO dispatch an action to update software on the connected reader
    }
}
