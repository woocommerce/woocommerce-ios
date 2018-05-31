import Foundation


/// Defines the methods and properties implemented by any concrete StorageManager implementation.
///
public protocol StorageManager {

    /// Returns the `Storage` associated to the main thread.
    ///
    var viewStorage: StorageType { get }

    /// Performs a task in Background: a special `Storage` instance will be provided (which is expected to be used within the closure!).
    /// Note that you must NEVER use the viewStorage within the backgroundClosure.
    ///
    func performBackgroundTask(_ closure: @escaping (StorageType) -> Void)
}
