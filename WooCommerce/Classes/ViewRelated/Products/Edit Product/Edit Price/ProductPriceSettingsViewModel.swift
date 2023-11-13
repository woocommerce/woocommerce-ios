import Yosemite
import WooFoundation

/// Provides data needed for price settings.
///
protocol ProductPriceSettingsViewModelOutput {
    typealias Section = ProductPriceSettingsViewController.Section
    typealias Row = ProductPriceSettingsViewController.Row
    var sections: [Section] { get }

    var regularPrice: String? { get }
    var salePrice: String? { get }
    var dateOnSaleStart: Date? { get }
    var dateOnSaleEnd: Date? { get }
    var taxStatus: ProductTaxStatus { get }
    var taxClass: TaxClass? { get }
    var subscriptionPeriod: String? { get }
}

/// Handles actions related to the price settings data.
///
protocol ProductPriceSettingsActionHandler {
    // Initialization
    func retrieveProductTaxClass(completion: @escaping () -> Void)

    // Tap actions
    func didTapScheduleSaleFromRow()
    func didTapScheduleSaleToRow()

    // Input field actions
    func handleRegularPriceChange(_ regularPrice: String?)
    func handleSalePriceChange(_ salePrice: String?)
    func handleTaxClassChange(_ taxClass: TaxClass?)
    func handleTaxStatusChange(_ taxStatus: ProductTaxStatus)
    func handleScheduleSaleChange(isEnabled: Bool)
    func handleSaleStartDateChange(_ date: Date)
    func handleSaleEndDateChange(_ date: Date?)
    func handleSubscriptionPeriodChange(interval: String, period: SubscriptionPeriod)

    // Navigation actions
    func completeUpdating(onCompletion: ProductPriceSettingsViewController.Completion, onError: (ProductPriceSettingsError) -> Void)
    func hasUnsavedChanges() -> Bool
}

/// Provides view data for price settings, and handles init/UI/navigation actions needed in product price settings.
///
final class ProductPriceSettingsViewModel: ProductPriceSettingsViewModelOutput {
    private let product: ProductFormDataModel & TaxClassRequestable

    // Editable data
    //
    private(set) var regularPrice: String?
    private(set) var salePrice: String?

    private(set) var subscriptionPeriod: String?

    private(set) var dateOnSaleStart: Date?
    private(set) var dateOnSaleEnd: Date?

    private let originalDateOnSaleStart: Date?

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

    private let priceSettingsValidator: ProductPriceSettingsValidator

    init(product: ProductFormDataModel & TaxClassRequestable,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         timezoneForScheduleSaleDates: TimeZone = TimeZone.siteTimezone) {
        self.product = product
        self.timezoneForScheduleSaleDates = timezoneForScheduleSaleDates
        self.priceSettingsValidator = ProductPriceSettingsValidator(currencySettings: currencySettings)

        regularPrice = product.regularPrice
        salePrice = product.salePrice
        subscriptionPeriod = product.subscriptionPeriodDescription

        // If the product sale start date is nil and the sale end date is not in the past, defaults the sale start date to today.
        if let saleEndDate = product.dateOnSaleEnd, product.dateOnSaleStart == nil &&
            Date().startOfDay(timezone: timezoneForScheduleSaleDates) <= saleEndDate.startOfDay(timezone: timezoneForScheduleSaleDates) {
            dateOnSaleStart = Date().startOfDay(timezone: timezoneForScheduleSaleDates)
        } else {
            dateOnSaleStart = product.dateOnSaleStart
        }
        originalDateOnSaleStart = dateOnSaleStart
        dateOnSaleEnd = product.dateOnSaleEnd

        standardTaxClass = TaxClass(siteID: product.siteID, name: Strings.standardTaxClassName, slug: "standard")

        if let productTaxClassSlug = product.taxClass, productTaxClassSlug.isEmpty == false {
            taxClass = TaxClass(siteID: product.siteID, name: productTaxClassSlug, slug: productTaxClassSlug)
        }
        else {
            taxClass = standardTaxClass
        }
        taxStatus = product.productTaxStatus
    }

    var sections: [Section] {
        // Price section
        var priceRows: [Row] = [.price]
        if product.productType.isSubscriptionType {
            priceRows.append(contentsOf: [.subscriptionPeriod])
        }
        let priceSection = Section(title: Strings.priceSectionTitle, rows: priceRows)

        // Sales section
        var saleScheduleRows: [Row] = [.salePrice, .scheduleSale]
        if dateOnSaleStart != nil || dateOnSaleEnd != nil {
            saleScheduleRows.append(contentsOf: [.scheduleSaleFrom])
            if datePickerSaleFromVisible {
                saleScheduleRows.append(contentsOf: [.datePickerSaleFrom])
            }
            saleScheduleRows.append(contentsOf: [.scheduleSaleTo])
            if datePickerSaleToVisible {
                saleScheduleRows.append(contentsOf: [.datePickerSaleTo])
            }
            if dateOnSaleEnd != nil {
                saleScheduleRows.append(.removeSaleTo)
            }
        }
        let salesSection = Section(title: Strings.saleSectionTitle, rows: saleScheduleRows)

        switch product {
        case is EditableProductModel:
            // Tax section
            let taxSection: Section
            taxSection = Section(title: Strings.taxSectionTitle,
                                 rows: [.taxStatus, .taxClass])
            return [
                priceSection,
                salesSection,
                taxSection
            ]
        case is EditableProductVariationModel:
            return [
                priceSection,
                salesSection
            ]
        default:
            fatalError("Unsupported product type: \(product)")
        }
    }
}

