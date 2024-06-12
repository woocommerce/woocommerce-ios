import SwiftUI
import WooFoundation
import Yosemite
import protocol Storage.StorageManagerType
import Combine

class ShippingLineSelectionDetailsViewModel: ObservableObject, Identifiable {
    private var siteID: Int64
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    /// Closure to be invoked when the shipping line is added or updated.
    ///
    var didSelectSave: ((ShippingLine) -> Void)

    /// Closure to be invoked when the shipping line is removed.
    ///
    var didSelectRemove: ((ShippingLine) -> Void)

    /// View model for the amount text field with currency symbol.
    ///
    let formattableAmountViewModel: FormattableAmountTextFieldViewModel

    /// Stores the method selected by the merchant.
    ///
    @Published var selectedMethod: ShippingMethod

    /// Text color for the selected method.
    ///
    var selectedMethodColor: Color {
        Color(selectedMethod.methodID == "" ? .placeholderText : .text)
    }

    /// Stores the method title entered by the merchant.
    ///
    @Published var methodTitle: String

    /// Method title entered by user or placeholder if it's empty.
    ///
    private var finalMethodTitle: String {
        methodTitle.isNotEmpty ? methodTitle : Localization.namePlaceholder
    }

    private let shippingID: Int64
    private let initialMethodID: String
    private let initialAmount: Decimal?
    private let initialMethodTitle: String

    /// Returns true when existing shipping line is edited.
    ///
    let isExistingShippingLine: Bool

    /// Shipping Method Results Controller.
    ///
    private lazy var shippingMethodResultsController: ResultsController<StorageShippingMethod> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "methodID", ascending: true)
        let resultsController = ResultsController<StorageShippingMethod>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
        return resultsController
    }()

    /// Placeholder shipping method, when no store shipping method is selected.
    ///
    private let placeholderMethod: ShippingMethod

    /// Available shipping methods on the store.
    ///
    var shippingMethods: [ShippingMethod] = []

    /// Returns true when there are valid pending changes.
    ///
    @Published var enableDoneButton: Bool = false

    init(siteID: Int64,
         shippingID: Int64?,
         initialMethodID: String,
         initialMethodTitle: String,
         shippingTotal: String,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         didSelectSave: @escaping ((ShippingLine) -> Void),
         didSelectRemove: @escaping ((ShippingLine) -> Void)) {
        self.siteID = siteID
        self.shippingID = shippingID ?? 0
        self.storageManager = storageManager
        self.analytics = analytics
        self.isExistingShippingLine = shippingID != nil
        self.initialMethodID = initialMethodID
        self.initialMethodTitle = initialMethodTitle
        self.methodTitle = initialMethodTitle
        placeholderMethod = ShippingMethod(siteID: siteID, methodID: "", title: Localization.placeholderMethodTitle)
        selectedMethod = placeholderMethod

        let currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        if isExistingShippingLine, let initialAmount = currencyFormatter.convertToDecimal(shippingTotal) {
            self.initialAmount = initialAmount as Decimal
        } else {
            self.initialAmount = nil
        }

        self.formattableAmountViewModel = FormattableAmountTextFieldViewModel(size: .title2,
                                                                              locale: locale,
                                                                              storeCurrencySettings: storeCurrencySettings,
                                                                              allowNegativeNumber: true)
        if isExistingShippingLine {
            formattableAmountViewModel.presetAmount(shippingTotal)
        }

        self.didSelectSave = didSelectSave
        self.didSelectRemove = didSelectRemove

        configureShippingMethods()
        observeShippingLineDetailsForUIStates(with: currencyFormatter)
    }

    convenience init(siteID: Int64,
                     shippingLine: ShippingLine?,
                     locale: Locale = Locale.autoupdatingCurrent,
                     storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
                     storageManager: StorageManagerType = ServiceLocator.storageManager,
                     analytics: Analytics = ServiceLocator.analytics,
                     didSelectSave: @escaping ((ShippingLine) -> Void),
                     didSelectRemove: @escaping ((ShippingLine) -> Void)) {
        self.init(siteID: siteID,
                  shippingID: shippingLine?.shippingID,
                  initialMethodID: shippingLine?.methodID ?? "",
                  initialMethodTitle: shippingLine?.methodTitle ?? "",
                  shippingTotal: shippingLine?.total ?? "",
                  locale: locale,
                  storeCurrencySettings: storeCurrencySettings,
                  storageManager: storageManager,
                  analytics: analytics,
                  didSelectSave: didSelectSave,
                  didSelectRemove: didSelectRemove)
    }

    func saveData() {
        let shippingLine = ShippingLine(shippingID: shippingID,
                                        methodTitle: finalMethodTitle,
                                        methodID: selectedMethod.methodID,
                                        total: formattableAmountViewModel.amount,
                                        totalTax: "",
                                        taxes: [])
        didSelectSave(shippingLine)
    }

    func removeShippingLine() {
        let shippingLine = ShippingLine(shippingID: shippingID,
                                        methodTitle: finalMethodTitle,
                                        methodID: selectedMethod.methodID,
                                        total: formattableAmountViewModel.amount,
                                        totalTax: "",
                                        taxes: [])
        didSelectRemove(shippingLine)
    }

    /// Tracks when a shipping method is selected
    ///
    func trackShippingMethodSelected(_ selectedMethod: ShippingMethod) {
        analytics.track(event: .Orders.orderShippingMethodSelected(methodID: selectedMethod.methodID))
    }
}

