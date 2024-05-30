import WooFoundation
import Yosemite
import protocol Experiments.FeatureFlagService
import protocol Storage.StorageManagerType
import Combine

/// Use case to add, edit, or remove shipping lines on an order.
///
final class EditableOrderShippingUseCase: ObservableObject {
    private var siteID: Int64
    private var analytics: Analytics
    private var featureFlagService: FeatureFlagService
    private var storageManager: StorageManagerType
    private var stores: StoresManager
    private var orderSynchronizer: OrderSynchronizer

    /// Current flow. For editing stores existing order state prior to applying any edits.
    ///
    private var flow: EditableOrderViewModel.Flow

    /// Defines if the non editable indicators (banners, locks, fields) should be shown.
    ///
    @Published private(set) var shouldShowNonEditableIndicators: Bool = false

    /// Multiple shipping lines support
    ///
    var multipleShippingLinesEnabled: Bool {
        featureFlagService.isFeatureFlagEnabled(.multipleShippingLines)
    }

    // MARK: View models

    /// View models for each shipping line in the order.
    ///
    @Published private(set) var shippingLineRows: [ShippingLineRowViewModel] = []

    /// View model to edit a selected shipping line.
    ///
    @Published var selectedShippingLine: ShippingLineSelectionDetailsViewModel? = nil

    // MARK: Shipping methods

    /// Shipping Methods Results Controller.
    ///
    private lazy var shippingMethodsResultsController: ResultsController<StorageShippingMethod> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageShippingMethod>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// All shipping methods for the store.
    ///
    private var allShippingMethods: [ShippingMethod] = []

    // MARK: Payment data

    /// Payment data related to shipping lines.
    ///
    @Published var paymentData = ShippingPaymentData()

    struct ShippingPaymentData {
        // We show shipping total if there are shipping lines
        let shouldShowShippingTotal: Bool
        let shippingTotal: String

        // We show shipping tax if the amount is not zero
        let shouldShowShippingTax: Bool
        let shippingTax: String

        // We only support one (the first) shipping line when the multipleShippingLines feature flag is disabled
        // In that case we need the shipping line details so it can be edited from the order totals section
        let isShippingTotalEditable: Bool
        let siteID: Int64
        let shippingID: Int64?
        let shippingMethodID: String
        let shippingMethodTitle: String
        let shippingMethodTotal: String
        let saveShippingLineClosure: (ShippingLine) -> Void
        let removeShippingLineClosure: (ShippingLine) -> Void
        var shippingLineViewModel: ShippingLineDetailsViewModel {
            ShippingLineDetailsViewModel(shippingID: shippingID,
                                         initialMethodTitle: shippingMethodTitle,
                                         shippingTotal: shippingMethodTotal,
                                         didSelectSave: saveShippingLineClosure,
                                         didSelectRemove: removeShippingLineClosure)
        }
        var shippingLineSelectionViewModel: ShippingLineSelectionDetailsViewModel {
            ShippingLineSelectionDetailsViewModel(siteID: siteID,
                                                  shippingID: shippingID,
                                                  initialMethodID: shippingMethodID,
                                                  initialMethodTitle: shippingMethodTitle,
                                                  shippingTotal: shippingMethodTotal,
                                                  didSelectSave: saveShippingLineClosure,
                                                  didSelectRemove: removeShippingLineClosure)
        }

        init(siteID: Int64 = 0,
             shouldShowShippingTotal: Bool = false,
             shippingTotal: String = "0",
             isShippingTotalEditable: Bool = true,
             shippingID: Int64? = nil,
             shippingMethodID: String = "",
             shippingMethodTitle: String = "",
             shippingMethodTotal: String = "",
             shippingTax: String = "0",
             saveShippingLineClosure: @escaping (ShippingLine) -> Void = { _ in },
             removeShippingLineClosure: @escaping (ShippingLine) -> Void = { _ in },
             currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)) {
            self.siteID = siteID
            self.shouldShowShippingTotal = shouldShowShippingTotal
            self.shippingTotal = currencyFormatter.formatAmount(shippingTotal) ?? "0.00"
            self.isShippingTotalEditable = isShippingTotalEditable
            self.shippingID = shippingID
            self.shippingMethodID = shippingMethodID
            self.shippingMethodTitle = shippingMethodTitle
            self.shippingMethodTotal = currencyFormatter.formatAmount(shippingMethodTotal) ?? "0.00"
            self.shouldShowShippingTax = !(currencyFormatter.convertToDecimal(shippingTax) ?? NSDecimalNumber(0.0)).isZero()
            self.shippingTax = currencyFormatter.formatAmount(shippingTax) ?? "0.00"
            self.saveShippingLineClosure = saveShippingLineClosure
            self.removeShippingLineClosure = removeShippingLineClosure
        }
    }

    init(siteID: Int64,
         flow: EditableOrderViewModel.Flow,
         orderSynchronizer: OrderSynchronizer,
         analytics: Analytics = ServiceLocator.analytics,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.flow = flow
        self.analytics = analytics
        self.storageManager = storageManager
        self.stores = stores
        self.orderSynchronizer = orderSynchronizer
        self.featureFlagService = featureFlagService

        configurePaymentData()
        configureNonEditableIndicators()
        configureShippingLineRowViewModels()
    }

    /// Returns a view model for adding a shipping line to an order.
    ///
    func addShippingLineViewModel() -> ShippingLineSelectionDetailsViewModel {
        return ShippingLineSelectionDetailsViewModel(siteID: siteID, shippingLine: nil, didSelectSave: saveShippingLine, didSelectRemove: removeShippingLine)
    }

    /// Saves a shipping line.
    ///
    /// - Parameter shippingLine: New or updated shipping line object to save.
    func saveShippingLine(_ shippingLine: ShippingLine) {
        orderSynchronizer.setShipping.send(shippingLine)
        analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodAdd(flow: flow.analyticsFlow,
                                                                               methodID: shippingLine.methodID ?? "",
                                                                               shippingLinesCount: Int64(orderSynchronizer.order.shippingLines.count)))
    }

    /// Removes a shipping line.
    ///
    /// - Parameter shippingLine: Shipping line object to remove.
    func removeShippingLine(_ shippingLine: ShippingLine) {
        orderSynchronizer.removeShipping.send(shippingLine)
        analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodRemove(flow: flow.analyticsFlow))
    }

    /// Tracks when the "Add shipping" button is tapped.
    ///
    func trackAddShippingTapped() {
        analytics.track(event: .Orders.orderAddShippingTapped())
    }
}

