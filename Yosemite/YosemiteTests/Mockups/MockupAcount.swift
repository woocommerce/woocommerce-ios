import Foundation
import Yosemite


// MARK: - Represents an Account Action.
//
enum MockupAccountAction: Action {
    case authenticate
    case deauthenticate
}


// MARK: - Account Mockup Store.
//
class MockupAccountStore: Store {

    var receivedActions = [MockupAccountAction]()

    override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: MockupAccountAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? MockupAccountAction else {
            fatalError()
        }

        receivedActions.append(accountAction)
    }
}
