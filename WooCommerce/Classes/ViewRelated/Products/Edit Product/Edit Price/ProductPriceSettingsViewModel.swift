import Yosemite

protocol ProductPriceSettingsViewModelOutput {
    var product: Product { get }
    var regularPrice: String? { get }
    var salePrice: String? { get }
    var dateOnSaleStart: Date? { get }
    var dateOnSaleEnd: Date? { get }
    var taxStatus: ProductTaxStatus { get }
    var taxClass: TaxClass? { get }
}

enum ProductPriceSetingsError: Error {
    case salePriceWithoutRegularPrice
    case salePriceHigherThanRegularPrice
}

final class ProductPriceSettingsViewModel: ProductPriceSettingsViewModelOutput {
    let product: Product

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

    init(product: Product, timezoneForScheduleSaleDates: TimeZone = TimeZone.siteTimezone) {
        self.product = product
        self.timezoneForScheduleSaleDates = timezoneForScheduleSaleDates

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

    // MARK: - Initialization

    func handleRetrievedTaxClass(_ taxClass: TaxClass?) {
        self.taxClass = taxClass ?? standardTaxClass
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
        let currencyFormatter = CurrencyFormatter()
        return currencyFormatter.convertToDecimal(from: price)
    }
}
