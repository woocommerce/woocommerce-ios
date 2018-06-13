import Foundation
@testable import Yosemite


// MARK: - Mockup Dispatcher
//
class MockupDispatcher: Dispatcher {

    func numberOfProcessors(for actionType: Action.Type) -> Int {
        return processors[actionType.identifier]?.count ?? 0
    }
}
