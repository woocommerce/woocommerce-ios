import Foundation

/// Defines the execution context for background work.
enum WorkExecutionContext {
    /// Work runs only when app is in background
    case backgroundOnly
    /// Work runs in both foreground and background
    case both
}

/// Protocol for background work that can be scheduled periodically in both foreground and background contexts.
///
/// Implementations should be `Sendable` to allow safe concurrent execution across actor boundaries.
///
protocol BackgroundWork: Sendable {
    /// Unique identifier for this work item.
    /// Must match the BGTaskScheduler identifier in Info.plist for background task scheduling.
    ///
    var identifier: String { get }

    /// How often this work should run (in seconds).
    /// This period is used by the scheduler to determine when to run the work next.
    ///
    var period: TimeInterval { get }

    /// Defines when this work should execute.
    /// - `.backgroundOnly`: Only runs when app is in background
    /// - `.both`: Runs in both foreground and background
    ///
    var executionContext: WorkExecutionContext { get }

    /// Execute the actual work.
    /// This method will be called from the scheduler and should perform the complete sync operation.
    ///
    /// - Throws: Any error that occurs during execution
    ///
    func execute() async throws

    /// Called when the work fails during a background execution context.
    /// Default implementation is a no-op.
    ///
    func didFail(with error: Error)

    /// Called when the system expires the background task before completion.
    /// Default implementation is a no-op.
    ///
    func didExpire()
}

extension BackgroundWork {
    func didFail(with error: Error) {}
    func didExpire() {}
}
