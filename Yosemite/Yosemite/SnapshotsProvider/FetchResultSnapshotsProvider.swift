import Storage
import CoreData
import Combine

/// The mutable (`Storage` model) type that is used by `FetchResultSnapshotsProvider`.
public typealias FetchResultSnapshotsProviderMutableType = NSManagedObject & ReadOnlyConvertible

/// The type of the items emitted by `FetchResultSnapshot`.
///
/// This is only declared to _hide_ `NSManagedObjectID` from the UI.
public typealias FetchResultSnapshotObjectID = NSManagedObjectID

/// Emitted by `FetchResultSnapshotsProvider` to be consumed by a `DiffableDataSource`.
///
/// The `String` is the type of the `FetchResultSnapshot.sectionIdenfifiers` items. The
/// `FetchResultSnapshotObjectID` is the type of the `FetchResultSnapshot.itemIdentifiers` items.
@available(iOS 13.0, *)
public typealias FetchResultSnapshot = NSDiffableDataSourceSnapshot<String, FetchResultSnapshotObjectID>

/// Emits `FetchResultSnapshot` objects for Core Data fetch results. The snapshot can be used
/// by `DiffableDataSource` consumers like `UITableViewDiffableDataSource`.
///
/// This will continuously emit snapshots whenever the data changes.
///
/// ## Example Usage
///
/// ```
/// // Create the snapshots provider
/// let query = FetchResultSnapshotsProvider<StorageOrder>.Query(
///     sortDescriptor: .init(keyPath: \StorageOrder.number, ascending: false)
/// )
/// let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)
///
/// // Set up the TableView and DataSource
/// let dataSource =
///    UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID>(tableView: tableView,
///                                                                       cellProvider: self.makeCellProvider())
/// tableView.dataSource = dataSource
///
/// // Apply the emitted snapshots to the TableView's DataSource
/// provider.snapshot.sink { snapshot in
///     dataSource.apply(snapshot)
/// }.store(in: &self.cancellables)
///
/// provider.start()
/// ```
///
/// That's it! The `UITableView` should be automatically updated whenever the data changes.
///
///
/// ## Important: Permanent ObjectIDs
///
/// For now, we have to ensure that when inserting `MutableType` in `Storage`, we will have to
/// obtain permanent IDs by calling `StorageType.obtainPermanentIDs`. This is because
/// `NSFetchedResultsController` can emit snapshots that contain temporary `ObjectIDs`.
/// Because of this, these undesirable effects can happen:
///
/// 1. The table can display empty cells because even though the snapshot has temporary IDs, those
///    temporary IDs were immediately converted to permanent IDs. And hence, `self.object(withID:)`
///    will return `nil`.
/// 2. The table will perform double (funky) animation when showing new records. We have the option
///    to use `NSManagedObjectContext.object(withID:)` in `self.object(withID:)` so that temporary
///    IDs are considered and it will not return `nil`. However, the `FRC` can emit two snapshots
///    in sequence in a short period of time. The first snapshot contains the temporary IDs and
///    the second one contains the permanent IDs. But for `UITableViewDiffableDataSource`,
///    the objects are “different” and it would animate the same rows in and out. Here is a sample of
///    how this undesirable animation looks like https://tinyurl.com/y62lwzg9. There is also
///    a related discussion about this [here](https://git.io/JUW5r).
///
@available(iOS 13.0, *)
public final class FetchResultSnapshotsProvider<MutableType: FetchResultSnapshotsProviderMutableType> {

    /// Defines the conditions for fetching the results.
    public struct Query {
        /// Defines how to sort the results.
        ///
        /// This is required because `NSFetchedResultsController` requires it.
        ///
        /// This needs to be extended to allow an array. However, we have to add protection that
        /// there will always be at least one `NSSortDescriptor`. It'd be great if we can check
        /// this requirement during compile-time.
        public let sortDescriptor: NSSortDescriptor
        /// An optional predicate to filter the results.
        public let predicate: NSPredicate?
        /// A keypath that returns the value to use for grouping results into sections.
        ///
        /// The values will be accessible in `FetchResultSnapshot.sectionIdentifiers`. In the UI,
        /// those values can be converted to a user-friendly value.
        public let sectionNameKeyPath: String?

