import Foundation
import Yosemite


// MARK: - Represents an Account Action.
//
enum MockAccountAction: Action {
    case authenticate
    case deauthenticate
}


// MARK: - Account Mock Store.
//
class MockAccountStore: Store {

    var receivedActions = [MockAccountAction]()

    override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: MockAccountAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? MockAccountAction else {
            fatalError()
        }

        receivedActions.append(accountAction)
    }
}
