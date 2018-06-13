import Foundation
import FluxSumi


// MARK: - Represents a Site Action.
//
enum SiteAction: Action {
    case refreshSite(identifier: Int)
    case refreshSites
}


// MARK: - Account Site Store.
//
class MockupSiteStore: Store {

    var receivedActions = [SiteAction]()

    override func registerSupportedActions() {
        dispatcher.register(processor: self, actionType: SiteAction.self)
    }

    override func onAction(_ action: Action) {
        guard let accountAction = action as? SiteAction else {
            return
        }

        receivedActions.append(accountAction)
    }
}
