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
    /// The `StorageManagerType` that `self.storage` belongs to.
    ///
    /// This is used for observing notifications.
    private let storageManager: StorageManagerType
    /// The conditions to use when fetching the results.
    ///
    /// In the future, we can allow this to be mutable if necessary.
    private let query: Query

    /// The NotificationCenter to use for observing notifications.
    private let notificationCenter: NotificationCenter

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

    private var objectsDidChangeCancellable: AnyCancellable?
    private var storageManagerDidResetCancellable: AnyCancellable?

    public init(storageManager: StorageManagerType,
                query: Query,
                notificationCenter: NotificationCenter = .default) {
        self.storageManager = storageManager
        self.storage = storageManager.viewStorage
        self.query = query
        self.notificationCenter = notificationCenter
    }

    deinit {
        storageManagerDidResetCancellable?.cancel()
        objectsDidChangeCancellable?.cancel()
    }

    /// Start fetching and emitting snapshots.
    public func start() throws {
        try activateFetchedResultsController()

        startObservingStorageManagerDidResetNotifications()
        startObservingObjectsDidChangeNotifications()
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

// MARK: - FetchedResultsController Activation

@available(iOS 13.0, *)
private extension FetchResultSnapshotsProvider {
    /// Start `fetchedResultsController` fetching and dispatching of snapshots.
    func activateFetchedResultsController() throws {
        try fetchedResultsController.performFetch()
    }

    /// Returns `true` if the `activateFetchedResultsController()` method was previously called.
    var fetchedResultsControllerIsActive: Bool {
        fetchedResultsController.fetchedObjects != nil
    }

    /// If previously activated, restart `fetchedResultsController` fetching and dispatching of snapshots.
    ///
    /// This needs to be called when:
    ///
    /// 1. The `StorageManager` is reset.
    /// 2. When `self.query` changes.
    ///
    /// Exceptions are swallowed because:
    ///
    /// 1. This will be called inside an `NSNotification` handler and there's no ideal way to
    ///    propagate the exception.
    /// 2. We assume that the throwing method, `activateFetchedResultsController()`, has already been
    ///    previously “tested” that it works because it was already called in `start()`.
    ///
    func restartFetchedResultsController() {
        guard fetchedResultsControllerIsActive else {
            return
        }

        do {
            try activateFetchedResultsController()
        } catch {
            DDLogError("⛔️ FetchResultSnapshotsProvider: Failed to restart with error \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

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

// MARK: - ObjectsDidChange Notification Handling

@available(iOS 13.0, *)
private extension FetchResultSnapshotsProvider {

    /// Start observing `NSManagedObjectContextObjectsDidChange` notifications so that snapshots
    /// for object updates will be emitted.
    ///
    /// - SeeAlso: maybeEmitSnapshotFromObjectsDidChangeNotification
    func startObservingObjectsDidChangeNotifications() {
        // Cancel in case this method was called already.
        objectsDidChangeCancellable?.cancel()

        objectsDidChangeCancellable =
            notificationCenter.publisher(for: .NSManagedObjectContextObjectsDidChange, object: storage)
                .sink(receiveValue: { [weak self] notification in
                    self?.maybeEmitSnapshotFromObjectsDidChangeNotification(notification)
                })
    }

    /// Emit a snapshot with _reloaded_ items if the updated objects exist in the current
    /// snapshot.
    ///
    /// Normally, the `NSFetchedResultsController` will emit new snapshots if an item is
    /// updated:
    ///
    /// ```
    /// let object = derivedStorage.loadObject(...)
    /// object.dateCreated = Date()
    ///
    /// // A new snapshot will be emitted here
    /// derivedStorage.saveIfNeeded()
    /// ```
    ///
    /// This new snapshot will have the same `itemIdentifiers` (`NSManagedObjectID`) as expected.
    /// However, this will not cause the `UITableViewDiffableDataSource` to _reload_ the
    /// appropriate cells. Because the `itemIdentifiers` are the same,
    /// `UITableViewDiffableDataSource` cannot tell if the underlying data (e.g. `dateCreated`)
    /// really changed.
    ///
    /// This behavior becomes a problem in this scenario:
    ///
    /// 1. The user opens the Orders tab. All the listed orders are up to date.
    /// 2. The user leaves the app.
    /// 3. An order is changed on the web.
    /// 4. The user opens the app, causing a synchronization in the background.
    /// 5. After the sync, the updated order is received. However, `UITableViewDiffableDataSource`
    ///    did not reload the cell. The user will be viewing stale data.
    ///
    /// To circumvent this, we will create a new snapshot and call
    /// `NSDiffableDataSourceSnapshot.reloadItems` with the appropriate `NSManagedObjectIDs` of
    /// the updated objects. This will prompt `UITableViewDiffableDataSource` to reload the cells.
    ///
    /// This behavior should probably be handled by `NSFetchedResultsController` itself but
    /// it is not. ¯\_(ツ)_/¯
    ///
    /// There is a somewhat similar discussion about this here: https://developer.apple.com/forums/thread/120320.
    ///
    func maybeEmitSnapshotFromObjectsDidChangeNotification(_ notification: Notification) {
        let didChangeNotification = ObjectsDidChangeNotification(notification)

        /// Exclude object types that are not represented by `self`.
        let objectIDsWithMatchingTypes = didChangeNotification.updatedObjects.filter {
            $0 is MutableType
        }.map(\.objectID)

        guard !objectIDsWithMatchingTypes.isEmpty else {
            return
        }

        let currentSnapshot = snapshotSubject.value
        let currentObjectIDs = Set<FetchResultSnapshotObjectID>(currentSnapshot.itemIdentifiers)

        // Include only `ObjectIDs` that exist in the `currentSnapshot`.
        let objectIDsToRefresh = currentObjectIDs.intersection(objectIDsWithMatchingTypes)

        guard !objectIDsToRefresh.isEmpty else {
            return
        }

        // Copy the current snapshot and _reload_ the `ObjectIDs` of the updated objects.
        var newSnapshot = currentSnapshot
        newSnapshot.reloadItems(Array(objectIDsToRefresh))

        snapshotSubject.send(newSnapshot)
    }
}

/// A safer representation of the `Notification` emitted by `NotificationCenter` during
/// `NSManagedObjectContextObjectsDidChange`.
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

// MARK: - StorageManager Reset Handling

@available(iOS 13.0, *)
private extension FetchResultSnapshotsProvider {

    /// Observe `StorageManagerDidResetStorage` notifications so that we can restart the
    /// `fetchedResultsController` fetching.
    ///
    /// This routine is to fix a crash when `CoreDataManager.reset()` is called (e.g. during
    /// user log out). If we don't do this, it looks like the `self.fetchedResultsController`
    /// would still be pointing to an invalid `NSManagedObjectContext`. If that is not corrected,
    /// we would get a crash like this when something changes in the database:
    ///
    /// ```
    /// [error] error: Serious application error.  Exception was caught during Core Data change
    /// processing.  This is usually a bug within an observer of
    /// NSManagedObjectContextObjectsDidChangeNotification.  Object's persistent store is not
    /// reachable from this NSManagedObjectContext's coordinator with userInfo (null)
    /// ```
    ///
    /// This crash comes from `NSFetchedResultsController` itself and not from the observation
    /// in `startObservingObjectsDidChangeNotifications()`.
    ///
    func startObservingStorageManagerDidResetNotifications() {
        // Cancel just in case this method was called already.
        storageManagerDidResetCancellable?.cancel()

        storageManagerDidResetCancellable =
            notificationCenter.publisher(for: .StorageManagerDidResetStorage, object: storageManager as AnyObject)
                .sink { [weak self] _ in
                    self?.restartFetchedResultsController()
        }
    }
}
