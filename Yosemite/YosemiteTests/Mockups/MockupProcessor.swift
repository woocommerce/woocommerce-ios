import Foundation
import Yosemite


// MARK: - Mockup Processor
//
class MockupProcessor: ActionsProcessor {

    var receivedActions = [Action]()

    func onAction(_ action: Action) {
        receivedActions.append(action)
    }
}
