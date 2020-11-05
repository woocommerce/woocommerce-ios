import CoreData

protocol PersistentStoreCoordinatorProtocol {

    func migratePersistentStore(_ store: NSPersistentStore,
                                to URL: URL,
                                options: [AnyHashable: Any]?,
                                withType storeType: String) throws -> NSPersistentStore

    func replacePersistentStore(at destinationURL: URL,
                                destinationOptions: [AnyHashable: Any]?,
                                withPersistentStoreFrom sourceURL: URL,
                                sourceOptions: [AnyHashable: Any]?,
                                ofType storeType: String) throws

    func destroyPersistentStore(at url: URL,
                                ofType storeType: String,
                                options: [AnyHashable: Any]?) throws
}
