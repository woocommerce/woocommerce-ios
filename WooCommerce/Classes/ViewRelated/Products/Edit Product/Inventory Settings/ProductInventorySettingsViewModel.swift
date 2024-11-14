import Combine
import Yosemite
import Experiments
import WooFoundation

/// Provides data needed for inventory settings.
///
protocol ProductInventorySettingsViewModelOutput {
    typealias Section = ProductInventorySettingsViewController.Section

    /// Observable table view sections.
    var sections: AnyPublisher<[Section], Never> { get }

    /// Potential error from input changes.
    var errors: [ProductUpdateError] { get }

    /// The type of inventory form.
    var formType: ProductInventorySettingsViewController.FormType { get }

    // Editable data - shared.
    //
    var sku: String? { get }

    var globalUniqueID: String? { get }

    var manageStockEnabled: Bool { get }
    // Optional: only editable in `Product`
    var soldIndividually: Bool? { get }

    // Editable data - manage stock enabled.
    var stockQuantity: Decimal? { get }
    var backordersSetting: ProductBackordersSetting? { get }

    // Editable data - manage stock disabled.
    var stockStatus: ProductStockStatus? { get }

    // Visibility logic

    /// Whether stock status is editable in the inventory settings.
    var isStockStatusEnabled: Bool { get }
}

