import Foundation


// MARK: - StorageManagerType Notifications
//
public extension NSNotification.Name {
    static let StorageManagerDidResetStorage = NSNotification.Name(rawValue: "StorageManagerDidResetStorage")
    static let StorageManagerDidDropDatabase = NSNotification.Name(rawValue: "StorageManagerDidDropDatabase")
}


/// Defines the methods and properties implemented by any concrete StorageManager implementation.
///
public protocol StorageManagerType: AnyObject {

    /// Returns the `Storage` associated to the main thread.
    ///
    var viewStorage: StorageType { get }

    /// Execute the given operation with a background context and save the changes.
    ///
    /// This function _does not block_ its running thread. The operation is executed in background and its return value
    /// is passed onto the `completion` closure which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - operation: A closure which uses the given `StorageType` to make data changes in background.
    ///   - completion: A closure which is called after the changed made by the `operation` is saved.
    ///   - queue: A queue on which to execute the completion closure.
    func performAndSave(_ operation: @escaping (StorageType) -> Void,
                        completion: (() -> Void)?,
                        on queue: DispatchQueue)

    /// Execute the given `operation` with a background context, save the changes, and return the result.
    ///
    /// This function _does not block_ its running thread. The operation is executed in background and its return value
    /// is passed onto the `completion` closure which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - operation: A closure which uses the given `StorageType` to make data changes in background.
    ///   - completion: A closure which is called with the `operation`'s execution result,
    ///   which is either an error thrown by the `operation` or the return value of the `operation`.
    ///   - queue: A queue on which to execute the completion closure.
    func performAndSave<T>(_ operation: @escaping (StorageType) throws -> T,
                           completion: @escaping (Result<T, Error>) -> Void,
                           on queue: DispatchQueue)

    /// This method is expected to destroy all persisted data. A notification of type `StorageManagerDidResetStorage` should get
    /// posted.
    ///
    /// - Parameter onCompletion: A callback closure triggered when the resetting is done.
    ///
    func reset(onCompletion: (() -> Void)?)
}

public extension StorageManagerType {
    /// Simplified method to reset the storage.
    func reset() {
        reset(onCompletion: nil)
    }

    /// Async/await version of `performAndSave`.
    ///
    /// - Parameters:
    ///   - operation: A closure which uses the given `StorageType` to make data changes in background.
    ///   - queue: A queue on which to execute the completion closure.
    func performAndSaveAsync(_ operation: @escaping (StorageType) -> Void, on queue: DispatchQueue = .main) async {
        await withCheckedContinuation { continuation in
            performAndSave(operation, completion: {
                continuation.resume()
            }, on: queue)
        }
    }
}
