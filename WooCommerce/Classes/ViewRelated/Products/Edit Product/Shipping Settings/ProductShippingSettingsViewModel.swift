import Yosemite

/// Provides data needed for shipping settings.
///
protocol ProductShippingSettingsViewModelOutput {
    typealias Section = ProductShippingSettingsViewController.Section

    /// Table view sections.
    var sections: [Section] { get }

    /// The product before any shipping changes.
    var product: ProductFormDataModel { get }

    var localizedWeight: String? { get }
    var localizedLength: String? { get }
    var localizedWidth: String? { get }
    var localizedHeight: String? { get }

    /// Only for UI display and list selector
    /// Nil and not editable until the shipping class is synced at a later point.
    var shippingClass: ProductShippingClass? { get }
}

/// Handles actions related to the shipping settings data.
///
protocol ProductShippingSettingsActionHandler {
    // Input field actions
    func handleWeightChange(_ weight: String?)
    func handleLengthChange(_ length: String?)
    func handleWidthChange(_ width: String?)
    func handleHeightChange(_ height: String?)
    func handleShippingClassChange(_ shippingClass: ProductShippingClass?)

    /// If the product has a shipping class (slug & ID), the shipping class is synced to get the name and for list selector.
    func onShippingClassRetrieved(shippingClass: ProductShippingClass)

    // Navigation actions
    func completeUpdating(onCompletion: ProductShippingSettingsViewController.Completion)
    func hasUnsavedChanges() -> Bool
}

/// Provides view data for shipping settings, and handles init/UI/navigation actions needed in product shipping settings.
///
final class ProductShippingSettingsViewModel: ProductShippingSettingsViewModelOutput {
    let sections: [Section]
    let product: ProductFormDataModel

    // Localizes weight and package dimensions
    //
    private let shippingValueLocalizer: ShippingValueLocalizer

    // Editable data
    //
    private var weight: String?
    private var length: String?
    private var width: String?
    private var height: String?
    private var shippingClassSlug: String?
    private var shippingClassID: Int64

    // Localized values
    //
    var localizedWeight: String? {
        shippingValueLocalizer.localized(shippingValue: weight) ?? weight
    }

    var localizedLength: String? {
        shippingValueLocalizer.localized(shippingValue: length) ?? length
    }

    var localizedWidth: String? {
        shippingValueLocalizer.localized(shippingValue: width) ?? width
    }

    var localizedHeight: String? {
        shippingValueLocalizer.localized(shippingValue: height) ?? height
    }

    /// Nil and not editable until the shipping class is synced at a later point.
    private(set) var shippingClass: ProductShippingClass?
    private var originalShippingClass: ProductShippingClass?

    init(product: ProductFormDataModel,
         shippingValueLocalizer: ShippingValueLocalizer = DefaultShippingValueLocalizer()) {
        self.product = product
        self.shippingValueLocalizer = shippingValueLocalizer
        weight = product.weight
        length = product.dimensions.length
        width = product.dimensions.width
        height = product.dimensions.height
        shippingClassSlug = product.shippingClass
        shippingClassID = product.shippingClassID

        // TODO-2580: re-enable shipping class for `ProductVariation` when the API issue is fixed.
        switch product {
        case is EditableProductModel:
            sections = [
                Section(rows: [.weight, .length, .width, .height]),
                Section(rows: [.shippingClass])
            ]
        case is EditableProductVariationModel:
            sections = [
                Section(rows: [.weight, .length, .width, .height])
            ]
        default:
            fatalError("Unsupported product type: \(product)")
        }
    }
}

extension ProductShippingSettingsViewModel: ProductShippingSettingsActionHandler {
    func handleWeightChange(_ weight: String?) {
        guard let weight = weight else {
            self.weight = nil
            return
        }

        self.weight = shippingValueLocalizer.unLocalized(shippingValue: weight) ?? weight
    }

    func handleLengthChange(_ length: String?) {
        guard let length = length else {
            self.length = nil
            return
        }
        self.length = shippingValueLocalizer.unLocalized(shippingValue: length) ?? length
    }

    func handleWidthChange(_ width: String?) {
        guard let width = width else {
            self.width = nil
            return
        }

        self.width = shippingValueLocalizer.unLocalized(shippingValue: width) ?? width
    }

    func handleHeightChange(_ height: String?) {
        guard let height = height else {
            self.height = nil
            return
        }

        self.height = shippingValueLocalizer.unLocalized(shippingValue: height) ?? height
    }

    func handleShippingClassChange(_ shippingClass: ProductShippingClass?) {
        self.shippingClass = shippingClass
        self.shippingClassSlug = shippingClass?.slug
        self.shippingClassID = shippingClass?.shippingClassID ?? 0
    }

    func onShippingClassRetrieved(shippingClass: ProductShippingClass) {
        self.shippingClass = shippingClass
        originalShippingClass = shippingClass
    }

    func completeUpdating(onCompletion: ProductShippingSettingsViewController.Completion) {
        let dimensions = ProductDimensions(length: length ?? "",
                                           width: width ?? "",
                                           height: height ?? "")
        onCompletion(weight,
                     dimensions,
                     shippingClassSlug,
                     shippingClassID,
                     hasUnsavedChanges())
    }

    func hasUnsavedChanges() -> Bool {
        weight != product.weight
            || length != product.dimensions.length
            || width != product.dimensions.width
            || height != product.dimensions.height
            || shippingClass != originalShippingClass
    }
}

private extension String {
    /// API uses US locale for weight and shipping dimensions
    ///
    private var usLocale: Locale {
        Locale(identifier: "en_US")
    }

    /// Localizes the weight and shipping dimensions
    ///
    func localized(toLocale: Locale) -> String? {
        NumberFormatter.localizedString(using: self, from: usLocale, to: toLocale)
    }

    /// Formats the weight and shipping dimensions to the API preferred locale (US locale)
    /// API doesn not accept numbers using comma as decimal separator. More details at p91TBi-8kO-p2
    ///
    func formattedForAPI(fromLocale: Locale) -> String? {
        NumberFormatter.localizedString(using: self, from: fromLocale, to: usLocale)
    }
}