extension ProductPriceSettingsViewModel: ProductPriceSettingsActionHandler {
    // MARK: - Initialization

    func retrieveProductTaxClass(completion: @escaping () -> Void) {
        let action = TaxAction.requestMissingTaxClasses(for: product) { [weak self] (taxClass, error) in
            self?.taxClass = taxClass ?? self?.standardTaxClass
            completion()
        }
        ServiceLocator.stores.dispatch(action)
    }

    // MARK: - Tap actions

    func didTapScheduleSaleFromRow() {
        datePickerSaleFromVisible = !datePickerSaleFromVisible
    }

    func didTapScheduleSaleToRow() {
        datePickerSaleToVisible = !datePickerSaleToVisible
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
        dateOnSaleStart = date.startOfDay(timezone: timezoneForScheduleSaleDates)

        if let dateOnSaleEnd = dateOnSaleEnd, dateOnSaleEnd < date {
            self.dateOnSaleEnd = date.endOfDay(timezone: timezoneForScheduleSaleDates)
        }
    }

    func handleSaleEndDateChange(_ date: Date?) {
        if date == nil {
            datePickerSaleToVisible = false
        }
        if let date = date, let dateOnSaleStart = dateOnSaleStart, date < dateOnSaleStart {
            return
        }
        else {
            self.dateOnSaleEnd = date?.endOfDay(timezone: self.timezoneForScheduleSaleDates)
        }
    }

    func handleSubscriptionPeriodChange(interval: String, period: SubscriptionPeriod) {
        let billingFrequency = {
            switch interval {
            case "1":
                return period.descriptionSingular
            default:
                return "\(interval) \(period.descriptionPlural)"
            }
        }()
        subscriptionPeriod = String.localizedStringWithFormat(Strings.subscriptionPeriodFormat, billingFrequency)
    }

    // MARK: - Navigation actions

    func completeUpdating(onCompletion: ProductPriceSettingsViewController.Completion, onError: (ProductPriceSettingsError) -> Void) {

        if let error = priceSettingsValidator.validate(regularPrice: regularPrice,
                                                       salePrice: salePrice,
                                                       dateOnSaleStart: dateOnSaleStart,
                                                       dateOnSaleEnd: dateOnSaleEnd) {
            onError(error)
            return
        }

        onCompletion(regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass, hasUnsavedChanges())
    }

    func hasUnsavedChanges() -> Bool {

        // Since an empty string and the standard tax class's slug both represent the standard tax class, the original and new
        // tax classes are converted to empty string whenever the value matches the standard tax class's slug.
        let newTaxClass = taxClass?.slug == standardTaxClass.slug ? "" : taxClass?.slug
        let originalTaxClass = product.taxClass == standardTaxClass.slug ? "": product.taxClass

        if priceSettingsValidator.getDecimalPrice(regularPrice) != priceSettingsValidator.getDecimalPrice(product.regularPrice) ||
            priceSettingsValidator.getDecimalPrice(salePrice) != priceSettingsValidator.getDecimalPrice(product.salePrice) ||
            dateOnSaleStart != originalDateOnSaleStart ||
            dateOnSaleEnd != product.dateOnSaleEnd ||
            taxStatus.rawValue != product.taxStatusKey ||
            newTaxClass != originalTaxClass ||
            subscriptionPeriod != product.subscriptionPeriodDescription {
            return true
        }

        return false
    }
}

extension ProductPriceSettingsViewModel {
    enum Strings {
        static let priceSectionTitle = NSLocalizedString("Price", comment: "Section header title for product price")
        static let saleSectionTitle = NSLocalizedString(
            "productPriceSettingsViewModel.saleSectionTitle",
            value: "Sale",
            comment: "Section header title for product sale price"
        )
        static let taxSectionTitle = NSLocalizedString("Tax Settings", comment: "Section header title for product tax settings")
        static let standardTaxClassName = NSLocalizedString("Standard rate", comment: "The name of the default Tax Class in Product Price Settings")
        static let subscriptionPeriodFormat = NSLocalizedString(
            "productPriceSettingsViewModel.subscriptionPeriodFormat",
            value: "every %1$@",
            comment: "Description of the subscription period for a product. " +
            "Reads like: 'every 2 months'."
        )
    }
}
