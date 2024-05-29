import WooFoundation
import Yosemite
import protocol Experiments.FeatureFlagService
import protocol Storage.StorageManagerType
import Combine

/// Use case to add, edit, or remove shipping lines on an order.
///
final class EditableOrderShippingLineUseCase: ObservableObject {
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

    init(siteID: Int64,
         flow: EditableOrderViewModel.Flow,
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
        self.orderSynchronizer = RemoteOrderSynchronizer(siteID: siteID, flow: flow, stores: stores, currencySettings: currencySettings)
        self.featureFlagService = featureFlagService

        configureNonEditableIndicators()
        configureShippingLineRowViewModels()
    }

    /// Returns a view model for adding a shipping line to an order.
    ///
    func addShippingLineViewModel() -> ShippingLineSelectionDetailsViewModel {
        return ShippingLineSelectionDetailsViewModel(siteID: siteID, shippingLine: nil, didSelectSave: saveShippingLine)
    }

    /// Saves a shipping line.
    ///
    /// - Parameter shippingLine: Optional shipping line object to save. `nil` will remove existing shipping line.
    func saveShippingLine(_ shippingLine: ShippingLine?) {
        orderSynchronizer.setShipping.send(shippingLine)

        if let shippingLine {
            analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodAdd(flow: flow.analyticsFlow, methodID: shippingLine.methodID ?? ""))
        } else {
            analytics.track(event: WooAnalyticsEvent.Orders.orderShippingMethodRemove(flow: flow.analyticsFlow))
        }
    }

    /// Tracks when the "Add shipping" button is tapped.
    ///
    func trackAddShippingTapped() {
        analytics.track(event: .Orders.orderAddShippingTapped())
    }
}

// MARK: Configuration

private extension EditableOrderShippingLineUseCase {
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
                                                                                     didSelectSave: saveShippingLine)
                    })
                }
            }
            .assign(to: &$shippingLineRows)
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
