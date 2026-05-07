import Foundation
import Testing
import Yosemite
@testable import WooAIAssistant

@MainActor
struct StoreActionDispatcherTests {
    @Test
    func test_dispatch_when_called_off_main_then_dispatches_action_on_main_thread() async {
        // Given
        let dispatcher = StoreActionDispatcher { action in
            #expect(Thread.isMainThread)
            guard let action = action as? TestAction else {
                Issue.record("expected TestAction")
                return
            }
            action.onCompletion(.success(42))
        }

        // When
        let result = await Task.detached {
            await dispatcher.dispatch { completion in
                TestAction(onCompletion: completion)
            }
        }.value

        // Then
        guard case .success(let value) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(value == 42)
    }
}

private struct TestAction: Action {
    let onCompletion: (Result<Int, TestError>) -> Void
}

private enum TestError: Error {
    case failed
}
