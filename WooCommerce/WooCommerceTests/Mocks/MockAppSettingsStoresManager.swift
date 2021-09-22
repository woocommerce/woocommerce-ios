import Yosemite
@testable import WooCommerce

/// Allows mocking for `AppSettingsStoresActions` related to known card readers.
///
final class MockAppSettingsStoresManager: DefaultStoresManager {

    private var knownReaderID: String?

    init(sessionManager: SessionManager, knownReaderID: String? = nil) {
        self.knownReaderID = knownReaderID
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
            knownReaderID = cardReaderID
            onCompletion(Result.success(()))
        case .forgetCardReader(let onCompletion):
            knownReaderID = nil
            onCompletion(Result.success(()))
        case .loadCardReader(let onCompletion):
            onCompletion(Result.success(knownReaderID))
        default:
            fatalError("Not available")
        }
    }
}
