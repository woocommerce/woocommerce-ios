import Foundation
import Combine
import OSLog

struct CardReader {
    var name: String
}

enum CardReaderSettingsActiveChildView {
    case none
    case connect
    case cannotConnect
}

class CardReaderSettingsViewModel: ObservableObject {
    @Published var activeChildView: CardReaderSettingsActiveChildView
    @Published var connectedReaders: [CardReader]
    @Published var knownReaders: [CardReader]

    init() {
        os_log("In CRSVM init")
        self.activeChildView = .none
        self.connectedReaders = []
        self.knownReaders = []
    }

    deinit {
        os_log("In CRSVM deinit")
    }

}
