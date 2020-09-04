import Storage
import CoreData
import Combine

public typealias FetchResultSnapshotsProviderMutableType = NSManagedObject & ReadOnlyConvertible

public typealias FetchResultSnapshotObjectID = NSManagedObjectID
@available(iOS 13.0, *)
public typealias FetchResultSnapshot = NSDiffableDataSourceSnapshot<String, FetchResultSnapshotObjectID>

@available(iOS 13.0, *)
public final class FetchResultSnapshotsProvider<MutableType: FetchResultSnapshotsProviderMutableType>: NSObject, NSFetchedResultsControllerDelegate {

    public struct Query {
        /// This needs to be extended to allow an array. However, we have to add protection that
        /// there will always be at least one sort descriptor. It's required by ResultsController.
        /// It'd be great if we can check this requirement during compile-time.
        public let sortDescriptor: NSSortDescriptor
        public let predicate: NSPredicate?
        public let sectionNameKeyPath: String?

        init(sortDescriptor: NSSortDescriptor, predicate: NSPredicate? = nil, sectionNameKeyPath: String? = nil) {
            self.sortDescriptor = sortDescriptor
            self.predicate = predicate
            self.sectionNameKeyPath = sectionNameKeyPath
        }
    }

    private let storage: StorageType
    private let query: Query

    private lazy var wrappedController: NSFetchedResultsController<MutableType> = {
        let fetchRequest = NSFetchRequest<MutableType>(entityName: MutableType.entityName)
        fetchRequest.predicate = query.predicate
        fetchRequest.sortDescriptors = [query.sortDescriptor]

        let resultsController = storage.createFetchedResultsController(
            fetchRequest: fetchRequest,
            sectionNameKeyPath: query.sectionNameKeyPath,
            cacheName: nil
        )
        resultsController.delegate = self
        return resultsController
    }()

    private let snapshotSubject = CurrentValueSubject<FetchResultSnapshot, Never>(FetchResultSnapshot())

    public var snapshot: AnyPublisher<FetchResultSnapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }

    public init(storageManager: StorageManagerType, query: Query) {
        self.storage = storageManager.viewStorage
        self.query = query
    }

    public func start() throws {
        try wrappedController.performFetch()
    }

    public func object(withID objectID: FetchResultSnapshotObjectID) -> MutableType.ReadOnlyType? {
        assert(!objectID.isTemporaryID, "Expected objectID \(objectID) to be a permanent NSManagedObjectID.")

        if let storageOrder = storage.loadObject(ofType: MutableType.self, with: objectID) {
            return storageOrder.toReadOnly()
        } else {
            return nil
        }
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as FetchResultSnapshot
        snapshotSubject.send(snapshot)
    }
}
