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
    fileprivate struct State {
        /// Bundles the attributes options that are supported
        ///
        enum Option {
            case local(name: String)
            case global(option: ProductAttributeTerm)
        }

        /// Stores the options to be offered
        ///
        var selectedOptions: [Option] = []

        /// Stores options added in previous sessions
        ///
        var existingOptions: [Option] = []

        /// Indicates if the view model is syncing a global attribute options
        ///
        var isSyncing: Bool = false
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
        state.selectedOptions.isNotEmpty
    }

    var showGhostTableView: Bool {
        state.isSyncing
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
    private lazy var existingOptionsResultsController: ResultsController<StorageProductAttributeTerm> = {
        guard case let .existing(attribute) = source, attribute.isGlobal else {
            // Return a dummy ResultsController if there isn't an existing attribute. It's a workaround to not deal with an optional ResultsController.
            return ResultsController<StorageProductAttributeTerm>(storageManager: viewStorage, matching: nil, sortedBy: [])
        }

        let predicate = NSPredicate(format: "siteID == %lld && attribute.attributeID == %lld", attribute.siteID, attribute.attributeID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        let controller = ResultsController<StorageProductAttributeTerm>(storageManager: viewStorage, matching: predicate, sortedBy: [descriptor])

        controller.onDidChangeContent = { [weak self] in
            self?.state.existingOptions = controller.fetchedObjects.map { .global(option: $0) }
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

    /// Stores manager to dispatch sync global options action.
    ///
    private let stores: StoresManager

    /// Storage manager to read fetched global options.
    ///
    private let viewStorage: StorageManagerType

    init(source: Source, stores: StoresManager = ServiceLocator.stores, viewStorage: StorageManagerType = ServiceLocator.storageManager) {
        self.source = source
        self.stores = stores
        self.viewStorage = viewStorage

        switch source {
        case .new:
            updateSections()
        case let .existing(attribute) where attribute.isGlobal:
            synchronizeGlobalOptions(of: attribute)
        case let .existing(attribute) where attribute.isLocal:
            populateLocalOptions(of: attribute)
        default:
            break
        }
    }
}

// MARK: - ViewController Inputs
extension AddAttributeOptionsViewModel {
    /// Inserts a new option with the provided name into the options selected section
    ///
    func addNewOption(name: String) {
        state.selectedOptions.append(.local(name: name))
    }

    /// Reorder a selected option at the specified index to a desired index.
    ///
    func reorderSelectedOptions(fromIndex: Int, toIndex: Int) {
        guard let option = state.selectedOptions[safe: fromIndex], fromIndex != toIndex else {
            return
        }
        state.selectedOptions.remove(at: fromIndex)
        state.selectedOptions.insert(option, at: toIndex)
    }

    /// Removes a selected  option at a given index
    ///
    func removeSelectedOption(atIndex index: Int) {
        guard index < state.selectedOptions.count else {
            return
        }
        state.selectedOptions.remove(at: index)
    }

    /// Moves an existing option at the specified index to the "Options Selected" section.
    ///
    func selectExistingOption(atIndex index: Int) {
        guard let option = remainingExistingOptions()[safe: index] else {
            return
        }

        addNewOption(name: option.name)
    }
}

// MARK: - Synchronize Product Attribute Options
//
private extension AddAttributeOptionsViewModel {
    /// Updates data in sections
    ///
    func updateSections() {
        let textFieldSection = Section(header: nil,
                                       footer: Localization.footerTextField,
                                       rows: [.optionTextField],
                                       allowsReorder: false,
                                       allowsSelection: false)
        let offeredSection = createSelectedSection()
        let addedSection = createExistingSection()
        sections = [textFieldSection, offeredSection, addedSection].compactMap { $0 }
    }

    func createSelectedSection() -> Section? {
        guard state.selectedOptions.isNotEmpty else {
            return nil
        }

        let rows = state.selectedOptions.map { option in
            AddAttributeOptionsViewModel.Row.selectedOptions(name: option.name)
        }

        return Section(header: Localization.headerSelectedOptions, footer: nil, rows: rows, allowsReorder: true, allowsSelection: false)
    }

    func createExistingSection() -> Section? {
        let currentOptionsAdded = remainingExistingOptions()
        guard currentOptionsAdded.isNotEmpty else {
            return nil
        }

        let rows = currentOptionsAdded.map { option in
            AddAttributeOptionsViewModel.Row.existingOptions(name: option.name)
        }

        return Section(header: Localization.headerExistingOptions, footer: nil, rows: rows, allowsReorder: false, allowsSelection: true)
    }

    /// Synchronizes options for global attributes
    ///
    func synchronizeGlobalOptions(of attribute: ProductAttribute) {
        let fetchOptions = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: attribute.siteID,
                                                                                       attributeID: attribute.attributeID) { [weak self] _ in
            guard let self = self else { return }
            self.state.existingOptions = self.existingOptionsResultsController.fetchedObjects.map { .global(option: $0) }
            self.state.isSyncing = false
        }
        state.isSyncing = true
        stores.dispatch(fetchOptions)
    }

    func populateLocalOptions(of attribute: ProductAttribute) {
        state.existingOptions = attribute.options.map { option in
            .local(name: option)
        }
    }

    /// Returns a filtered(based on the option name) version of `state.existingOptions` where options that exists in `state.selectedOptions` are removed.
    ///
    func remainingExistingOptions() -> [State.Option] {
        let optionsOfferedNames = state.selectedOptions.map { $0.name }
        return state.existingOptions.filter { option in
            !optionsOfferedNames.contains(option.name)
        }
    }
}

private extension AddAttributeOptionsViewModel {
    enum Localization {
        static let footerTextField = NSLocalizedString("Add each option and press enter",
                                                       comment: "Footer of text field section in Add Attribute Options screen")
        static let headerSelectedOptions = NSLocalizedString("OPTIONS OFFERED",
                                                           comment: "Header of selected attribute options section in Add Attribute Options screen")
        static let headerExistingOptions = NSLocalizedString("ADD OPTIONS",
                                                           comment: "Header of existing attribute options section in Add Attribute Options screen")
    }
}

private extension AddAttributeOptionsViewModel.State.Option {
    /// Returns the name associated with the option
    ///
    var name: String {
        switch self {
        case let .local(name):
            return name
        case let .global(option):
            return option.name
        }
    }
}
