import Yosemite
import Observables

/// Provides data needed for inventory settings.
///
protocol ProductInventorySettingsViewModelOutput {
    typealias Section = ProductInventorySettingsViewController.Section

    /// Observable table view sections.
    var sections: Observable<[Section]> { get }

    /// Potential error from input changes.
    var error: ProductUpdateError? { get }

    /// The type of inventory form.
    var formType: ProductInventorySettingsViewController.FormType { get }

    // Editable data - shared.
    //
    var sku: String? { get }
    var manageStockEnabled: Bool { get }
    // Optional: only editable in `Product`
    var soldIndividually: Bool? { get }

    // Editable data - manage stock enabled.
    var stockQuantity: Int64? { get }
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
    func handleSKUFromBarcodeScanner(_ sku: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void)
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
    private(set) var manageStockEnabled: Bool
    // Optional: only editable in `Product`
    private(set) var soldIndividually: Bool?

    // Editable data - manage stock enabled.
    private(set) var stockQuantity: Int64?
    private(set) var backordersSetting: ProductBackordersSetting?

    // Editable data - manage stock disabled.
    private(set) var stockStatus: ProductStockStatus?

    let isStockStatusEnabled: Bool

    /// Table Sections to be rendered
    ///
    var sections: Observable<[Section]> {
        sectionsSubject
    }
    private let sectionsSubject: BehaviorSubject<[Section]> = BehaviorSubject<[Section]>([])

    private(set) var error: ProductUpdateError?

    // Sku validation
    private var skuIsValid: Bool = true
    private lazy var throttler: Throttler = Throttler(seconds: 0.5)

    private let stores: StoresManager

    init(formType: FormType, productModel: ProductFormDataModel, stores: StoresManager = ServiceLocator.stores) {
        self.formType = formType
        self.productModel = productModel
        self.stores = stores
        self.siteID = productModel.siteID

        self.sku = productModel.sku
        self.manageStockEnabled = productModel.manageStock
        self.soldIndividually = productModel.soldIndividually

        self.stockQuantity = productModel.stockQuantity
        self.backordersSetting = productModel.backordersSetting
        self.stockStatus = productModel.stockStatus

        self.isStockStatusEnabled = productModel.isStockStatusEnabled()

        reloadSections()
    }
}

extension ProductInventorySettingsViewModel: ProductInventorySettingsActionHandler {
    func handleSKUChange(_ sku: String?, onValidation: @escaping (_ isValid: Bool, _ shouldBringUpKeyboard: Bool) -> Void) {
        self.sku = sku

        // If the sku is identical to the old one, is always valid
        guard sku != productModel.sku else {
            skuIsValid = true
            hideError()
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
                    self.hideError()
                    onValidation(true, false)
                }

                self?.stores.dispatch(action)
            }
        }
    }

    func handleSKUFromBarcodeScanner(_ sku: String?, onValidation: @escaping (Bool, Bool) -> Void) {
        // Displays SKU before validation.
        self.sku = sku
        reloadSections()
        handleSKUChange(sku, onValidation: onValidation)
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
        self.stockQuantity = Int64(stockQuantity)
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
        if skuIsValid {
            let data = ProductInventoryEditableData(sku: sku,
                                                    manageStock: manageStockEnabled,
                                                    soldIndividually: soldIndividually,
                                                    stockQuantity: stockQuantity,
                                                    backordersSetting: backordersSetting,
                                                    stockStatus: stockStatus)
            onCompletion(data)
        }
    }

    func hasUnsavedChanges() -> Bool {
        guard skuIsValid else {
            return true
        }

        // Checks general settings regardless of whether stock management is enabled.
        let hasChangesInGeneralSettings = sku != productModel.sku
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
        let sections: [Section]
        switch formType {
        case .inventory:
            let stockSection: Section
            if manageStockEnabled {
                stockSection = Section(rows: [.manageStock, .stockQuantity, .backorders])
            } else if isStockStatusEnabled {
                stockSection = Section(rows: [.manageStock, .stockStatus])
            } else {
                stockSection = Section(rows: [.manageStock])
            }

            switch productModel {
            case is EditableProductModel:
                sections = [
                    createSKUSection(),
                    stockSection,
                    Section(rows: [.limitOnePerOrder])
                ]
            case is EditableProductVariationModel:
                sections = [
                    createSKUSection(),
                    stockSection
                ]
            default:
                fatalError("Unsupported product type: \(productModel)")
            }
        case .sku:
            sections = [
                createSKUSection()
            ]
        }
        sectionsSubject.send(sections)
    }

    func createSKUSection() -> Section {
        if let error = error {
            return Section(errorTitle: error.errorDescription, rows: [.sku])
        } else {
            return Section(rows: [.sku])
        }
    }
}

// MARK: - Error handling
//
private extension ProductInventorySettingsViewModel {
    func displayError(error: ProductUpdateError) {
        self.error = error
        reloadSections()
    }

    func hideError() {
        // This check is useful so we don't reload while typing each letter in the sections
        if error != nil {
            error = nil
            reloadSections()
        }
    }
}
