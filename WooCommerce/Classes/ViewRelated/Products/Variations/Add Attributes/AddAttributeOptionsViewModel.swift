import Foundation
import Yosemite

import protocol Storage.StorageManagerType

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeOptionsViewModel {
    typealias Section = AddAttributeOptionsViewController.Section
    typealias Row = AddAttributeOptionsViewController.Row

    /// Enum to represents the original invocation source of this view model
    ///
    enum Source {
        case new(name: String)
        case existing(attribute: ProductAttribute)
    }

    /// Defines the necessary state to produce the ViewModel's outputs.
    ///
    private struct State {
        /// Stores the options to be offered
        ///
        var optionsOffered: [String] = []

        /// Stores options previously added
        ///
        var optionsAdded: [ProductAttributeTerm] = []
    }

    /// Title of the navigation bar
    ///
    var titleView: String? {
        switch source {
        case .new(let name):
            return name
        case .existing(let attribute):
            return attribute.name
        }
    }

    /// Defines next button visibility
    ///
    var isNextButtonEnabled: Bool {
        state.optionsOffered.isNotEmpty
    }

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

    /// Main attribute dependency.
    ///
    private let source: Source

    /// When an attribute exists, returns an already configured `ResultsController`
    /// When there isn't an existing attribute, returns a dummy/un-initialized `ResultsController`
    ///
    private lazy var optionsOfferedResultsController: ResultsController<StorageProductAttributeTerm> = {
        guard case let .existing(attribute) = source, attribute.isGlobal else {
            // Return a dummy ResultsController if there isn't an existing attribute. It's a workaround to not deal with an optional ResultsController.
            return ResultsController<StorageProductAttributeTerm>(storageManager: viewStorage, matching: nil, sortedBy: [])
        }

        let predicate = NSPredicate(format: "siteID == %lld && attribute.attributeID == %lld", attribute.siteID, attribute.attributeID)
        let controller = ResultsController<StorageProductAttributeTerm>(storageManager: ServiceLocator.storageManager, matching: predicate, sortedBy: [])

        controller.onDidChangeContent = { [weak self] in
            self?.state.optionsAdded = controller.fetchedObjects
        }

        try? controller.performFetch()
        return controller
    }()

    /// Current `ViewModel` state.
    ///
    private var state: State = State() {
        didSet {
            updateSections()
            onChange?()
        }
    }

    private(set) var sections: [Section] = []

    /// Stores manager to dispatch sync terms(options) action.
    ///
    private let stores: StoresManager

    /// Storage manager to read fetched terms(options).
    ///
    private let viewStorage: StorageManagerType

    init(source: Source, stores: StoresManager = ServiceLocator.stores, viewStorage: StorageManagerType = ServiceLocator.storageManager) {
        self.source = source
        self.stores = stores
        self.viewStorage = viewStorage
        updateSections()
        synchronizeOptions()
    }
}

// MARK: - ViewController Inputs
extension AddAttributeOptionsViewModel {
    /// Inserts a new option with the provided name into the options offered section
    ///
    func addNewOption(name: String) {
        state.optionsOffered.append(name)
    }

    /// Reorder an option offered at the specified index to a desired index
    ///
    func reorderOptionOffered(fromIndex: Int, toIndex: Int) {
        guard let option = state.optionsOffered[safe: fromIndex], fromIndex != toIndex else {
            return
        }
        state.optionsOffered.remove(at: fromIndex)
        state.optionsOffered.insert(option, at: toIndex)
    }

    /// Removes an option offered at a given index
    ///
    func removeOptionOffered(atIndex index: Int) {
        guard index < state.optionsOffered.count else {
            return
        }
        state.optionsOffered.remove(at: index)
    }
}

// MARK: - Synchronize Product Attribute terms
//
private extension AddAttributeOptionsViewModel {
    /// Updates data in sections
    ///
    func updateSections() {
        let textFieldSection = Section(header: nil, footer: Localization.footerTextField, rows: [.termTextField], allowsReorder: false)
        let offeredSection = createOfferedSection()
        sections = [textFieldSection, offeredSection].compactMap { $0 }
    }

    func createOfferedSection() -> Section? {
        guard state.optionsOffered.isNotEmpty else {
            return nil
        }

        let rows = state.optionsOffered.map { option in
            AddAttributeOptionsViewModel.Row.selectedTerms(name: option)
        }

        return Section(header: Localization.headerSelectedTerms, footer: nil, rows: rows, allowsReorder: true)
    }

    /// Synchronizes options(terms) for global attributes
    ///
    func synchronizeOptions() {
        guard case let .existing(attribute) = source, attribute.isGlobal else {
            return
        }

        let fetchTerms = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: attribute.siteID,
                                                                                     attributeID: attribute.attributeID) { [weak self] _ in
            guard let self = self else { return }
            self.state.optionsAdded = self.optionsOfferedResultsController.fetchedObjects
        }
        stores.dispatch(fetchTerms)
    }
}

private extension AddAttributeOptionsViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Add each option and press enter",
                                                       comment: "Footer of text field section in Add Attribute Options screen")
        static let headerSelectedTerms = NSLocalizedString("OPTIONS OFFERED",
                                                           comment: "Header of selected attribute options section in Add Attribute Options screen")
        static let headerExistingTerms = NSLocalizedString("ADD OPTIONS",
                                                           comment: "Header of existing attribute options section in Add Attribute Options screen")
    }
}
