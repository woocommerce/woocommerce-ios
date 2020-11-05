import CoreData

@testable import Storage

final class SpyPersistentStoreCoordinator: PersistentStoreCoordinatorProtocol {

    struct StoreReplacement {
        let destinationURL: URL
        let sourceURL: URL
    }

    private let spiedCoordinator: NSPersistentStoreCoordinator

    private(set) var storeReplacements = [StoreReplacement]()

    init(_ coordinator: NSPersistentStoreCoordinator) {
        spiedCoordinator = coordinator
    }

    func migratePersistentStore(_ store: NSPersistentStore,
                                to URL: URL,
                                options: [AnyHashable: Any]?,
                                withType storeType: String) throws -> NSPersistentStore {
        try spiedCoordinator.migratePersistentStore(store, to: URL, options: options, withType: storeType)
    }

    func replacePersistentStore(at destinationURL: URL,
                                destinationOptions: [AnyHashable: Any]?,
                                withPersistentStoreFrom sourceURL: URL,
                                sourceOptions: [AnyHashable: Any]?,
                                ofType storeType: String) throws {
        try spiedCoordinator.replacePersistentStore(at: destinationURL,
                                                    destinationOptions: destinationOptions,
                                                    withPersistentStoreFrom: sourceURL,
                                                    sourceOptions: sourceOptions,
                                                    ofType: storeType)

        storeReplacements.append(.init(destinationURL: destinationURL, sourceURL: sourceURL))
    }

    func destroyPersistentStore(at url: URL, ofType storeType: String, options: [AnyHashable: Any]?) throws {
        try spiedCoordinator.destroyPersistentStore(at: url, ofType: storeType, options: options)
    }
}
