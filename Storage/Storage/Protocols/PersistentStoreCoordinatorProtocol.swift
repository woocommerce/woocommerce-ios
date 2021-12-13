import CoreData

/// Defines methods provided by `NSPersistentStoreCoordinator` that are used by
/// `CoreDataIterativeMigrator` for migrating stores.
///
/// This is generally used to allow injection of test doubles.
protocol PersistentStoreCoordinatorProtocol {

    /// Replace the destination persistent store with the source store.
    func replacePersistentStore(at destinationURL: URL,
                                destinationOptions: [AnyHashable: Any]?,
                                withPersistentStoreFrom sourceURL: URL,
                                sourceOptions: [AnyHashable: Any]?,
                                ofType storeType: String) throws

    /// Deletes (or truncates) the target persistent store in accordance with the store class' requirements.
    func destroyPersistentStore(at url: URL,
                                ofType storeType: String,
                                options: [AnyHashable: Any]?) throws
}
