import Foundation
import Storage
import CoreData



// MARK: - MutableType: Storage.framework Type that will be retrieved (and converted into ReadOnly)
//
public typealias ResultsControllerMutableType = NSManagedObject & ReadOnlyConvertible


// MARK: - GenericResultsController (Core Implementation)
//
public class GenericResultsController<T: ResultsControllerMutableType, Output> {

    /// The `StorageType` used to fetch objects.
    ///
    private let viewStorage: StorageType

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
    public var sortDescriptors: [NSSortDescriptor]? {
        didSet {
            refreshFetchedObjects(sortDescriptors: sortDescriptors)
        }
    }

    /// NSFetchRequest instance used to do the fetching.
    ///
    private lazy var fetchRequest: NSFetchRequest<T> = {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let fetchLimit {
            request.fetchLimit = fetchLimit
        }
        return request
    }()

    /// Internal NSFetchedResultsController Instance.
    ///
    public private(set) lazy var controller: NSFetchedResultsController<T> = {
        viewStorage.createFetchedResultsController(
                fetchRequest: fetchRequest,
                sectionNameKeyPath: sectionNameKeyPath,
                cacheName: nil
        )
    }()

    /// FetchedResultsController Delegate Wrapper.
    ///
    // TODO: This being an internal delegate it needs to be stored strongly, or it will be immediately released. Is this approach appropriate?
    // swiftlint:disable:next weak_delegate
    private let internalDelegate = FetchedResultsControllerDelegateWrapper()

    /// Closure to be executed before the results are changed.
    ///
    public var onWillChangeContent: (() -> Void)?

    /// Closure to be executed after the results are changed.
    ///
    public var onDidChangeContent: (() -> Void)?

    /// Closure to be executed whenever an Object is updated.
    ///
    public var onDidChangeObject: ((_ object: Output, _ indexPath: IndexPath?, _ type: ChangeType, _ newIndexPath: IndexPath?) -> Void)?

    /// Closure to be executed whenever an entire Section is updated.
    ///
    public var onDidChangeSection: ((_ sectionInfo: SectionInfo, _ sectionIndex: Int, _ type: ChangeType) -> Void)?

    /// Closure to be executed whenever the (entire) content was reset. This happens whenever a `StorageManagerDidResetStorage` notification is
    /// caught
    ///
    public var onDidResetContent: (() -> Void)?

    /// Limits the number of objects fetched from storage
    ///
    private let fetchLimit: Int?

    /// Transformer closure to convert T to Output type.
    ///
    private let transformer: (T) -> Output

    /// Designated Initializer.
    ///
    public init(viewStorage: StorageType,
                sectionNameKeyPath: String? = nil,
                matching predicate: NSPredicate? = nil,
                fetchLimit: Int? = nil,
                sortedBy descriptors: [NSSortDescriptor],
                transformer: @escaping (T) -> Output) {

        self.viewStorage = viewStorage
        self.sectionNameKeyPath = sectionNameKeyPath
        self.predicate = predicate
        self.fetchLimit = fetchLimit
        self.sortDescriptors = descriptors
        self.transformer = transformer

        setupResultsController()
        setupEventsForwarding()
        startListeningForStorageManagerNotifications()
    }

    /// Convenience Initializer.
    ///
    public convenience init(storageManager: StorageManagerType,
                            sectionNameKeyPath: String? = nil,
                            matching predicate: NSPredicate? = nil,
                            fetchLimit: Int? = nil,
                            sortedBy descriptors: [NSSortDescriptor],
                            transformer: @escaping (T) -> Output) {

        self.init(viewStorage: storageManager.viewStorage,
                  sectionNameKeyPath: sectionNameKeyPath,
                  matching: predicate,
                  fetchLimit: fetchLimit,
                  sortedBy: descriptors,
                  transformer: transformer)
    }


    /// Executes the fetch request on the store to get objects.
    ///
    public func performFetch() throws {
        try controller.performFetch()
    }

    /// Returns the fetched object at a given indexPath.
    ///
    /// Prefer to use `safeObject(at:)` instead.
    ///
    public func object(at indexPath: IndexPath) -> Output {
        return transformer(controller.object(at: indexPath))
    }

