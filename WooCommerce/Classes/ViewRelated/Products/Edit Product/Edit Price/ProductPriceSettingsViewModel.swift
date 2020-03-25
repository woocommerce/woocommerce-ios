import Yosemite

/// Provides data needed for price settings.
///
protocol ProductPriceSettingsViewModelOutput {
    var regularPrice: String? { get }
    var salePrice: String? { get }
    var dateOnSaleStart: Date? { get }
    var dateOnSaleEnd: Date? { get }
    var taxStatus: ProductTaxStatus { get }
    var taxClass: TaxClass? { get }
}

/// Handles actions related to the price settings data.
///
protocol ProductPriceSettingsActionHandler {
    // Initialization
    func retrieveProductTaxClass(completion: @escaping () -> Void)

    // Input field actions
    func handleRegularPriceChange(_ regularPrice: String?)
    func handleSalePriceChange(_ salePrice: String?)
    func handleTaxClassChange(_ taxClass: TaxClass?)
    func handleTaxStatusChange(_ taxStatus: ProductTaxStatus)
    func handleScheduleSaleChange(isEnabled: Bool)
    func handleSaleStartDateChange(_ date: Date)
    func handleSaleEndDateChange(_ date: Date)

    // Navigation actions
    func completeUpdating(onCompletion: ProductPriceSettingsViewController.Completion, onError: (ProductPriceSetingsError) -> Void)
    func hasUnsavedChanges() -> Bool
}

/// Error cases that could occur in product price settings.
///
enum ProductPriceSetingsError: Error {
    case salePriceWithoutRegularPrice
    case salePriceHigherThanRegularPrice
}

/// Provides view data for price settings, and handles init/UI/navigation actions needed in product price settings.
///
final class ProductPriceSettingsViewModel: ProductPriceSettingsViewModelOutput {
    private let product: Product

    // Editable data
    //
    private(set) var regularPrice: String?
    private(set) var salePrice: String?

    private(set) var dateOnSaleStart: Date?
    private(set) var dateOnSaleEnd: Date?

    // Timezone of the website
    //
    private let timezoneForScheduleSaleDates: TimeZone

    // Date Pickers status
    //
    private var datePickerSaleFromVisible = false
    private var datePickerSaleToVisible = false

    // Today at the start of the day
    //
    private lazy var defaultStartDate = Date().startOfDay(timezone: timezoneForScheduleSaleDates)

    // Tomorrow at the end of the day
    //
    private lazy var defaultEndDate = Calendar.current.date(byAdding: .day, value: 1, to: Date().endOfDay(timezone: timezoneForScheduleSaleDates))

    // Internal data for rendering UI
    //
    private(set) var taxStatus: ProductTaxStatus = .taxable
    private(set) var taxClass: TaxClass?

    // The tax class configured by default, always present in a website
    //
    private let standardTaxClass: TaxClass

    private let currencyFormatter: CurrencyFormatter

    init(product: Product, currencySettings: CurrencySettings = CurrencySettings.shared, timezoneForScheduleSaleDates: TimeZone = TimeZone.siteTimezone) {
        self.product = product
        self.timezoneForScheduleSaleDates = timezoneForScheduleSaleDates
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)

        regularPrice = product.regularPrice
        salePrice = product.salePrice
        dateOnSaleStart = product.dateOnSaleStart
        dateOnSaleEnd = product.dateOnSaleEnd

        let taxClassName = NSLocalizedString("Standard rate", comment: "The name of the default Tax Class in Product Price Settings")
        standardTaxClass = TaxClass(siteID: product.siteID, name: taxClassName, slug: "standard")

        if let productTaxClassSlug = product.taxClass, productTaxClassSlug.isEmpty == false {
            taxClass = TaxClass(siteID: product.siteID, name: productTaxClassSlug, slug: productTaxClassSlug)
        }
        else {
            taxClass = standardTaxClass
        }
        taxStatus = product.productTaxStatus
    }
}

extension ProductPriceSettingsViewModel: ProductPriceSettingsActionHandler {
    // MARK: - Initialization

