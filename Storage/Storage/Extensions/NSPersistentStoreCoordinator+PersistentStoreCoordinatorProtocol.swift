import CoreData

/// Make `NSPersistentStoreCoordinator` conform to `PersistentStoreCoordinatorProtocol` so
/// consumers of `CoreDataIterativeMigrator.init()` can pass in
/// `NSPersistentStoreCoordinator` instances.
extension NSPersistentStoreCoordinator: PersistentStoreCoordinatorProtocol {

}
