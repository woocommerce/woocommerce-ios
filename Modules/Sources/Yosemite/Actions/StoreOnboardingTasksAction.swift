import Foundation

/// Defines the `actions` supported by the `StoreOnboardingTasksStore`.
///
public enum StoreOnboardingTasksAction: Action {
    case loadOnboardingTasks(siteID: Int64, completion: (Result<[StoreOnboardingTask], Error>) -> Void)
}
