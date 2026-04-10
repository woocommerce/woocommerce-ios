import Foundation
import Yosemite


// MARK: - Represents a Site Action.
//
enum MockSiteAction: Action {
    case refreshSite(identifier: Int)
    case refreshSites
}


// MARK: - Account Site Store.
//
class MockSiteStore: Store {

    var receivedActions = [MockSiteAction]()

    override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: MockSiteAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? MockSiteAction else {
            return
        }

        receivedActions.append(accountAction)
    }
}
