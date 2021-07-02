import Yosemite
@testable import WooCommerce

/// Allows mocking for `AppSettingsStoresActions` related to known card readers.
///
final class MockAppSettingsStoresManager: DefaultStoresManager {

    private var knownReaders: [String]

    init(sessionManager: SessionManager, knownReaders: [String] = []) {
        self.knownReaders = knownReaders
        super.init(sessionManager: sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? AppSettingsAction {
            onAppSettingsAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onAppSettingsAction(action: AppSettingsAction) {
        switch action {
        case .rememberCardReader(let cardReaderID, let onCompletion):
            knownReaders.append(cardReaderID)
            onCompletion(Result.success(()))
        case .forgetCardReader(let cardReaderID, let onCompletion):
            knownReaders = knownReaders.filter { $0 != cardReaderID }
            onCompletion(Result.success(()))
        case .loadCardReaders(let onCompletion):
            onCompletion(Result.success(knownReaders))
        default:
            fatalError("Not available")
        }
    }
}