    func retrieveProductTaxClass(completion: @escaping () -> Void) {
        let action = TaxClassAction.requestMissingTaxClasses(for: product) { [weak self] (taxClass, error) in
            self?.taxClass = taxClass ?? self?.standardTaxClass
            completion()
        }
        ServiceLocator.stores.dispatch(action)
    }

    // MARK: - UI changes

    func handleRegularPriceChange(_ regularPrice: String?) {
        self.regularPrice = regularPrice
    }

    func handleSalePriceChange(_ salePrice: String?) {
        self.salePrice = salePrice
    }

    func handleTaxClassChange(_ taxClass: TaxClass?) {
        self.taxClass = taxClass
    }

    func handleTaxStatusChange(_ taxStatus: ProductTaxStatus) {
        self.taxStatus = taxStatus
    }

    func handleScheduleSaleChange(isEnabled: Bool) {
        if isEnabled {
            self.dateOnSaleStart = dateOnSaleStart ?? defaultStartDate
            self.dateOnSaleEnd = dateOnSaleEnd ?? defaultEndDate
            return
        }

        dateOnSaleStart = nil
        dateOnSaleEnd = nil
    }

    func handleSaleStartDateChange(_ date: Date) {
        guard let dateOnSaleEnd = dateOnSaleEnd else {
            return
        }

        dateOnSaleStart = date.startOfDay(timezone: timezoneForScheduleSaleDates)

        if dateOnSaleEnd < date {
            self.dateOnSaleEnd = date.endOfDay(timezone: timezoneForScheduleSaleDates)
        }
    }

    func handleSaleEndDateChange(_ date: Date) {
        guard let dateOnSaleStart = dateOnSaleStart else {
            return
        }

        if date < dateOnSaleStart {
            return
        }
        else {
            self.dateOnSaleEnd = date.endOfDay(timezone: self.timezoneForScheduleSaleDates)
        }
    }

    // MARK: - Navigation actions

    func completeUpdating(onCompletion: ProductPriceSettingsViewController.Completion, onError: (ProductPriceSetingsError) -> Void) {
        let newSalePrice = salePrice == "0" ? nil : salePrice

        // Check if the sale price is populated, and the regular price is not.
        if getDecimalPrice(salePrice) != nil, getDecimalPrice(regularPrice) == nil {
            onError(.salePriceWithoutRegularPrice)
            return
        }

        // Check if the sale price is less of the regular price, else show an error.
        if let decimalSalePrice = getDecimalPrice(salePrice), let decimalRegularPrice = getDecimalPrice(regularPrice),
            decimalSalePrice.compare(decimalRegularPrice) != .orderedAscending {
            onError(.salePriceHigherThanRegularPrice)
            return
        }

        onCompletion(regularPrice, newSalePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass)
    }

    func hasUnsavedChanges() -> Bool {
        let newSalePrice = salePrice == "0" ? nil : salePrice

        // Since an empty string and the standard tax class's slug both represent the standard tax class, the original and new
        // tax classes are converted to empty string whenever the value matches the standard tax class's slug.
        let newTaxClass = taxClass?.slug == standardTaxClass.slug ? "" : taxClass?.slug
        let originalTaxClass = product.taxClass == standardTaxClass.slug ? "": product.taxClass

        if getDecimalPrice(regularPrice) != getDecimalPrice(product.regularPrice) ||
            getDecimalPrice(newSalePrice) != getDecimalPrice(product.salePrice) ||
            dateOnSaleStart != product.dateOnSaleStart ||
            dateOnSaleEnd != product.dateOnSaleEnd ||
            taxStatus.rawValue != product.taxStatusKey ||
            newTaxClass != originalTaxClass {
            return true
        }

        return false
    }
}

private extension ProductPriceSettingsViewModel {
    func getDecimalPrice(_ price: String?) -> NSDecimalNumber? {
        guard let price = price else {
            return nil
        }
        return currencyFormatter.convertToDecimal(from: price)
    }
}
