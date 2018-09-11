import Foundation


// MARK: - StorageManagerType Notifications
//
public extension NSNotification.Name {
    public static let StorageManagerDidResetStorage = NSNotification.Name(rawValue: "StorageManagerDidResetStorage")
}


/// Defines the methods and properties implemented by any concrete StorageManager implementation.
///
public protocol StorageManagerType {

    /// Returns the `Storage` associated to the main thread.
    ///
    var viewStorage: StorageType { get }

    /// Performs a task in Background: a special `Storage` instance will be provided (which is expected to be used within the closure!).
    /// Note that you must NEVER use the viewStorage within the backgroundClosure.
    ///
    func performBackgroundTask(_ closure: @escaping (StorageType) -> Void)

    /// This method is expected to destroy all persisted data. A notification of type `StorageManagerDidResetStorage` should get
    /// posted.
    ///
    func reset()
}
