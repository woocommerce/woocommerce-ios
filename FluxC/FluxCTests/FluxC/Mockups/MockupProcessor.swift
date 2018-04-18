import Foundation
import FluxC


// MARK: - Mockup Processor
//
class MockupProcessor: ActionsProcessor {

    var receivedActions = [Action]()

    func onAction(_ action: Action) {
        receivedActions.append(action)
    }
}
