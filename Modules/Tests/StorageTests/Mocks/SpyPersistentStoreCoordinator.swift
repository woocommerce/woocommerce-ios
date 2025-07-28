import CoreData

@testable import Storage

/// Performs the functions of an `NSPersistentStoreCoordinator` instance while also logging
/// the executed functions' arguments in inspectable properties.
final class SpyPersistentStoreCoordinator: PersistentStoreCoordinatorProtocol {

    /// Defines some of the arguments passed to the `replacePersistentStore()` function.
    struct Replacement {
        let destinationURL: URL
        let sourceURL: URL
    }

    private let spiedCoordinator: NSPersistentStoreCoordinator

    /// The replacements logged during every call of `replacePersistentStore()`.
    private(set) var replacements = [Replacement]()
    /// The URLs of the stores destroyed by `destroyPersistentStore()`.
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
