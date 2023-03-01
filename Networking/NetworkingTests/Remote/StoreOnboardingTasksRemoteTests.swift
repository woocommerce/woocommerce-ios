import Foundation
import XCTest
import TestKit
@testable import Networking

final class StoreOnboardingTasksRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_it_returns_only_the_store_setup_tasks_from_response() async throws {
        // Given
        let remote = StoreOnboardingTasksRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "onboarding/tasks", filename: "store-onboarding-tasks")

        // When
        let tasks = try await remote.loadOnboardingTasks(siteID: 0)

        // Then
        XCTAssertEqual(tasks.count, 8)
    }
}
