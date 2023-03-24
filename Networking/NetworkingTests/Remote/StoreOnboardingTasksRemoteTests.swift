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

        var index = 0
        let task1 = tasks[index]
        XCTAssertTrue(task1.isComplete)
        XCTAssertEqual(task1.type, .storeDetails)

        index += 1
        let task2 = tasks[index]
        XCTAssertFalse(task2.isComplete)
        XCTAssertEqual(task2.type, .addFirstProduct)

        index += 1
        let task3 = tasks[index]
        XCTAssertFalse(task3.isComplete)
        XCTAssertEqual(task3.type, .payments)

        index += 1
        let task4 = tasks[index]
        XCTAssertFalse(task4.isComplete)
        XCTAssertEqual(task4.type, .unsupported("tax"))

        index += 1
        let task5 = tasks[index]
        XCTAssertFalse(task5.isComplete)
        XCTAssertEqual(task5.type, .unsupported("marketing"))

        index += 1
        let task6 = tasks[index]
        XCTAssertFalse(task6.isComplete)
        XCTAssertEqual(task6.type, .unsupported("appearance"))

        index += 1
        let task7 = tasks[index]
        XCTAssertTrue(task7.isComplete)
        XCTAssertEqual(task7.type, .customizeDomains)

        index += 1
        let task8 = tasks[index]
        XCTAssertFalse(task8.isComplete)
        XCTAssertEqual(task8.type, .launchStore)
    }
}
