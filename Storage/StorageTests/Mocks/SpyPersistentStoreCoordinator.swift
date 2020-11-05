import CoreData

@testable import Storage

final class SpyPersistentStoreCoordinator: PersistentStoreCoordinatorProtocol {

    struct Replacement {
        let destinationURL: URL
        let sourceURL: URL
    }

    struct Migration {
        let destinationURL: URL
    }

    private let spiedCoordinator: NSPersistentStoreCoordinator

    private(set) var replacements = [Replacement]()
    private(set) var destroyedURLs = [URL]()

    init(_ coordinator: NSPersistentStoreCoordinator) {
        spiedCoordinator = coordinator
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

        replacements.append(.init(destinationURL: destinationURL, sourceURL: sourceURL))
    }

    func destroyPersistentStore(at url: URL, ofType storeType: String, options: [AnyHashable: Any]?) throws {
        try spiedCoordinator.destroyPersistentStore(at: url, ofType: storeType, options: options)

        destroyedURLs.append(url)
    }
}
