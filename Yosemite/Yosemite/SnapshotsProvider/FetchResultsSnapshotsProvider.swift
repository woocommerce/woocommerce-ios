import Storage
import CoreData
import Combine

@available(iOS 13.0, *)
public final class FetchResultSnapshotsProvider: NSObject {

    public typealias ObjectID = NSManagedObjectID
    public typealias Snapshot = NSDiffableDataSourceSnapshot<String, ObjectID>

    private let storage: StorageType

    private lazy var wrappedController: NSFetchedResultsController<StorageOrder> = {
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageOrder.dateCreated, ascending: false)
        let fetchRequest = NSFetchRequest<StorageOrder>(entityName: StorageOrder.entityName)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let sectionNameKeyPath = #selector(StorageOrder.normalizedAgeAsString)
        let resultsController = storage.createFetchedResultsController(
            fetchRequest: fetchRequest,
            sectionNameKeyPath: "\(sectionNameKeyPath)",
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

    public init(storage: StorageType) {
        self.storage = storage
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
}

@available(iOS 13.0, *)
extension FetchResultSnapshotsProvider: NSFetchedResultsControllerDelegate {
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
