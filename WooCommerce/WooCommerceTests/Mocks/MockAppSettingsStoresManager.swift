import Yosemite
@testable import WooCommerce

/// Allows mocking for `AppSettingsStoresActions` related to known card readers.
///
final class MockAppSettingsStoresManager: DefaultStoresManager {

    private var knownReaderIDs: [String]

    init(sessionManager: SessionManager, knownReaderIDs: [String] = []) {
        self.knownReaderIDs = knownReaderIDs
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
            knownReaderIDs = [cardReaderID]
            onCompletion(Result.success(()))
        case .forgetCardReader(let onCompletion):
            knownReaderIDs = []
            onCompletion(Result.success(()))
        case .loadCardReaders(let onCompletion):
            guard let knownReader = knownReaderIDs.last else {
                onCompletion(Result.success([]))
                return
            }
            onCompletion(Result.success([knownReader]))
        default:
            fatalError("Not available")
        }
    }
}
