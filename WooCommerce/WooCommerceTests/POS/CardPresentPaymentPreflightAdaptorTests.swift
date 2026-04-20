import XCTest
import Yosemite
@testable import WooCommerce

final class CardPresentPaymentPreflightAdaptorTests: XCTestCase {
    @MainActor
    func test_attemptConnection_when_task_is_cancelled_then_throws_cancellation_error() async throws {
        let preflightController = MockCardPresentPaymentPreflightController()
        let adaptor = CardPresentPaymentPreflightAdaptor(preflightController: preflightController)

        let didStart = expectation(description: "start called")
        preflightController.onStart = {
            didStart.fulfill()
        }

        let didCancel = expectation(description: "task cancelled")

        let task = Task {
            do {
                _ = try await adaptor.attemptConnection(discoveryMethod: .bluetoothScan)
                XCTFail("Expected task cancellation")
            } catch is CancellationError {
                didCancel.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        await fulfillment(of: [didStart], timeout: 1.0)
        task.cancel()
        await fulfillment(of: [didCancel], timeout: 1.0)
        XCTAssertEqual(preflightController.startCallCount, 1)
        XCTAssertEqual(preflightController.cancelConnectionAttemptCallCount, 1)
    }
}
