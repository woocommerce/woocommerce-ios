import Foundation
import Yosemite


// MARK: - Mock Processor
//
class MockProcessor: ActionsProcessor {

    var receivedActions = [Action]()

    func onAction(_ action: Action) {
        receivedActions.append(action)
    }
}
