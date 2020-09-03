import Storage
import CoreData
import Combine

public typealias FetchResultSnapshotsProviderResultType = NSManagedObject & ReadOnlyConvertible

public typealias FetchResultSnapshotObjectID = NSManagedObjectID

@available(iOS 13.0, *)
public final class FetchResultSnapshotsProvider<ResultType: FetchResultSnapshotsProviderResultType>: NSObject, NSFetchedResultsControllerDelegate {

    public typealias Snapshot = NSDiffableDataSourceSnapshot<String, FetchResultSnapshotObjectID>

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

    private lazy var wrappedController: NSFetchedResultsController<ResultType> = {
        let fetchRequest = NSFetchRequest<ResultType>(entityName: ResultType.entityName)
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

    private let snapshotSubject = CurrentValueSubject<Snapshot, Never>(Snapshot())

    public var snapshot: AnyPublisher<Snapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }

    public init(storage: StorageType, query: Query) {
        self.storage = storage
        self.query = query
    }

    public func start() throws {
        try wrappedController.performFetch()
    }

    public func object(withID objectID: FetchResultSnapshotObjectID) -> Order? {
        let context = storage as! NSManagedObjectContext
        if let storageOrder = try? context.existingObject(with: objectID) as? StorageOrder {
            return storageOrder.toReadOnly()
        } else {
            return nil
        }
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as Snapshot
        snapshotSubject.send(snapshot)
    }
}
