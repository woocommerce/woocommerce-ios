import Foundation
import BackgroundTasks

/// Protocol abstracting BGTask for testability
protocol BackgroundTaskProtocol: AnyObject {
    var identifier: String { get }
    var expirationHandler: (() -> Void)? { get set }
    func setTaskCompleted(success: Bool)
}

extension BGTask: BackgroundTaskProtocol {}

/// Protocol abstracting BGTaskScheduler for testability
protocol BackgroundTaskScheduling {
    func register(forTaskWithIdentifier identifier: String, using queue: DispatchQueue?, launchHandler: @escaping (BackgroundTaskProtocol) -> Void)
    func submit(_ taskRequest: BGTaskRequest) throws
    func cancelAllTaskRequests()
}

/// Production implementation wrapping BGTaskScheduler
final class SystemBackgroundTaskScheduler: BackgroundTaskScheduling {
    func register(forTaskWithIdentifier identifier: String, using queue: DispatchQueue?, launchHandler: @escaping (BackgroundTaskProtocol) -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            launchHandler(task)
        }
    }

    func submit(_ taskRequest: BGTaskRequest) throws {
        try BGTaskScheduler.shared.submit(taskRequest)
    }

    func cancelAllTaskRequests() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}
