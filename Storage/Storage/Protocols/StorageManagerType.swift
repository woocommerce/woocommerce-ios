import Foundation


// MARK: - StorageManagerType Notifications
//
public extension NSNotification.Name {
    static let StorageManagerDidResetStorage = NSNotification.Name(rawValue: "StorageManagerDidResetStorage")
}


/// Defines the methods and properties implemented by any concrete StorageManager implementation.
///
public protocol StorageManagerType {

    /// Returns the `Storage` associated to the main thread.
    ///
    var viewStorage: StorageType { get }

    /// Returns a shared derived storage instance dedicated for write operations.
    ///
    @available(*, deprecated, message: "Use `performAndSave` to handle write operations instead.")
    var writerDerivedStorage: StorageType { get }

    /// Performs a task in Background: a special `Storage` instance will be provided (which is expected to be used within the closure!).
    /// Note that you must NEVER use the viewStorage within the backgroundClosure.
    ///

    /// Save a derived context created with `writerDerivedStorage` via this convenience method
    ///
    /// - Parameters:
    ///   - derivedStorageType: a derived StorageType constructed with `newDerivedStorage`
    ///   - closure: Callback to be executed on completion
    ///
    @available(*, deprecated, message: "Use `performAndSave` to handle write operations instead.")
    func saveDerivedType(derivedStorage: StorageType, _ closure: @escaping () -> Void)

    /// Execute the given block with a background context and save the changes.
    ///
    /// This function _does not block_ its running thread. The block is executed in background and its return value
    /// is passed onto the `completion` block which is executed on the given `queue`.
    ///
    /// - Parameters:
    ///   - closure: A closure which uses the given `NSManagedObjectContext` to make Core Data model changes.
    ///   - completion: A closure which is called with the return value of the `block`, after the changed made
    ///         by the `block` is saved.
    ///   - queue: A queue on which to execute the completion block.
    func performAndSave(_ closure: @escaping (StorageType) -> Void, completion: (() -> Void)?, on queue: DispatchQueue)

    /// This method is expected to destroy all persisted data. A notification of type `StorageManagerDidResetStorage` should get
    /// posted.
    ///
    func reset()
}
