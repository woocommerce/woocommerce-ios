import XCTest
@testable import Networking

/// StoreOnboardingTaskListMapper Unit Tests
///
final class StoreOnboardingTaskListMapperTests: XCTestCase {
    func test_onboarding_tasks_response_is_properly_parsed() throws {
        guard let tasks = mapStoreOnboardingTasksResponse() else {
            XCTFail()
            return
        }

        let task = try XCTUnwrap(tasks[1])
        XCTAssertFalse(task.isComplete)
        XCTAssertEqual(task.type, .addFirstProduct)
    }

    func test_onboarding_tasks_response_without_data_envelope_is_properly_parsed() throws {
        guard let tasks = mapStoreOnboardingTasksResponseWithoutDataEnvelope() else {
            XCTFail()
            return
        }

        let storeDetails = tasks[0]
        XCTAssertTrue(storeDetails.isComplete)
        XCTAssertEqual(storeDetails.type, .storeDetails)

        let addProductTask = try XCTUnwrap(tasks[1])
        XCTAssertFalse(addProductTask.isComplete)
        XCTAssertEqual(addProductTask.type, .addFirstProduct)

        let taxTask = try XCTUnwrap(tasks[3])
        XCTAssertFalse(taxTask.isComplete)
        XCTAssertEqual(taxTask.type, .unsupported("tax"))
    }
}

// MARK: - Private Methods.
//
private extension StoreOnboardingTaskListMapperTests {
    func mapStoreOnboardingTasksResponse() -> [StoreOnboardingTask]? {
        guard let response = Loader.contentsOf("store-onboarding-tasks") else {
            return nil
        }

        return try? StoreOnboardingTaskListMapper().map(response: response)
    }

    func mapStoreOnboardingTasksResponseWithoutDataEnvelope() -> [StoreOnboardingTask]? {
        guard let response = Loader.contentsOf("store-onboarding-tasks-without-data") else {
            return nil
        }

        return try? StoreOnboardingTaskListMapper().map(response: response)
    }
}
