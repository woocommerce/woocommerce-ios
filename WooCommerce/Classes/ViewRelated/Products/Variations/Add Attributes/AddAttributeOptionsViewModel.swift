import Foundation
import Yosemite

import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics
import protocol Experiments.FeatureFlagService

/// Provides view data for Add Attributes, and handles init/UI/navigation actions needed.
///
final class AddAttributeOptionsViewModel {
    typealias Section = AddAttributeOptionsViewController.Section
    typealias Row = AddAttributeOptionsViewController.Row

    /// Enum to represents the original invocation source of this view model
    ///
    enum Attribute {
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

        /// Possible states for syncing global attribute options
        ///
        enum SyncState {
            case idle
            case loading
            case failed
        }

        /// Stores the options to be offered
        ///
        var selectedOptions: [Option] = []

        /// Stores options added in previous sessions
        ///
        var existingOptions: [Option] = []

        /// Indicates synchronization state for global attribute options
        ///
        var syncState: SyncState = .idle

        /// Indicates if the view model is updating the product's attributes
        ///
        var isUpdating: Bool = false

        /// Name of the attribute
        ///
        var currentAttributeName: String = ""

        /// "Visible on product page" value of the attribute
        ///
        var isVisible: Bool = true

        /// "Used for variations" value of the attribute
        ///
        var isUsedForVariations: Bool = true
    }

    /// Defines next button visibility
    ///
    var isNextButtonEnabled: Bool {
        let optionsToSubmit = state.selectedOptions.map { $0.name }
        let attributeHasChanges = state.currentAttributeName != attribute.name
            || optionsToSubmit != attribute.previouslySelectedOptions
            || state.isVisible != initialIsVisible
            || state.isUsedForVariations != initialIsUsedForVariations
        return attributeHasChanges && state.selectedOptions.isNotEmpty
    }

    /// Defines the more(...) button visibility
    ///
    var showMoreButton: Bool {
        allowsEditing
    }

    /// Defines ghost cells visibility
    ///
    var showGhostTableView: Bool {
        state.syncState == .loading
    }

    /// Defines if the update indicator should be shown
    ///
    var showUpdateIndicator: Bool {
        state.isUpdating
    }

    /// Defines if the error state should be shown
    ///
    var showSyncError: Bool {
        state.syncState == .failed
    }

    /// Defines if the attribute can be renamed (existing local attributes only)
    ///
    var allowsRename: Bool {
        switch attribute {
        case .new:
            return false
        case let .existing(productAttribute):
            return productAttribute.isLocal
        }
    }

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

    /// Main product dependency.
    ///
    let product: Product

    /// Main attribute dependency.
    ///
    private let attribute: Attribute

    /// Main allows editing dependency.
    ///
    private let allowsEditing: Bool

    /// True when the screen is part of the flow that creates variations
    ///
    private let isVariationsFlow: Bool

    private let isNonVariationAttributesEnabled: Bool

    private let isVariableProduct: Bool

    /// "Visible on product page" and "Used for variations" values when the screen opened
    ///
    private let initialIsVisible: Bool
    private let initialIsUsedForVariations: Bool

    /// True when the product already has this attribute and uses it for variations
    ///
    private let isSavedAsUsedForVariations: Bool

