import Foundation
import Yosemite

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeViewModel {

    typealias Section = AddAttributeViewController.Section
    typealias Row = AddAttributeViewController.Row

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let storesManager: StoresManager

    private let product: Product
    private(set) var fetchedAttributes: [ProductAttribute] = []

    private lazy var resultController: ResultsController<StorageProductAttribute> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld", product.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductAttribute.name, ascending: true)
        return ResultsController<StorageProductAttribute>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    var sections: [Section] = []

    /// Represents the current state of `synchronizeProductAttributes` action. Useful for the consumer to update it's UI upon changes
    ///
    enum SyncingState: Equatable {
        case initialized
        case syncing
        case failed
        case synced
    }

    /// Closure to be invoked when `synchronizeProductAttributes` state changes
    ///
    private var onSyncStateChange: ((SyncingState) -> Void)?

    /// Current  product attributes synchronization state
    ///
    private var syncProductAttributesState: SyncingState = .initialized {
        didSet {
            guard syncProductAttributesState != oldValue else {
                return
            }
            onSyncStateChange?(syncProductAttributesState)
        }
    }

    init(storesManager: StoresManager = ServiceLocator.stores, product: Product) {
        self.storesManager = storesManager
        self.product = product
    }

    /// Load existing product attributes from storage and fire the synchronize all product attributes action.
    ///
    func performFetch() {
        synchronizeAllProductAttributes()
        try? resultController.performFetch()
    }

    /// Observes and notifies of changes made to product attributes. The current state will be dispatched upon subscription.
    /// Calling this method will remove any other previous observer.
    ///
    func observeProductAttributesListStateChanges(onStateChanges: @escaping (SyncingState) -> Void) {
        onSyncStateChange = onStateChanges
        onSyncStateChange?(syncProductAttributesState)
    }
}

// MARK: - Synchronize global Product Attributes
//
private extension AddAttributeViewModel {
    /// Synchronizes all global  product attributes.
    ///
    func synchronizeAllProductAttributes() {
        syncProductAttributesState = .syncing
        let action = ProductAttributeAction.synchronizeProductAttributes(siteID: product.siteID) { [weak self] result in
            self?.updateSections()

            switch result {
            case .success:
                self?.syncProductAttributesState = .synced
            case .failure(let error):
                DDLogError("⛔️ Error fetching product attributes: \(error.localizedDescription)")
                self?.syncProductAttributesState = .failed
            }
        }
        storesManager.dispatch(action)
    }

    /// Updates  data from  the resultController's fetched objects.
    ///
    func updateSections() {
        fetchedAttributes = resultController.fetchedObjects
        var attributesRows = [Row]()
        for _ in 0..<fetchedAttributes.count {
            attributesRows.append(.existingAttribute)
        }
        let attributesSection = Section(header: Localization.headerAttributes, footer: nil, rows: attributesRows)

        sections = [Section(header: nil, footer: Localization.footerTextField, rows: [.attributeTextField]), attributesSection]
    }
}

private extension AddAttributeViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Variation type (ie Color, Size)", comment: "Footer of text field section in Add Attribute screen")
        static let headerAttributes = NSLocalizedString("Or tap to select existing attribute", comment: "Header of attributes section in Add Attribute screen")
    }
}
