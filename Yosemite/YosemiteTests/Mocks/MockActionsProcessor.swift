import Foundation
import Yosemite


// MARK: - Mock ActionsProcessor
//
class MockActionsProcessor: ActionsProcessor {

    var receivedActions = [Action]()

    func onAction(_ action: Action) {
        receivedActions.append(action)
    }
}
