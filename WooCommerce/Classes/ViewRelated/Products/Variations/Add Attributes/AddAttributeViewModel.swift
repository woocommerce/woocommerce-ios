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
    private(set) var localAndGlobalAttributes: [ProductAttribute] = []

    private(set) var sections: [Section] = []
    private(set) var newAttributeName: String?

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
    /// Synchronizes all global product attributes.
    ///
    func synchronizeAllProductAttributes() {
        syncProductAttributesState = .syncing
        let action = ProductAttributeAction.synchronizeProductAttributes(siteID: product.siteID) { [weak self] result in
            switch result {
            case .success(let attributes):
                self?.updateSections(attributes: attributes)
                self?.syncProductAttributesState = .synced
            case .failure(let error):
                DDLogError("⛔️ Error fetching product attributes: \(error.localizedDescription)")
                self?.syncProductAttributesState = .failed
            }
        }
        storesManager.dispatch(action)
    }

    /// Updates  data from the remote fetched objects.
    ///
    func updateSections(attributes: [ProductAttribute]) {

        /// Sum fetched attributes + attributes inside the product (global + local), and remove duplicated product attributes, then sort it
        localAndGlobalAttributes = attributes + product.attributes.filter { element in
            return !attributes.contains { $0.attributeID == element.attributeID }
        }.sorted(by: > )

        var attributesRows = [Row]()
        for _ in 0..<localAndGlobalAttributes.count {
            attributesRows.append(.existingAttribute)
        }
        let attributesSection = attributesRows.count > 0 ? Section(header: Localization.headerAttributes, footer: nil, rows: attributesRows) : nil

        sections = [Section(header: nil, footer: Localization.footerTextField, rows: [.attributeTextField]), attributesSection].compactMap { $0 }
    }
}


// MARK: Actions
extension AddAttributeViewModel {

    func handleNewAttributeNameChange(_ name: String?) {
        guard name != nil && name?.isNotEmpty == true else {
            newAttributeName = nil
            return
        }

        newAttributeName = name
    }
}

private extension AddAttributeViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Variation type (ie Color, Size)", comment: "Footer of text field section in Add Attribute screen")
        static let headerAttributes = NSLocalizedString("Or tap to select existing attribute", comment: "Header of attributes section in Add Attribute screen")
    }
}
