import Networking
import XCTest

/// Mock for `StoreOnboardingTasksRemote`.
///
final class MockStoreOnboardingTasksRemote {
    /// The results to return in `loadOnboardingTasks`.
    private var loadOnboardingTasks: Result<[StoreOnboardingTask], Error>?

    /// Returns the value when `loadOnboardingTasks` is called.
    func whenLoadingOnboardingTasks(thenReturn result: Result<[StoreOnboardingTask], Error>) {
        loadOnboardingTasks = result
    }
}

extension MockStoreOnboardingTasksRemote: StoreOnboardingTasksRemoteProtocol {
    func loadOnboardingTasks(siteID: Int64) async throws -> [StoreOnboardingTask] {
        guard let result = loadOnboardingTasks else {
            XCTFail("Could not find result for loading onboarding tasks.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
