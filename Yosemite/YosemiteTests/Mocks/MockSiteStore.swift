import Foundation
import Yosemite


// MARK: - Represents a Site Action.
//
enum SiteAction: Action {
    case refreshSite(identifier: Int)
    case refreshSites
}


// MARK: - Account Site Store.
//
class MockSiteStore: Store {

    var receivedActions = [SiteAction]()

    override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SiteAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? SiteAction else {
            return
        }

        receivedActions.append(accountAction)
    }
}
