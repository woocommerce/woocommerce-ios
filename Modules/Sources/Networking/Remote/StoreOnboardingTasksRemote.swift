import Foundation

public protocol StoreOnboardingTasksRemoteProtocol {
    func loadOnboardingTasks(siteID: Int64) async throws -> [StoreOnboardingTask]
}

public class StoreOnboardingTasksRemote: Remote, StoreOnboardingTasksRemoteProtocol {
    /// Loads store onboarding tasks
    /// - Parameter siteID: Site ID
    /// - Returns: An array of store onboarding tasks
    public func loadOnboardingTasks(siteID: Int64) async throws -> [StoreOnboardingTask] {
        let path = Constants.tasksPath
        let request = JetpackRequest(wooApiVersion: .wcAdmin,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: StoreOnboardingTaskListMapper())
    }
}

// MARK: - Constants!
//
private extension StoreOnboardingTasksRemote {
    enum Constants {
        static let tasksPath = "onboarding/tasks"
    }
}
