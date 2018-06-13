import Foundation
import Yosemite


// MARK: - Represents an Account Action.
//
enum AccountAction: Action {
    case authenticate
    case deauthenticate
}


// MARK: - Account Mockup Store.
//
class MockupAccountStore: Store {

    var receivedActions = [AccountAction]()

    override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AccountAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? AccountAction else {
            fatalError()
        }

        receivedActions.append(accountAction)
    }
}
