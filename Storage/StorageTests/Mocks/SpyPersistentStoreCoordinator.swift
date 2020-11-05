import CoreData

@testable import Storage

final class SpyPersistentStoreCoordinator: PersistentStoreCoordinatorProtocol {

    struct Replacement {
        let destinationURL: URL
        let sourceURL: URL
    }

    struct StoreMigrations {
        let destinationURL: URL
    }

    private let spiedCoordinator: NSPersistentStoreCoordinator

    private(set) var storeMigrations = [StoreMigrations]()
    private(set) var storeReplacements = [Replacement]()

    init(_ coordinator: NSPersistentStoreCoordinator) {
        spiedCoordinator = coordinator
    }

    func migratePersistentStore(_ store: NSPersistentStore,
                                to URL: URL,
                                options: [AnyHashable: Any]?,
                                withType storeType: String) throws -> NSPersistentStore {
        let migratedStore = try spiedCoordinator.migratePersistentStore(store,
                                                                        to: URL,
                                                                        options: options,
                                                                        withType: storeType)
        storeMigrations.append(.init(destinationURL: URL))
        return migratedStore
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
