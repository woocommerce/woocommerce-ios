import CoreData

protocol PersistentStoreCoordinatorProtocol {

    func replacePersistentStore(at destinationURL: URL,
                                destinationOptions: [AnyHashable: Any]?,
                                withPersistentStoreFrom sourceURL: URL,
                                sourceOptions: [AnyHashable: Any]?,
                                ofType storeType: String) throws

    func destroyPersistentStore(at url: URL,
                                ofType storeType: String,
                                options: [AnyHashable: Any]?) throws
}