// MARK: Configuration

private extension EditableOrderShippingUseCase {
    /// Binds the order state to the `shouldShowNonEditableIndicators` property.
    ///
    func configureNonEditableIndicators() {
        Publishers.CombineLatest(orderSynchronizer.orderPublisher, Just(flow))
            .map { order, flow in
                switch flow {
                case .creation:
                    return false
                case .editing:
                    return !order.isEditable
                }
            }
            .assign(to: &$shouldShowNonEditableIndicators)
    }

    /// Configures row view models for each shipping line on the order.
    ///
    func configureShippingLineRowViewModels() {
        updateShippingMethodsResultsController()
        syncShippingMethods()

        guard multipleShippingLinesEnabled else {
            return
        }

        orderSynchronizer.orderPublisher
            .map { $0.shippingLines }
            .removeDuplicates()
            .combineLatest($shouldShowNonEditableIndicators)
            .map { [weak self] (shippingLines, isNonEditable) -> [ShippingLineRowViewModel] in
                guard let self else { return [] }
                return shippingLines.compactMap { shippingLine in
                    guard !shippingLine.isDeleted else { return nil }

                    return ShippingLineRowViewModel(shippingLine: shippingLine,
                                                    shippingMethods: self.allShippingMethods,
                                                    editable: !isNonEditable,
                                                    onEditShippingLine: { [weak self] shippingID in
                        guard let self else {
                            return
                        }
                        selectedShippingLine = ShippingLineSelectionDetailsViewModel(siteID: siteID,
                                                                                     shippingID: shippingLine.shippingID,
                                                                                     initialMethodID: shippingLine.methodID ?? "",
                                                                                     initialMethodTitle: shippingLine.methodTitle,
                                                                                     shippingTotal: shippingLine.total,
                                                                                     didSelectSave: saveShippingLine,
                                                                                     didSelectRemove: removeShippingLine)
                    })
                }
            }
            .assign(to: &$shippingLineRows)
    }

    /// Configures the payment data relates to shipping lines.
    ///
    func configurePaymentData() {
        orderSynchronizer.orderPublisher
            .map { [weak self] order in
                guard let self else { return ShippingPaymentData() }

                // The first shipping line in the order (used if multiple shipping lines are not supported)
                let shippingLine = order.shippingLines.first

                return ShippingPaymentData(siteID: siteID,
                                           shouldShowShippingTotal: order.shippingLines.filter { $0.methodID != nil }.isNotEmpty,
                                           shippingTotal: order.shippingTotal.isNotEmpty ? order.shippingTotal : "0",
                                           isShippingTotalEditable: !multipleShippingLinesEnabled,
                                           shippingID: shippingLine?.shippingID,
                                           shippingMethodID: shippingLine?.methodID ?? "",
                                           shippingMethodTitle: shippingLine?.methodTitle ?? "",
                                           shippingMethodTotal: order.shippingLines.first?.total ?? "0",
                                           shippingTax: order.shippingTax.isNotEmpty ? order.shippingTax : "0",
                                           saveShippingLineClosure: saveShippingLine,
                                           removeShippingLineClosure: removeShippingLine)
            }
            .assign(to: &$paymentData)
    }

    /// Updates `allShippingMethods` from storage.
    ///
    func updateShippingMethodsResultsController() {
        do {
            try shippingMethodsResultsController.performFetch()
            allShippingMethods = shippingMethodsResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Error fetching shipping methods for order: \(error)")
        }
    }

    /// Synchronizes available shipping methods for editing the order shipping lines.
    ///
    func syncShippingMethods() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.orderShippingMethodSelection) else {
            return
        }
        let action = ShippingMethodAction.synchronizeShippingMethods(siteID: siteID) { [weak self] result in
            switch result {
            case .success:
                self?.updateShippingMethodsResultsController()
            case let .failure(error):
                DDLogError("⛔️ Error retrieving available shipping methods: \(error)")
            }
        }
        stores.dispatch(action)
    }
}
