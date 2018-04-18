import Foundation
@testable import FluxC


// MARK: - Mockup Dispatcher
//
class MockupDispatcher: Dispatcher {

    var numberOfProcessors: Int {
        return processors.count
    }
}
