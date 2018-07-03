import Foundation
import CoreData
import Storage



// MARK: - ResultsController
//
public class ResultsController<T: NSManagedObject & ReadOnlyConvertible> {

    /// Managed Object Context used to fetch objects.
    ///
    private let viewContext: NSManagedObjectContext

    /// keyPath on resulting objects that returns the section name.
    ///
    private let sectionNameKeyPath: String?

    /// Filtering Predicate to be applied to the Results.
    ///
    private let predicate: NSPredicate?

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

    ///
    ///
    private lazy var controller: NSFetchedResultsController<T> = {
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: viewContext,
                                          sectionNameKeyPath: sectionNameKeyPath,
                                          cacheName: nil)
    }()

    ///
    ///
    private let internalDelegate = FetchedResultsControllerDelegateWrapper()

    ///
    ///
    public var onWillChangeContent: (() -> Void)?

    ///
    ///
    public var onDidChangeContent: (() -> Void)?

    ///
    ///
    public var onDidChangeObject: ((_ object: T.ReadOnlyType, _ indexPath: IndexPath?, _ type: ChangeType, _ newIndexPath: IndexPath?) -> Void)?

    ///
    ///
    public var onDidChangeSection: ((_ sectionInfo: SectionInfo, _ sectionIndex: Int, _ type: ChangeType) -> Void)?



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

        setupEventsForwarding()
        setupResultsController()
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


    /// Returns an array of SectionInfo Entitites.
    ///
    private(set) public lazy var sections: [SectionInfo] = {
        return controller.sections?.compactMap { mutableSection in
            self.readonlySection(from: mutableSection)
        } ?? []
    }()


    ///
    ///
    private func readonlySection(from mutableSection: NSFetchedResultsSectionInfo) -> SectionInfo {
        let mutableObjects = mutableSection.objects as? [T] ?? []
        let readonlyObjects = mutableObjects.map { $0.toReadOnly() }

        return SectionInfo(name: mutableSection.name, objects: readonlyObjects)
    }


    ///
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

            let readOnlySection = self.readonlySection(from: mutableSection)
            self.sections[sectionIndex] = readOnlySection
            self.onDidChangeSection?(readOnlySection, sectionIndex, type)
        }
    }


    /// Initializes the FetchedResultsController
    ///
    private func setupResultsController() {
        controller.delegate = internalDelegate
    }
}



// MARK: - Nested Types
//
public extension ResultsController {

    // MARK: - ResultsController.ChangeType
    //
    public typealias ChangeType = NSFetchedResultsChangeType

    // MARK: - ResultsController.SectionInfo
    //
    public struct SectionInfo {

        /// Name of the section
        ///
        public let name: String

        /// Number of objects in the current section
        ///
        public var numberOfObjects: Int {
            return objects.count
        }

        /// Returns the array of (ReadOnly) objects in the section.
        ///
        private(set) public var objects: [T.ReadOnlyType]
    }
}
