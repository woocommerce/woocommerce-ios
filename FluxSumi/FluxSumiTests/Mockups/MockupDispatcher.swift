import Foundation
@testable import FluxSumi


// MARK: - Mockup Dispatcher
//
class MockupDispatcher: Dispatcher {

    func numberOfProcessors(for actionType: Action.Type) -> Int {
        return processors[actionType.identifier]?.count ?? 0
    }
}
