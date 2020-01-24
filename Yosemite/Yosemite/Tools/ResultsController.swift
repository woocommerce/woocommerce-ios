import Foundation
import Storage
import CoreData



// MARK: - MutableType: Storage.framework Type that will be retrieved (and converted into ReadOnly)
//
public typealias ResultsControllerMutableType = NSManagedObject & ReadOnlyConvertible


// MARK: - ResultsController
//
public class ResultsController<T: ResultsControllerMutableType> {

    /// Managed Object Context used to fetch objects.
    ///
    private let viewContext: NSManagedObjectContext

    /// keyPath on resulting objects that returns the section name.
    ///
    private let sectionNameKeyPath: String?

    /// Filtering Predicate to be applied to the Results.
    ///
    public var predicate: NSPredicate? {
        didSet {
            refreshFetchedObjects(predicate: predicate)
        }
    }

    /// Results's Sort Descriptor.
    ///
    private let sortDescriptors: [NSSortDescriptor]?

    /// NSFetchRequest instance used to do the fetching.
    ///
    private lazy var fetchRequest: NSFetchRequest<T> = {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }()

    /// Internal NSFetchedResultsController Instance.
    ///
    private lazy var controller: NSFetchedResultsController<T> = {
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: viewContext,
                                          sectionNameKeyPath: sectionNameKeyPath,
                                          cacheName: nil)
    }()

    /// FetchedResultsController Delegate Wrapper.
    ///
    private let internalDelegate = FetchedResultsControllerDelegateWrapper()

    /// NotificationCenter ObserverBlock Token
    ///
    private var notificationCenterToken: Any?

    /// Closure to be executed before the results are changed.
    ///
    public var onWillChangeContent: (() -> Void)?

    /// Closure to be executed after the results are changed.
    ///
    public var onDidChangeContent: (() -> Void)?

    /// Closure to be executed whenever an Object is updated.
    ///
    public var onDidChangeObject: ((_ object: T.ReadOnlyType, _ indexPath: IndexPath?, _ type: ChangeType, _ newIndexPath: IndexPath?) -> Void)?

    /// Closure to be executed whenever an entire Section is updated.
    ///
    public var onDidChangeSection: ((_ sectionInfo: SectionInfo, _ sectionIndex: Int, _ type: ChangeType) -> Void)?

    /// Closure to be executed whenever the (entire) content was reset. This happens whenever a `StorageManagerDidResetStorage` notification is
    /// caught
    ///
    public var onDidResetContent: (() -> Void)?


    /// Designated Initializer.
    ///
    public init(viewContext: NSManagedObjectContext,
                sectionNameKeyPath: String? = nil,
                matching predicate: NSPredicate? = nil,
                sortedBy descriptors: [NSSortDescriptor]) {

        self.viewContext = viewContext
        self.sectionNameKeyPath = sectionNameKeyPath
        self.predicate = predicate
        self.sortDescriptors = descriptors

        setupResultsController()
        setupEventsForwarding()
        startListeningForStorageManagerNotifications()
    }

    /// Convenience Initializer.
    ///
    public convenience init(storageManager: CoreDataManager,
                            sectionNameKeyPath: String? = nil,
                            matching predicate: NSPredicate? = nil,
                            sortedBy descriptors: [NSSortDescriptor]) {

        self.init(viewContext: storageManager.persistentContainer.viewContext,
                  sectionNameKeyPath: sectionNameKeyPath,
                  matching: predicate,
                  sortedBy: descriptors)
    }


    /// Executes the fetch request on the store to get objects.
    ///
    public func performFetch() throws {
        try controller.performFetch()
    }

    /// Returns the fetched object at a given indexPath.
    ///
    public func object(at indexPath: IndexPath) -> T.ReadOnlyType {
        return controller.object(at: indexPath).toReadOnly()
    }

    /// Returns the Plain ObjectIndex corresponding to a given IndexPath. You can use this index to map the
    /// `fetchedObject[index]` collection.
    ///
    /// This is *required* for calculations involving Page / Scrolling.
    ///
    public func objectIndex(from indexPath: IndexPath) -> Int {
        guard let sections = controller.sections else {
            return indexPath.row
        }

        var output = indexPath.row
        for (index, section) in sections.enumerated() where index < indexPath.section {
            output += section.numberOfObjects
        }

        return output
    }

    /// Indicates if there are any Objects matching the specified criteria.
    ///
    public var isEmpty: Bool {
        return controller.fetchedObjects?.isEmpty ?? true
    }
    
    /// Returns the number of fetched objects.
    ///
    public var numberOfObjects: Int {
        return controller.fetchedObjects?.count ?? 0
    }

    /// Returns an array of all of the (ReadOnly) Fetched Objects.
    ///
    public var fetchedObjects: [T.ReadOnlyType] {
        let readOnlyObjects = controller.fetchedObjects?.compactMap { mutableObject in
            mutableObject.toReadOnly()
        }

        return readOnlyObjects ?? []
    }

    /// Returns an array of SectionInfo Entitites.
    ///
    public var sections: [SectionInfo] {
        let readOnlySections = controller.sections?.compactMap { mutableSection in
            SectionInfo(mutableSection: mutableSection)
        }

        return readOnlySections ?? []
    }

    /// Refreshes all of the Fetched Objects, so that the new criteria is met.
    ///
    private func refreshFetchedObjects(predicate: NSPredicate?) {
        controller.fetchRequest.predicate = predicate
        try? controller.performFetch()
    }

    /// Initializes the FetchedResultsController
    ///
    private func setupResultsController() {
        controller.delegate = internalDelegate
    }

    /// Initializes FRC's Event Forwarding.
    ///
    private func setupEventsForwarding() {
        internalDelegate.onWillChangeContent = { [weak self] in
            self?.onWillChangeContent?()
        }

        internalDelegate.onDidChangeContent = { [weak self] in
            self?.onDidChangeContent?()
        }

        internalDelegate.onDidChangeObject = { [weak self] (object, indexPath, type, newIndexPath) in
            guard let `self` = self, let object = object as? T else {
                return
            }

            let readOnlyObject = object.toReadOnly()
            self.onDidChangeObject?(readOnlyObject, indexPath, type, newIndexPath)
        }

        internalDelegate.onDidChangeSection = { [weak self] (mutableSection, sectionIndex, type) in
            guard let `self` = self else {
                return
            }

            let readOnlySection = SectionInfo(mutableSection: mutableSection)
            self.onDidChangeSection?(readOnlySection, sectionIndex, type)
        }
    }

    /// Listens for `StorageManagerDidResetStorage` Notifications
    ///
    private func startListeningForStorageManagerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(storageWasReset), name: .StorageManagerDidResetStorage, object: nil)
    }

    /// Whenever the storage was reset, this method will refetch all of the contents, and call the `onDidResetContent` closure.
    ///
    @objc func storageWasReset() {
        DDLogInfo("<> ResultsController: Re-Fetching")

        try? self.controller.performFetch()
        self.onDidResetContent?()
    }
}



// MARK: - Nested Types
//
public extension ResultsController {

    // MARK: - ResultsController.ChangeType
    //
    typealias ChangeType = NSFetchedResultsChangeType

    // MARK: - ResultsController.SectionInfo
    //
    class SectionInfo {

        /// Name of the section
        ///
        public let name: String

        /// Number of objects in the current section
        ///
        public var numberOfObjects: Int {
            return mutableObjects.count
        }

        /// Returns the array of (ReadOnly) objects in the section.
        ///
        private(set) public lazy var objects: [T.ReadOnlyType] = {
            return mutableObjects.map { $0.toReadOnly() }
        }()


        /// Array of Mutable Objects!
        ///
        private let mutableObjects: [T]


        /// Designated Initializer
        ///
        init(mutableSection: NSFetchedResultsSectionInfo) {
            name = mutableSection.name
            mutableObjects = mutableSection.objects as? [T] ?? []
        }
    }
}
