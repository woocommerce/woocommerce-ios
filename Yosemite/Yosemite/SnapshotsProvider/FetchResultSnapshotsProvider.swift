import Storage
import CoreData
import Combine

public typealias FetchResultSnapshotsProviderResultType = NSManagedObject & ReadOnlyConvertible

@available(iOS 13.0, *)
public final class FetchResultSnapshotsProvider<ResultType: FetchResultSnapshotsProviderResultType>: NSObject, NSFetchedResultsControllerDelegate {

    public typealias ObjectID = NSManagedObjectID
    public typealias Snapshot = NSDiffableDataSourceSnapshot<String, ObjectID>
    public typealias ResultMutableType = NSManagedObject & ReadOnlyConvertible

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
    private var observationToken: Any?

    public var snapshot: AnyPublisher<Snapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }

    public init(storage: StorageType, query: Query) {
        self.storage = storage
        self.query = query
    }

    public func start() throws {
        try wrappedController.performFetch()

        #warning("fix cast")
        let context = storage as! NSManagedObjectContext
        let nc = NotificationCenter.default

        if let token = observationToken {
            nc.removeObserver(token)
        }

        observationToken = nc.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: context, queue: nil) { [weak self] notification in
            guard let self = self else {
                return
            }

            let structuredNotification = ObjectsDidChangeNotification(notification)

            #warning("also add filter using the correct entity")
            let currentSnapshot = self.snapshotSubject.value
            let managedObjectIDs = structuredNotification.updatedObjects.map(\.objectID).filter { managedObjectID in
                currentSnapshot.indexOfItem(managedObjectID) != nil
            }
            if !managedObjectIDs.isEmpty {
                var newSnapshot = currentSnapshot
                newSnapshot.reloadItems(managedObjectIDs)
                self.snapshotSubject.send(newSnapshot)
            }
        }
    }

    deinit {
        if let token = observationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    public func object(withID objectID: ObjectID) -> Order? {
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

private struct ObjectsDidChangeNotification {

    private let notification: Notification

    init(_ notification: Notification) {
        assert(notification.name == .NSManagedObjectContextObjectsDidChange)
        self.notification = notification
    }

    var updatedObjects: Set<NSManagedObject> {
        (notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? Set()
    }
}