// MARK: Configuration

private extension ShippingLineSelectionDetailsViewModel {
    /// Observes changes to the shipping line method, amount, and method title to determine the state of the "Done" button.
    ///
    func observeShippingLineDetailsForUIStates(with currencyFormatter: CurrencyFormatter) {
        formattableAmountViewModel.$amount
            .combineLatest($methodTitle, $selectedMethod)
            .map { [weak self] (amount, methodTitle, selectedMethod) in
                guard let self, let amountDecimal = currencyFormatter.convertToDecimal(amount) as? Decimal else {
                    return false
                }
                let amountUpdated = amountDecimal != self.initialAmount
                let methodTitleUpdated = methodTitle != self.initialMethodTitle
                let methodUpdated = selectedMethod.methodID != self.initialMethodID
                return amountUpdated || methodTitleUpdated || methodUpdated
        }.assign(to: &$enableDoneButton)
    }

    /// Configures the available and selected shipping methods for display.
    ///
    func configureShippingMethods() {
        updateShippingMethodResultsController()
        initializeSelectedMethod()
    }

    /// Fetches shipping methods from storage.
    ///
    func updateShippingMethodResultsController() {
        do {
            try shippingMethodResultsController.performFetch()
            // The app previously set the shipping method ID to "other" when shipping was added in the app.
            // This option is not included in the remote list of shipping methods so we add it here.
            let otherMethod = ShippingMethod(siteID: siteID, methodID: "other", title: "Other")
            shippingMethods = [placeholderMethod] + shippingMethodResultsController.fetchedObjects + [otherMethod]
        } catch {
            DDLogError("⛔️ Error fetching shipping methods from storage: \(error)")
        }
    }

    /// Sets the initial selected method using the available shipping methods.
    ///
    func initializeSelectedMethod() {
        selectedMethod = shippingMethods.first(where: { $0.methodID == initialMethodID }) ?? placeholderMethod
    }
}

// MARK: Constants

extension ShippingLineSelectionDetailsViewModel {
    enum Localization {
        static let namePlaceholder = NSLocalizedString("order.shippingLineDetails.namePlaceholder",
                                                       value: "Shipping",
                                                       comment: "Placeholder for the name field on the Shipping Line Details screen in order form")
        static let placeholderMethodTitle = NSLocalizedString("order.shippingLineDetails.placeholderMethodTitle",
                                                              value: "N/A",
                                                              comment: "Title for the placeholder shipping method on the Shipping Line Details screen")
    }
}