        public init(sortDescriptor: NSSortDescriptor, predicate: NSPredicate? = nil, sectionNameKeyPath: String? = nil) {
            self.sortDescriptor = sortDescriptor
            self.predicate = predicate
            self.sectionNameKeyPath = sectionNameKeyPath
        }
    }

    /// The `StorageType` to perform the fetch on.
    ///
    /// This is currently forced to be the `viewStorage` (main thread). In the future, we can
    /// probably move this to a background `StorageType` since `UITableViewDiffableDataSource`
    /// allows consuming snapshots in the background.
    private let storage: StorageType
    /// The conditions to use when fetching the results.
    ///
    /// In the future, we can allow this to be mutable if necessary.
    private let query: Query

    /// The publisher that emits snapshots when the fetch results arrive and when the data changes.
    public var snapshot: AnyPublisher<FetchResultSnapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }
    private let snapshotSubject = CurrentValueSubject<FetchResultSnapshot, Never>(FetchResultSnapshot())

    private lazy var fetchedResultsController: NSFetchedResultsController<MutableType> = {
        let fetchRequest = NSFetchRequest<MutableType>(entityName: MutableType.entityName)
        fetchRequest.predicate = query.predicate
        fetchRequest.sortDescriptors = [query.sortDescriptor]

        let resultsController = storage.createFetchedResultsController(
            fetchRequest: fetchRequest,
            sectionNameKeyPath: query.sectionNameKeyPath,
            cacheName: nil
        )
        resultsController.delegate = self.hiddenFetchedResultsControllerDelegate
        return resultsController
    }()

    /// The delgate for `fetchedResultsController`.
    private lazy var hiddenFetchedResultsControllerDelegate = HiddenFetchedResultsControllerDelegate(self)

    public init(storageManager: StorageManagerType, query: Query) {
        self.storage = storageManager.viewStorage
        self.query = query
    }

    /// Start fetching and emitting snapshots.
    public func start() throws {
        try fetchedResultsController.performFetch()
    }

    /// Retrieve the immutable type pointed to by `objectID`.
    ///
    /// This is typically used in the `UITableViewDiffableDataSource`'s `CellProvider` in order to
    /// display the row's information. Example:
    ///
    /// ```
    /// private func makeCellProvider() -> UITableViewDiffableDataSource<String, FetchResultSnapshotObjectID>.CellProvider {
    ///    return { [weak self] tableView, indexPath, objectID in
    ///        guard let self = self, let cell = tableView.dequeueReusableCell(withIdentifier: ...) else {
    ///            fatalError()
    ///        }
    ///
    ///        let order = provider.object(withID: objectID)
    ///        cell.configure(using: order)
    ///        return cell
    ///    }
    /// }
    /// ```
    public func object(withID objectID: FetchResultSnapshotObjectID) -> MutableType.ReadOnlyType? {
        // WIP This assertion will be restored soon.
        // assert(!objectID.isTemporaryID, "Expected objectID \(objectID) to be a permanent NSManagedObjectID.")

        if let storageOrder = storage.loadObject(ofType: MutableType.self, with: objectID) {
            return storageOrder.toReadOnly()
        } else {
            return nil
        }
    }
}

@available(iOS 13.0, *)
private extension FetchResultSnapshotsProvider {
    /// Part of `FetchResultSnapshotsProvider` which submits new `FetchResultSnapshot` objects to
    /// `snapshotSubject` whenever `NSFetchedResultsController` receives changes.
    ///
    /// This class is used to hide the `controller:didChangeContentWith:` delegate method. If we
    /// didn't have this, then we would have had to make that delegate method `public`. And
    /// that throws encapsulation out of the window. :D
    final class HiddenFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {

        private weak var snapshotsProvider: FetchResultSnapshotsProvider?

        init(_ snapshotsProvider: FetchResultSnapshotsProvider) {
            self.snapshotsProvider = snapshotsProvider
        }

        /// Converts the `NSFetchedResultsController` results to a snapshot that is then emitted
        /// to observers.
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
            let snapshot = snapshot as FetchResultSnapshot
            snapshotsProvider?.snapshotSubject.send(snapshot)
        }
    }
}