/// Handles actions related to the inventory settings data.
///
protocol ProductInventorySettingsActionHandler {
    // Input field actions
    func handleSKUChange(_ sku: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleGlobalUniqueIdentifierChange(_ globalUniqueID: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleSKUFromBarcodeScanner(_ sku: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleGlobalUniqueIdentifierFromBarcodeScanner(_ globalUniqueID: String?,
                                                        onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
    func handleManageStockEnabledChange(_ manageStockEnabled: Bool)
    func handleSoldIndividuallyChange(_ soldIndividually: Bool?)
    func handleStockQuantityChange(_ stockQuantity: String?)
    func handleBackordersSettingChange(_ backordersSetting: ProductBackordersSetting?)
    func handleStockStatusChange(_ stockStatus: ProductStockStatus?)

    // Navigation actions
    func completeUpdating(onCompletion: ProductInventorySettingsViewController.Completion)
    func hasUnsavedChanges() -> Bool
}

/// Provides view data for inventory settings, and handles init/UI/navigation actions needed in product inventory settings.
///
final class ProductInventorySettingsViewModel: ProductInventorySettingsViewModelOutput {
    typealias FormType = ProductInventorySettingsViewController.FormType
    let formType: FormType
    private let productModel: ProductFormDataModel

    private let siteID: Int64

    // Editable data - shared.
    //
    private(set) var sku: String?
    private(set) var globalUniqueID: String?
    private(set) var manageStockEnabled: Bool
    // Optional: only editable in `Product`
    private(set) var soldIndividually: Bool?

    // Editable data - manage stock enabled.
    private(set) var stockQuantity: Decimal?
    private(set) var backordersSetting: ProductBackordersSetting?

    // Editable data - manage stock disabled.
    private(set) var stockStatus: ProductStockStatus?

    let isStockStatusEnabled: Bool

    /// Table Sections to be rendered
    ///
    var sections: AnyPublisher<[Section], Never> {
        $sectionsSubject.eraseToAnyPublisher()
    }
    @Published private var sectionsSubject: [Section] = []

    private(set) var errors: [ProductUpdateError] = []

    private let analytics: Analytics

    // Sku validation
    private var skuIsValid: Bool = true
    private var globalUniqueIdIsValid: Bool = true
    private lazy var throttler: Throttler = Throttler(seconds: 0.5)

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(formType: FormType,
         productModel: ProductFormDataModel,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics) {
        self.formType = formType
        self.productModel = productModel
        self.stores = stores
        self.siteID = productModel.siteID

        self.sku = productModel.sku
        self.globalUniqueID = productModel.globalUniqueID
        self.manageStockEnabled = productModel.manageStock
        self.soldIndividually = productModel.soldIndividually

        self.stockQuantity = productModel.stockQuantity
        self.backordersSetting = productModel.backordersSetting
        self.stockStatus = productModel.stockStatus

        self.isStockStatusEnabled = productModel.isStockStatusEnabled()
        self.featureFlagService = featureFlagService
        self.analytics = analytics

        reloadSections()
    }
}

extension ProductInventorySettingsViewModel: ProductInventorySettingsActionHandler {
    func handleSKUChange(_ sku: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        self.sku = sku

        // If the sku is identical to the old one, is always valid
        guard sku != productModel.sku else {
            skuIsValid = true
            hideError(error: .duplicatedSKU)
            throttler.cancel()
            onValidation(true, true)
            return
        }

        // Throttled API call
        let siteID = self.siteID
        throttler.throttle {
            DispatchQueue.main.async { [weak self] in
                let action = ProductAction.validateProductSKU(sku, siteID: siteID) { [weak self] isValid in
                    guard let self = self else {
                        return
                    }
                    self.skuIsValid = isValid

                    guard isValid else {
                        self.displayError(error: .duplicatedSKU)
                        onValidation(false, true)
                        return
                    }
                    self.hideError(error: .duplicatedSKU)
                    onValidation(true, false)
                }

                self?.stores.dispatch(action)
            }
        }
    }

    func handleGlobalUniqueIdentifierChange(_ globalUniqueID: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        self.globalUniqueID = globalUniqueID

        guard let newGlobalUniqueID = globalUniqueID,
              globalUniqueIdentifierIsValid(newGlobalUniqueID) else {

            var shouldBringUpKeyboard = false
            // If the error was already shown there's no need to show it again
            if !errors.contains(.invalidGlobalUniqueIdentifier) {
                displayError(error: .invalidGlobalUniqueIdentifier)
                // After reloading the sections the keyboard was dismissed, let's bring it back again
                shouldBringUpKeyboard = true
            }

            globalUniqueIdIsValid = false
            onValidation(false, shouldBringUpKeyboard)

            return
        }

        // Bring keyboard up if the error was shown, so they user can keep typing when the sections are reloaded to remove the error message
        let shouldBringUpKeyboard = errors.contains(.invalidGlobalUniqueIdentifier)
        hideError(error: .invalidGlobalUniqueIdentifier)
        globalUniqueIdIsValid = true
        onValidation(true, shouldBringUpKeyboard)
    }

    func handleSKUFromBarcodeScanner(_ sku: String?, onValidation: @escaping (Bool, Bool) -> Void) {
        // Displays SKU before validation.
        self.sku = sku
        reloadSections()
        handleSKUChange(sku, onValidation: onValidation)
    }

    func handleGlobalUniqueIdentifierFromBarcodeScanner(_ globalUniqueID: String?,
                                                        onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        handleGlobalUniqueIdentifierChange(globalUniqueID, onValidation: onValidation)
        reloadSections()
    }

    func handleManageStockEnabledChange(_ manageStockEnabled: Bool) {
        self.manageStockEnabled = manageStockEnabled
        reloadSections()
    }

    func handleSoldIndividuallyChange(_ soldIndividually: Bool?) {
        self.soldIndividually = soldIndividually
    }

    func handleStockQuantityChange(_ stockQuantity: String?) {
        guard let stockQuantity = stockQuantity else {
            return
        }
        self.stockQuantity = Decimal(string: stockQuantity)
    }

    func handleBackordersSettingChange(_ backordersSetting: ProductBackordersSetting?) {
        self.backordersSetting = backordersSetting
        reloadSections()
    }

    func handleStockStatusChange(_ stockStatus: ProductStockStatus?) {
        self.stockStatus = stockStatus
        reloadSections()
    }

    func completeUpdating(onCompletion: (ProductInventoryEditableData) -> Void) {
        if skuIsValid && globalUniqueIdIsValid {
            if globalUniqueID != productModel.globalUniqueID {
                analytics.track(.productInventorySettingsGlobalUniqueIDFieldEdited)
            }

            let data = ProductInventoryEditableData(sku: sku,
                                                    globalUniqueIdentifier: globalUniqueID,
                                                    manageStock: manageStockEnabled,
                                                    soldIndividually: soldIndividually,
                                                    stockQuantity: stockQuantity,
                                                    backordersSetting: backordersSetting,
                                                    stockStatus: stockStatus)
            onCompletion(data)
        }
    }

    func hasUnsavedChanges() -> Bool {
        guard skuIsValid,
              globalUniqueIdIsValid else {
            return true
        }

        // Checks general settings regardless of whether stock management is enabled.
        let hasChangesInGeneralSettings = sku != productModel.sku
            || globalUniqueID != productModel.globalUniqueID
            || manageStockEnabled != productModel.manageStock
            || soldIndividually != productModel.soldIndividually

        // Checks stock settings depending on whether stock management is enabled.
        let hasChangesInStockSettings: Bool
        if manageStockEnabled {
            hasChangesInStockSettings = stockQuantity != productModel.stockQuantity
                || backordersSetting != productModel.backordersSetting
        } else {
            hasChangesInStockSettings = stockStatus != productModel.stockStatus
        }

        return hasChangesInGeneralSettings || hasChangesInStockSettings
    }
}

// MARK: - Sections reload
//
private extension ProductInventorySettingsViewModel {
    func reloadSections() {
        var sections = [createSKUSection()]
        if featureFlagService.isFeatureFlagEnabled(.productGlobalUniqueIdentifierSupport) {
            sections.append(createGlobalUniqueIdentifierSection())
        }

        if formType == .inventory {
            let stockSection: Section
            if manageStockEnabled {
                stockSection = Section(rows: [.manageStock, .stockQuantity, .backorders])
            } else if isStockStatusEnabled {
                stockSection = Section(rows: [.manageStock, .stockStatus])
            } else {
                stockSection = Section(rows: [.manageStock])
            }

            sections.append(stockSection)

            if productModel is EditableProductModel {
                sections.append(Section(rows: [.limitOnePerOrder]))
            }
        }

        sectionsSubject = sections
    }

    func createSKUSection() -> Section {
        let skuError = errors.first { $0 == .invalidSKU || $0 == .duplicatedSKU }

        if let skuError = skuError {
            return Section(errorTitle: skuError.errorDescription, rows: [.sku])
        } else {
            return Section(rows: [.sku])
        }
    }

    func createGlobalUniqueIdentifierSection() -> Section {
        if errors.contains(.invalidGlobalUniqueIdentifier) {
            return Section(errorTitle: ProductUpdateError.invalidGlobalUniqueIdentifier.errorDescription, rows: [.globalUniqueIdentifier])
        } else {
            return Section(rows: [.globalUniqueIdentifier])
        }
    }
}

// MARK: - Error handling
//
private extension ProductInventorySettingsViewModel {
    func displayError(error: ProductUpdateError) {
        errors.append(error)
        reloadSections()
    }

    func hideError(error: ProductUpdateError) {
        // This check is useful so we don't reload while typing each letter in the sections
        if errors.contains(error) {
            errors.removeAll { $0 == error }
            reloadSections()
        }
    }

    func globalUniqueIdentifierIsValid(_ input: String) -> Bool {
        guard input.isNotEmpty else {
            return true
        }

        // Only contains numbers and hyphens
        let pattern = "^[0-9-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)

        return predicate.evaluate(with: input)
    }
}
