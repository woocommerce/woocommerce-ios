import Foundation
import CoreData
import Storage


/// EntityListener: Observes changes performed over a specified ReadOnly Entity, and executes the callback Closures, as required.
/// *Note:* The type T is expected to be a ReadOnly one.
///
public class EntityListener<T: ReadOnlyType> {

    /// NSManagedObjectContext associated to the Main Thread.
    ///
    private let viewContext: NSManagedObjectContext

    /// Last known state of the Observed ReadOnly Entity.
    ///
    private(set) public var readOnlyEntity: T

    /// NotificationCenter Observer Token.
    ///
    private var notificationsToken: Any!

    /// Closure to be executed whenever the associated Storage.Entity is: (Updated | Refreshed | Inserted).
    ///
    public var onUpsert: ((T) -> Void)?

    /// Closure to be executed whenever the associated Storage.Entity gets Nuked from the ViewContext.
    ///
    public var onDelete: (() -> Void)?


    /// Designated Initializer.
    ///
    public init(viewContext: NSManagedObjectContext, readOnlyEntity: T) {
        /// This tool expects a *ReadOnly* entity. We'll make sure we haven't received a NSMO.
        ///
        assert(readOnlyEntity is NSManagedObject == false)

        self.viewContext = viewContext
        self.readOnlyEntity = readOnlyEntity
        self.notificationsToken = startObservingChangeNotifications(in: viewContext)
    }

    /// Convenience Initializer.
    ///
    public convenience init(storageManager: CoreDataManager, readOnlyEntity: T) {
        self.init(viewContext: storageManager.persistentContainer.viewContext,
                  readOnlyEntity: readOnlyEntity)
    }
}


// MARK: - Private Methods
//
private extension EntityListener {

    /// Starts observing changes performed over the ViewContext.
    ///
    func startObservingChangeNotifications(in context: NSManagedObjectContext) -> Any {
        let nc = NotificationCenter.default
        return nc.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: viewContext, queue: nil) { [weak self] notification in
            self?.viewContextDidChange(notification: notification)
        }
    }

    /// Handles the ContextObjectDidChange Notification triggered by the ViewContext.
    ///
    func viewContextDidChange(notification: Notification) {
        guard let note = ManagedObjectsDidChangeNotification(notification: notification) else {
            return
        }

        /// Scenario: Upsert (Insert + Update + Refresh)
        ///
        if let storageEntity = readOnlyConvertible(from: note.upsertedObjects, representing: readOnlyEntity),
            let updatedEntity = storageEntity.toTypeErasedReadOnly() as? T {
            readOnlyEntity = updatedEntity
            onUpsert?(readOnlyEntity)
        }

        /// Scenario: Nuked
        ///
        if let _ = readOnlyConvertible(from: note.deletedObjects, representing: readOnlyEntity) {
            onDelete?()
        }
    }

    /// Returns the first NSManagedObject stored in a fiven collection, which represents the specified (ReadOnly) entity.
    ///
    func readOnlyConvertible(from storageEntities: Set<NSManagedObject>, representing readOnlyEntity: T) -> TypeErasedReadOnlyConvertible? {
        for case let storageEntity as TypeErasedReadOnlyConvertible in storageEntities {
            guard readOnlyEntity.isReadOnlyRepresentation(of: storageEntity) else {
                continue
            }

            return storageEntity
        }

        return nil
    }
}
