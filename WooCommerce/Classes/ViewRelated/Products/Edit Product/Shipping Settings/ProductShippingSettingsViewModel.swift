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

    // User device locale used to localize weight and shipping dimensions
    //
    private let locale: Locale

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
        weight?.localized(toLocale: locale)
    }

    var localizedLength: String? {
        length?.localized(toLocale: locale)
    }

    var localizedWidth: String? {
        width?.localized(toLocale: locale)
    }

    var localizedHeight: String? {
        height?.localized(toLocale: locale)
    }

    /// Nil and not editable until the shipping class is synced at a later point.
    private(set) var shippingClass: ProductShippingClass?
    private var originalShippingClass: ProductShippingClass?

    init(product: ProductFormDataModel,
         locale: Locale = .current) {
        self.product = product
        self.locale = locale
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

        guard let formatted = weight.formattedForAPI(fromLocale: locale) else {
            self.weight = weight
            return
        }

        self.weight = formatted
    }

    func handleLengthChange(_ length: String?) {
        guard let length = length else {
            self.length = nil
            return
        }

        guard let formatted = length.formattedForAPI(fromLocale: locale) else {
            self.length = length
            return
        }

        self.length = formatted
    }

    func handleWidthChange(_ width: String?) {
        guard let width = width else {
            self.width = nil
            return
        }

        guard let formatted = width.formattedForAPI(fromLocale: locale) else {
            self.width = width
            return
        }

        self.width = formatted
    }

    func handleHeightChange(_ height: String?) {
        guard let height = height else {
            self.height = nil
            return
        }

        guard let formatted = height.formattedForAPI(fromLocale: locale) else {
            self.height = height
            return
        }

        self.height = formatted
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
    func localized(toLocale: Locale) -> String {
        NumberFormatter.localizedString(using: self, from: usLocale, to: toLocale) ?? self
    }

    /// Formats the weight and shipping dimensions to the API preferred locale (US locale)
    /// API doesn not accept numbers using comma as decimal separator. More details at p91TBi-8kO-p2
    ///
    func formattedForAPI(fromLocale: Locale) -> String? {
        NumberFormatter.localizedString(using: self, from: fromLocale, to: usLocale)
    }
}