    /// Returns the fetched object at the given `indexPath`. Returns `nil` if the `indexPath`
    /// does not exist.
    ///
    public func safeObject(at indexPath: IndexPath) -> Output? {
        guard !isEmpty else {
            return nil
        }
        guard let sections = controller.sections, sections.count > indexPath.section else {
            return nil
        }

        let section = sections[indexPath.section]

        guard section.numberOfObjects > indexPath.row else {
            return nil
        }

        return transformer(controller.object(at: indexPath))
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
    /// Note: Avoid calling this in computed variables as the conversion of storage items can be costly.
    ///
    public var fetchedObjects: [Output] {
        let transformedObjects = controller.fetchedObjects?.compactMap { mutableObject in
            transformer(mutableObject)
        }

        return transformedObjects ?? []
    }

    /// Returns an array of SectionInfo Entitites.
    ///
    public var sections: [SectionInfo] {
        let transformedSections = controller.sections?.compactMap { mutableSection in
            SectionInfo(mutableSection: mutableSection, transformer: transformer)
        }

        return transformedSections ?? []
    }

    /// Returns an optional index path of the first matching object.
    /// - Parameter objectMatching: Specifies the matching criteria.
    /// - Returns: An optional index path of the first object that matches the given criteria.
    public func indexPath(forObjectMatching objectMatching: (T) -> Bool) -> IndexPath? {
        guard let fetchedObjects = controller.fetchedObjects,
              let object = fetchedObjects.first(where: { objectMatching($0) }) else {
            return nil
        }
        return controller.indexPath(forObject: object)
    }

    /// Refreshes all of the Fetched Objects, so that the new criteria is met.
    ///
    private func refreshFetchedObjects(predicate: NSPredicate?) {
        controller.fetchRequest.predicate = predicate
        try? controller.performFetch()
    }

    /// Refreshes all of the Fetched Objects, so that the new sort descriptors are applied.
    ///
    private func refreshFetchedObjects(sortDescriptors: [NSSortDescriptor]?) {
        controller.fetchRequest.sortDescriptors = sortDescriptors
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

            let transformedObject = transformer(object)
            self.onDidChangeObject?(transformedObject, indexPath, type, newIndexPath)
        }

        internalDelegate.onDidChangeSection = { [weak self] (mutableSection, sectionIndex, type) in
            guard let `self` = self else {
                return
            }

            let transformedSection = SectionInfo(mutableSection: mutableSection, transformer: transformer)
            self.onDidChangeSection?(transformedSection, sectionIndex, type)
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
public extension GenericResultsController {

    // MARK: - ResultsController.ChangeType
    //
    typealias ChangeType = NSFetchedResultsChangeType

    // MARK: - ResultsController.SectionInfo

    /// An interface to `NSFetchedResultsSectionInfo` which enforces readonly usage.
    ///
    final class SectionInfo {

        /// The real SectionInfo that we're hiding.
        ///
        private let mutableSectionInfo: NSFetchedResultsSectionInfo

        /// Name of the section
        ///
        public var name: String {
            mutableSectionInfo.name
        }

        /// Number of objects in the current section
        ///
        public var numberOfObjects: Int {
            mutableSectionInfo.numberOfObjects
        }

        /// Transformer closure to convert objects in the section.
        ///
        private let transformer: (T) -> Output

        /// Returns the array of transformed objects in the section.
        ///
        public private(set) lazy var objects: [Output] = {
            guard let objects = mutableSectionInfo.objects else {
                return []
            }
            guard let castedObjects = objects as? [T] else {
                assertionFailure("Failed to cast objects into an array of \(T.self)")
                return []
            }

            return castedObjects.map { transformer($0) }
        }()

        /// Designated Initializer
        ///
        init(mutableSection: NSFetchedResultsSectionInfo, transformer: @escaping (T) -> Output) {
            mutableSectionInfo = mutableSection
            self.transformer = transformer
        }
    }
}

// MARK: - ResultsController (Backward Compatible Specialization)
//
public class ResultsController<T: ResultsControllerMutableType>: GenericResultsController<T, T.ReadOnlyType> {
    /// Designated Initializer.
    ///
    public init(viewStorage: StorageType,
                sectionNameKeyPath: String? = nil,
                matching predicate: NSPredicate? = nil,
                fetchLimit: Int? = nil,
                sortedBy descriptors: [NSSortDescriptor]) {
        super.init(viewStorage: viewStorage,
                   sectionNameKeyPath: sectionNameKeyPath,
                   matching: predicate,
                   fetchLimit: fetchLimit,
                   sortedBy: descriptors,
                   transformer: { $0.toReadOnly() })
    }

    /// Convenience Initializer.
    ///
    public convenience init(storageManager: StorageManagerType,
                            sectionNameKeyPath: String? = nil,
                            matching predicate: NSPredicate? = nil,
                            fetchLimit: Int? = nil,
                            sortedBy descriptors: [NSSortDescriptor]) {
        self.init(viewStorage: storageManager.viewStorage,
                  sectionNameKeyPath: sectionNameKeyPath,
                  matching: predicate,
                  fetchLimit: fetchLimit,
                  sortedBy: descriptors)
    }
}