    /// When an attribute exists, returns an already configured `ResultsController`
    /// When there isn't an existing attribute, returns a dummy/un-initialized `ResultsController`
    ///
    private lazy var existingOptionsResultsController: ResultsController<StorageProductAttributeTerm> = {
        guard case let .existing(attribute) = attribute, attribute.isGlobal else {
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
    private var state = State() {
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

    /// For tracking attribute creation
    ///
    private let analytics: Analytics

    /// Keeps a strong reference to the use case to wait for callback closures.
    ///
    private lazy var remoteActionUseCase = ProductFormRemoteActionUseCase(stores: stores)

    init(product: Product,
         attribute: Attribute,
         allowsEditing: Bool = false,
         isVariationsFlow: Bool = false,
         stores: StoresManager = ServiceLocator.stores,
         viewStorage: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.product = product
        self.attribute = attribute
        self.state.currentAttributeName = attribute.name
        self.allowsEditing = allowsEditing
        self.isVariationsFlow = isVariationsFlow
        let isNonVariationAttributesEnabled = featureFlagService.isFeatureFlagEnabled(.nonVariationProductAttributes)
        self.isNonVariationAttributesEnabled = isNonVariationAttributesEnabled
        self.stores = stores
        self.viewStorage = viewStorage
        self.analytics = analytics

        // An attribute the product already has keeps its values.
        // In the variations flow, or without non-variation attributes, the attribute is always used for variations.
        let productAttribute = product.attributes.first { $0.attributeID == attribute.attributeID && $0.name == attribute.name }
        let isVariableProduct = product.productType.isVariable
        self.isVariableProduct = isVariableProduct
        let isAlwaysUsedForVariations = isVariationsFlow || !isNonVariationAttributesEnabled
        self.initialIsVisible = productAttribute?.visible ?? true
        self.initialIsUsedForVariations = isAlwaysUsedForVariations || (productAttribute?.variation ?? isVariableProduct)
        self.isSavedAsUsedForVariations = productAttribute?.variation ?? false
        self.state.isVisible = initialIsVisible
        self.state.isUsedForVariations = initialIsUsedForVariations

        synchronizeOptions()
    }

    /// Updates all options based on attribute type.
    /// For global attribute remote sync will be triggered.
    ///
    func synchronizeOptions() {
        switch attribute {
        case .new:
            updateSections()
        case let .existing(attribute):
            preselectCurrentOptions(of: attribute)
            if attribute.isGlobal {
                synchronizeGlobalOptions(of: attribute)
            } else {
                populateLocalOptions(of: attribute)
            }
        }
    }
}

// MARK: - ViewController Inputs
extension AddAttributeOptionsViewModel {
    /// Inserts a new option with the provided name into the options selected section
    ///
    func addNewOption(name: String) {
        guard name.isNotEmpty else {
            return
        }
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

    /// Sets the current attribute name to a new name
    ///
    func setCurrentAttributeName(_ newName: String) {
        state.currentAttributeName = newName
    }

    /// Gets the current attribute name
    ///
    var getCurrentAttributeName: String {
        state.currentAttributeName
    }

    /// Sets the "Visible on product page" value
    ///
    func setVisible(_ isVisible: Bool) {
        state.isVisible = isVisible
    }

    /// Sets the "Used for variations" value
    ///
    func setUsedForVariations(_ isUsedForVariations: Bool) {
        state.isUsedForVariations = isUsedForVariations
    }

    /// True when turning off "Used for variations" needs a confirmation:
    /// the product has variations, and the attribute is saved as used for variations.
    ///
    func needsConfirmation(toSetUsedForVariations isUsedForVariations: Bool) -> Bool {
        !isUsedForVariations && isSavedAsUsedForVariations && product.variations.isNotEmpty
    }

    /// Gathers selected options and update the product's attributes.
    /// Note: if the product doesn't exists remotely, then the product is also created as a draft
    ///
    func updateProductAttributes(onCompletion: @escaping ((Result<Product, ProductUpdateError>) -> Void)) {
        let newProduct = createUpdatedProduct()
        if newProduct.existsRemotely {
            performProductUpdate(newProduct, onCompletion: onCompletion)
        } else {
            performProductDraftCreation(newProduct, onCompletion: onCompletion)
        }
    }

    /// Updates the product remotely by removing the current attribute
    ///
    func removeCurrentAttribute(onCompletion: @escaping ((Result<Product, ProductUpdateError>) -> Void)) {
        let newProduct = createProductByRemovingCurrentAttribute()
        performProductUpdate(newProduct, onCompletion: onCompletion)
    }

    /// Update the given product remotely.
    ///
    private func performProductUpdate(_ newProduct: Product, onCompletion: @escaping ((Result<Product, ProductUpdateError>) -> Void)) {

        // Track operation trigger
        let startDate = Date()
        analytics.track(event: .Variations.updateAttribute(productID: product.productID))

        state.isUpdating = true
        let action = ProductAction.updateProduct(product: newProduct) { [weak self] result in
            guard let self else { return }
            self.handleProductUpdate(requestStartDate: startDate, result: result, onCompletion: onCompletion)
        }
        stores.dispatch(action)
    }

    /// Creates the given product remotely as a draft.
    ///
    private func performProductDraftCreation(_ newProduct: Product, onCompletion: @escaping ((Result<Product, ProductUpdateError>) -> Void)) {
        // Track operation trigger
        let startDate = Date()
        analytics.track(event: .Variations.updateAttribute(productID: product.productID))

        let productViewModel = EditableProductModel(product: newProduct.copy(statusKey: ProductStatus.draft.rawValue))

        state.isUpdating = true
        remoteActionUseCase.addProduct(product: productViewModel, password: nil) { [weak self] result in
            guard let self else { return }
            let productResult = result.map { $0.product.product }
            self.handleProductUpdate(requestStartDate: startDate, result: productResult, onCompletion: onCompletion)
        }
    }

    /// Dispatch `onCompletion` back and add necessary tracking to the create/update product remote action.
    ///
    private func handleProductUpdate(requestStartDate: Date,
                                     result: Result<Product, ProductUpdateError>,
                                     onCompletion: @escaping ((Result<Product, ProductUpdateError>) -> Void)) {
        state.isUpdating = false
        onCompletion(result)

        // Track operation result
        let elapsedTime = Date().timeIntervalSince(requestStartDate)
        switch result {
        case .success:
            self.analytics.track(event: .Variations.updateAttributeSuccess(productID: product.productID, time: elapsedTime))
        case let .failure(error):
            self.analytics.track(event: .Variations.updateAttributeFail(productID: product.productID,
                                                                                         time: elapsedTime,
                                                                                         error: error))
        }
    }


    /// Returns a product with its name and options updated with the new attribute to create.
    /// An attribute the product already has keeps its `position`.
    ///
    private func createUpdatedProduct() -> Product {
        let newOptions = state.selectedOptions.map { $0.name }
        let newName = state.currentAttributeName

        // Name has to be considered, because local attributes are zero-id based. We use `attribute` instead of `newAttribute` because
        // the new Name may not match the old one, if the attribute was renamed.
        var attributes = product.attributes
        let existingIndex = attributes.firstIndex { $0.attributeID == attribute.attributeID && $0.name == attribute.name }
        let existingAttribute = existingIndex.map { attributes[$0] }
        let nextPosition = (attributes.map { $0.position }.max() ?? -1) + 1

        let newAttribute = ProductAttribute(siteID: product.siteID,
                                            attributeID: attribute.attributeID,
                                            name: newName,
                                            position: existingAttribute?.position ?? nextPosition,
                                            visible: state.isVisible,
                                            variation: state.isUsedForVariations,
                                            options: newOptions)

        if let existingIndex {
            attributes[existingIndex] = newAttribute
        } else {
            attributes.append(newAttribute)
        }

        return product.copy(attributes: attributes)
    }

    /// Returns a product with the current attribute removed.
    ///
    private func createProductByRemovingCurrentAttribute() -> Product {
        // Remove the current attribute from the product attribute array.
        // Name has to be considered, because local attributes are zero-id based.
        let updatedAttributes: [ProductAttribute] = {
            var attributes = product.attributes
            attributes.removeAll { $0.attributeID == attribute.attributeID && $0.name == attribute.name }
            return attributes
        }()

        return product.copy(attributes: updatedAttributes)
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
        sections = [createSettingsSection(), textFieldSection, offeredSection, addedSection].compactMap { $0 }
    }

    /// "Visible on product page" for every product type, and "Used for variations" for variable products outside the variations flow
    ///
    func createSettingsSection() -> Section? {
        guard isNonVariationAttributesEnabled else {
            return nil
        }
        let rows: [Row] = [
            .visibleOnProductPage(isOn: state.isVisible),
            isVariableProduct && !isVariationsFlow ? .usedForVariations(isOn: state.isUsedForVariations) : nil
        ].compactMap { $0 }
        return Section(header: nil, footer: nil, rows: rows, allowsReorder: false, allowsSelection: false)
    }

    func createSelectedSection() -> Section? {
        guard state.selectedOptions.isNotEmpty else {
            return nil
        }

        let rows = state.selectedOptions.map { option in
            AddAttributeOptionsViewModel.Row.selectedOptions(name: option.name)
        }

        // Only allow reorder for local attributes(existing and new)
        let allowsReorder: Bool = {
            switch attribute {
            case .new:
                return true
            case let .existing(productAttribute):
                return productAttribute.isLocal
            }
        }()

        return Section(header: Localization.headerSelectedOptions, footer: nil, rows: rows, allowsReorder: allowsReorder, allowsSelection: false)
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

    /// Pre-selects options of a product attribute.
    ///
    func preselectCurrentOptions(of attribute: ProductAttribute) {
        state.selectedOptions = attribute.options.map { option in
            .local(name: option)
        }
    }

    /// Synchronizes options for global attributes
    ///
    func synchronizeGlobalOptions(of attribute: ProductAttribute) {
        let fetchOptions = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: attribute.siteID,
                                                                                       attributeID: attribute.attributeID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.state.existingOptions = self.existingOptionsResultsController.fetchedObjects.map { .global(option: $0) }
                self.state.syncState = .idle
            case .failure(let error):
                DDLogError(error.localizedDescription)
                self.state.syncState = .failed
            }
        }
        state.syncState = .loading
        stores.dispatch(fetchOptions)
    }

    /// Populates existing options for a local attribute.
    ///
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
        static let footerTextField = NSLocalizedString("Add each option and press return",
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

private extension AddAttributeOptionsViewModel.Attribute {
    /// Returns the ID associated with the attribute. `Zero` for new attributes
    ///
    var attributeID: Int64 {
        switch self {
        case .new:
            return 0
        case .existing(let attribute):
            return attribute.attributeID
        }
    }

    /// Returns the name associated with the attribute.
    ///
    var name: String {
        switch self {
        case let .new(name):
            return name
        case let .existing(attribute):
            return attribute.name
        }
    }

    /// Returns the previously selected options of an attribute. (ie: set when creating a variation)
    ///
    var previouslySelectedOptions: [String] {
        switch self {
        case .new:
            return []
        case let .existing(attribute):
            return attribute.options
        }
    }
}
