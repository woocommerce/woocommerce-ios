import Foundation
import Yosemite
import WooFoundation
import Combine
import struct Networking.WooShippingAccountSettings
import enum Networking.DotcomError
import protocol Storage.StorageManagerType

enum WooShippingCreateLabelSelection {
    case shipment(index: Int)
    case shippingLabel(label: ShippingLabel)

    var selectedShippingLabel: ShippingLabel? {
        switch self {
        case .shipment: nil
        case .shippingLabel(let label): label
        }
    }
}

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    enum ContentState {
        case loading
        case ready
        case missingRequiredData
    }

    private let order: Order
    private let shippingSettingsService: ShippingSettingsService
    private let itemsDataSource: WooShippingItemsDataSource
    private var destinationEmail: String?
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencySettings: CurrencySettings
    private var subscriptions: Set<AnyCancellable> = []
    private let initialNoticeDelay: RunLoop.SchedulerTimeType.Stride
    private let analytics: Analytics

    private(set) var orderItems: WooShippingItemsViewModel

    var canViewLabel: Bool {
        currentShipmentDetailsViewModel.canViewLabel
    }

    var postPurchase: WooShippingPostPurchaseViewModel? {
        currentShipmentDetailsViewModel.postPurchase
    }

    @Published private(set) var shipments: [Shipment] {
        didSet {
            updateShipmentDetailsViewModels()
        }
    }

    @Published var selectedShipmentIndex = 0 {
        didSet {
            observeHAZMATNotices()
            observeSelectedPackage()
            observeSelectedRates()
            observeShippingRates()
        }
    }

    var currentShipment: Shipment {
        shipments[selectedShipmentIndex]
    }

    var hasUnfulfilledShipments: Bool {
        shipments.contains(where: { $0.purchasedLabel == nil })
    }

    @Published var labelPurchaseErrorNotice: Notice?

    @Published private(set) var state = ContentState.loading

    @Published private(set) var shouldShowNotices = false

    /// View model for split shipments.
    private(set) var splitShipmentsViewModel: WooShippingSplitShipmentsViewModel

    private(set) var shipmentDetailViewModels: [WooShippingShipmentDetailsViewModel] = []

    var currentShipmentDetailsViewModel: WooShippingShipmentDetailsViewModel {
        shipmentDetailViewModels[selectedShipmentIndex]
    }

    /// View model for a list of origin addresses to ship from.
    private(set) var originAddresses = WooShippingOriginAddressListViewModel(addresses: [])

    /// Address to ship from (store address).
    @Published private var selectedOriginAddress: WooShippingOriginAddress?

    /// Address to ship to (customer address),
    @Published private var destinationAddress: WooShippingAddress?

    /// Whether the origin address is unverified.
    var isOriginAddressUnverified: Bool {
        selectedOriginAddress?.isVerified == false
    }

    /// Address to ship from (store address), formatted for display.
    @Published private(set) var originAddress: String = ""

    /// Address to ship from (store address), formatted for display and split into separate lines to allow additional formatting.
    var originAddressLines: [String]? {
        if let shippingLabel = currentShipmentDetailsViewModel.shippingLabel {
            shippingLabel.originAddress.formattedPostalAddress?.components(separatedBy: "\n")
        } else {
            originAddress.components(separatedBy: ", ")
        }
    }

    /// This property can be set to display a notice with the provided label about the origin address status.
    @Published var originAddressUnverifiedNoticeLabel: String?

    /// Address to ship to (customer address), formatted for display and split into separate lines to allow additional formatting.
    var destinationAddressLines: [String]? {
        if let shippingLabel = currentShipmentDetailsViewModel.shippingLabel {
            shippingLabel.destinationAddress.formattedPostalAddress?.components(separatedBy: "\n")
        } else {
            (destinationAddress?.formattedPostalAddress)?.components(separatedBy: ", ")
        }
    }

    /// Possible statuses for a Woo Shipping destination address.
    enum DestinationAddressStatus {
        case verified
        case unverified
        case missing
    }

    /// The current destination address status.
    @Published private(set) var destinationAddressStatus: DestinationAddressStatus?

    /// This property can be set to display a notice with the provided label about the destination address status.
    @Published var destinationAddressStatusNoticeLabel: String?

    /// This property can be set to display a notice with the provided label about the destination phone number.
    @Published var destinationPhoneNumberNoticeLabel: String?

    /// View model for address to edit.
    /// Setting this property will navigate to the address edit screen.
    @Published var addressToEdit: WooShippingEditAddressViewModel?

    /// Shipping lines for the order, with formatted amount.
    let shippingLines: [WooShipping_ShippingLineViewModel]

    /// Shipping rates for the purchased label, with formatted amount.
    @Published private(set) var shippingRates: [(title: String, amount: String)] = []

    /// Total cost of the shipping label, formatted for display.
    var totalCost: String? {
        currentShipmentDetailsViewModel.totalCost
    }

    private var isMissingStoreSettings: Bool {
        weightUnit.isEmpty && dimensionsUnit.isEmpty
    }

    /// Whether to mark the order as complete after the label is purchased.
    @Published var markOrderComplete: Bool = false

    /// If the purchase button should be enabled.
    var isPurchaseButtonEnabled: Bool {
        currentShipmentDetailsViewModel.isPurchaseButtonEnabled
    }

    /// If the label purchase is in progress.
    @Published private(set) var isPurchasingLabel: Bool = false

    /// Unit to use for weight measurements.
    @Published var weightUnit = ""

    /// Unit to use for dimensions measurements.
    @Published var dimensionsUnit = ""

    @Published var hazmatNotice: Notice?

    @Published var refundNotice: Notice?

    /// Selected package data for the shipping label.
    @Published private var selectedPackage: WooShippingPackageDataRepresentable?

    /// Selected shipment rate for the shipping label
    @Published private(set) var selectedRate: WooShippingSelectedRate?

    /// Closure to execute after the label is successfully purchased.
    let onLabelPurchase: ((_ markOrderComplete: Bool) -> Void)?

    @Published var showingPaymentMethods = false
    @Published private var paymentMethod: ShippingLabelPaymentMethod?
    @Published private(set) var paymentMethodLine: WooShippingPaymentMethodLine?

    private(set) var paymentMethodsViewModel: ShippingLabelPaymentMethodsViewModel?

    @Published var shouldShowUPSTermsAndConditions = false

    var upsTermsViewModel: UPSTermsViewModel? {
        guard let originAddress = selectedOriginAddress?.toWooShippingAddress() else {
            return nil
        }
        return UPSTermsViewModel(siteID: order.siteID, originAddress: originAddress)
    }

    let isOrderCompleted: Bool

    /// Shipments Results Controller.
    ///
    private lazy var shipmentResultsController: ResultsController<StorageWooShippingShipment> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageWooShippingShipment.index, ascending: true)

        return ResultsController<StorageWooShippingShipment>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Origin addresses Results Controller.
    ///
    private lazy var originAddressResultsController: ResultsController<StorageWooShippingOriginAddress> = {
        let predicate = NSPredicate(format: "siteID = %ld", self.order.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageWooShippingOriginAddress.id, ascending: true)

        return ResultsController<StorageWooShippingOriginAddress>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Shipping Label Account Settings ResultsController
    ///
    private lazy var accountSettingsResultsController: ResultsController<StorageShippingLabelAccountSettings> = {
        let predicate = NSPredicate(format: "siteID == %lld", order.siteID)
        return ResultsController<StorageShippingLabelAccountSettings>(
            storageManager: storageManager,
            matching: predicate,
            fetchLimit: 1,
            sortedBy: []
        )
    }()

    private let shipmentSplitting: ShipmentSplittingProviding

    /// Initialize the view model with or without an existing shipping label.
    init(order: Order,
         preselection: WooShippingCreateLabelSelection? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         shipmentSplitting: ShipmentSplittingProviding = ServiceLocator.siteFeatureProvider.current.shipmentSplitting,
         initialNoticeDelay: RunLoop.SchedulerTimeType.Stride = .seconds(2),
         onLabelPurchase: ((Bool) -> Void)? = nil) {
        self.order = order
        self.itemsDataSource = DefaultWooShippingItemsDataSource(
            order: order,
            storageManager: storageManager,
            stores: stores
        )
        self.orderItems = WooShippingItemsViewModel(dataSource: itemsDataSource)
        self.onLabelPurchase = onLabelPurchase
        self.currencySettings = currencySettings
        self.destinationEmail = order.shippingAddress?.email ?? order.billingAddress?.email
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0, currency: order.currency) })
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.shipmentSplitting = shipmentSplitting
        self.shippingSettingsService = shippingSettingsService
        self.weightUnit = shippingSettingsService.weightUnit ?? ""
        self.dimensionsUnit = shippingSettingsService.dimensionUnit ?? ""
        self.initialNoticeDelay = initialNoticeDelay
        self.isOrderCompleted = order.status == .completed

        let splitShipmentsViewModel = WooShippingSplitShipmentsViewModel(order: order,
                                                                         remoteShipments: [],
                                                                         items: itemsDataSource.items,
                                                                         stores: stores)
        self.splitShipmentsViewModel = splitShipmentsViewModel
        self.shipments = splitShipmentsViewModel.shipments

        if let label = preselection?.selectedShippingLabel {
            destinationAddressStatus = .verified
            destinationAddress = label.destinationAddress.toWooShippingAddress()
            originAddress = label.originAddress.formattedInlineAddress ?? ""
        } else {
            destinationAddress = getDestinationAddress(order: order, address: order.shippingAddress)
            loadDestinationAddress()
        }

        syncCountries()
        updateShipmentDetailsViewModels()
        observeSelectedOriginAddress()
        observeDestinationAddress()
        observeViewStates()
        observePaymentMethod()
        configureShipmentResultsController()
        configureOriginAddressResultsController()
        configureAccountSettingsResultsController()

        Task { @MainActor in
            await loadRequiredData()

            // After shipment configs are updated, shipments are updated with purchased label details.
            // Update the selected tab now by checking the initial selected shipment index if available.
            // Otherwise, compare the purchased labels with the initial selected label.
            switch preselection {
            case .shipment(let index):
                self.selectedShipmentIndex = index
            case .shippingLabel(let label):
                if let matchingIndex = shipments.firstIndex(where: { $0.purchasedLabel?.shippingLabelID == label.shippingLabelID }) {
                    self.selectedShipmentIndex = matchingIndex
                }
            case .none:
                break
            }
        }
    }

    @MainActor
    func loadRequiredData() async {
        state = .loading
        await withTaskGroup(of: Void.self) { group in
            /// Only load store options synchronously if no settings have been saved in storage yet.
            if isMissingStoreSettings {
                group.addTask {
                    await self.loadStoreOptions()
                }
            } else {
                /// load asynchronously to update the local storage and unblock UI
                stores.dispatch(WooShippingAction.loadAccountSettings(siteID: order.siteID, completion: { _ in }))
            }

            /// Only load origin addresses synchronously if no addresses have been saved in storage yet.
            if hasUnfulfilledShipments, originAddress.isEmpty {
                group.addTask {
                    await self.loadOriginAddresses()
                }
            } else if hasUnfulfilledShipments {
                /// load asynchronously to update the local storage and unblock UI
                stores.dispatch(WooShippingAction.loadOriginAddresses(siteID: order.siteID, completion: { _ in }))
            }
        }

        if isMissingStoreSettings ||
            (originAddress.isEmpty && hasUnfulfilledShipments) {
            state = .missingRequiredData
        } else {
            state = .ready
            let count = shipments.count(where: { $0.purchasedLabel == nil })
            analytics.track(event: .WooShipping.createShippingLabelFormShown(unfulfilledShipmentsCount: count))
        }
    }

    func updateShipments(_ shipments: [Shipment]) {
        self.selectedShipmentIndex = 0
        self.shipments = shipments
    }

    func didUpdateAccountSettings(_ accountSettings: ShippingLabelAccountSettings) {
        self.paymentMethod = accountSettings.paymentMethods.first(where: { $0.paymentMethodID == accountSettings.selectedPaymentMethodID })
        self.paymentMethodsViewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: accountSettings)
    }

    /// Purchases a shipping label with the provided label details and settings.
    @MainActor
    func purchaseLabel(shouldRefreshPackageAndRate: Bool) async {
        guard paymentMethod != nil else {
            showingPaymentMethods = true
            return
        }
        isPurchasingLabel = true
        labelPurchaseErrorNotice = nil

        do {
            if shouldRefreshPackageAndRate {
                try await currentShipmentDetailsViewModel.refreshPackagesAndShippingRates()
            }
            let markOrderComplete = isOrderCompleted ? nil : self.markOrderComplete
            try await currentShipmentDetailsViewModel.purchaseLabel(markOrderComplete: markOrderComplete)
        } catch let DotcomError.unknown(code, _, _) where code == Constants.missingUPSDAPTermsOfServiceAcceptance {
            shouldShowUPSTermsAndConditions = true
        } catch {
            if let phoneMessage = invalidPhoneNumberMessage(from: error) {
                labelPurchaseErrorNotice = Notice(
                    title: Localization.PhoneNumberError.title,
                    message: phoneMessage,
                    feedbackType: .error,
                    actionTitle: Localization.PhoneNumberError.editAddress
                ) { [weak self] in
                    self?.editDestinationAddress()
                }
            } else {
                labelPurchaseErrorNotice = Notice(
                    title: Localization.LabelPurchaseError.title,
                    message: Localization.LabelPurchaseError.message,
                    feedbackType: .error,
                    actionTitle: Localization.LabelPurchaseError.retry
                ) { [weak self] in
                    Task {
                        await self?.purchaseLabel(
                            shouldRefreshPackageAndRate: shouldRefreshPackageAndRate
                        )
                    }
                }
            }
            DDLogError("⛔️ Error purchasing shipping label: \(error)")
        }
        isPurchasingLabel = false
    }

    func editSelectedOriginAddress() {
        guard let selectedOriginAddress else {
            return
        }
        addressToEdit = WooShippingEditAddressViewModel(address: selectedOriginAddress, onAddressEdited: { [weak self] editedAddress in
            guard let self, let index = originAddresses.addresses.firstIndex(where: { $0.id == editedAddress.id }) else {
                return
            }
            var addresses = originAddresses.addresses
            addresses.remove(at: index)
            addresses.insert(editedAddress, at: index)
            self.selectedOriginAddress = editedAddress
            originAddresses = WooShippingOriginAddressListViewModel(addresses: addresses,
                                                                    selectedAddressID: editedAddress.id)
            originAddresses.onSelect = { [weak self] selectedAddress in
                self?.selectedOriginAddress = selectedAddress
            }
            addressToEdit = nil // Dismisses address edit screen
        })
    }

    /// Sets the `addressToEdit` property for editing the destination address.
    /// After the address is edited, the destination address is replaced with the updated address.
    func editDestinationAddress() {
        addressToEdit = WooShippingEditAddressViewModel(address: destinationAddress,
                                                        orderID: order.orderID,
                                                        email: destinationEmail,
                                                        isVerified: destinationAddressStatus == .verified,
                                                        originCountryCode: selectedOriginAddress?.country,
                                                        originStateCode: selectedOriginAddress?.state,
                                                        onAddressEdited: { [weak self] result, editedEmail in
            guard let self else {
                return
            }
            destinationAddress = result.address.toWooShippingAddress()
            destinationEmail = editedEmail
            destinationAddressStatus = result.isVerified ? .verified : .unverified
            addressToEdit = nil // Dismisses address edit screen
        })
    }
}

// MARK: Remote
private extension WooShippingCreateLabelsViewModel {

    /// Updates store options (weight and dimensions units) with remote settings or fall back to cache results if failed.
    @MainActor
    func loadStoreOptions() async {
        let settings: WooShippingAccountSettings? = await withCheckedContinuation { continuation in
            let action = WooShippingAction.loadAccountSettings(siteID: order.siteID) { result in
                switch result {
                case .success(let settings):
                    continuation.resume(returning: settings)
                case .failure(let error):
                    DDLogError("⛔️ Error loading account settings: \(error)")
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
        }
        weightUnit = settings?.storeOptions.weightUnit ?? shippingSettingsService.weightUnit ?? ""
        dimensionsUnit = settings?.storeOptions.dimensionUnit ?? shippingSettingsService.dimensionUnit ?? ""
        updateAccountSettings(accountSettings: settings?.accountSettings)
    }

    /// Syncs origin addresses to use for shipping label from remote.
    ///
    @MainActor
    func loadOriginAddresses() async {
        let addresses = await withCheckedContinuation { continuation in
            let action = WooShippingAction.loadOriginAddresses(siteID: order.siteID) { result in
                switch result {
                case .success(let addresses):
                    continuation.resume(returning: addresses)
                case .failure(let error):
                    DDLogError("⛔️ Error loading origin addresses for Woo Shipping labels: \(error)")
                    continuation.resume(returning: [])
                }
            }
            stores.dispatch(action)
        }
        updateSelectedOriginAddress(addresses: addresses)
    }

    /// Loads destination address of the order from remote.
    ///
    func loadDestinationAddress() {
        let action = WooShippingAction.verifyDestinationAddress(siteID: order.siteID,
                                                                orderID: order.orderID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let address):
                destinationAddress = address.normalizedAddress.toWooShippingAddress()
                destinationAddressStatus = address.isVerified ? .verified : .unverified
            case .failure(let error):
                DDLogError("⛔️ Error loading destination addresses for Woo Shipping labels: \(error)")

                if let orderShippingAddress = getDestinationAddress(order: order, address: order.shippingAddress) {
                    destinationAddress = orderShippingAddress
                    destinationAddressStatus = destinationAddressLines == nil ? .missing : .unverified
                } else {
                    destinationAddressStatus = .missing
                }
            }
        }
        stores.dispatch(action)
    }

    /// Sync countries to update the storage with latest data from remote.
    /// This is useful for checking countries in the customs form and listing countries in the edit address form.
    func syncCountries() {
        stores.dispatch(DataAction.synchronizeCountries(siteID: order.siteID) { _ in })
    }
}

// MARK: Split Shipments
// Accessors describing Split Shipments elements availability
extension WooShippingCreateLabelsViewModel {
    private var hasMultipleProducts: Bool {
        return itemsDataSource.items.map(\.quantity).reduce(0, +) > 1
    }

    private var splitShipmentsFeatureAvailable: Bool {
        shipmentSplitting.isSplitShipmentsEnabled
    }

    /// Determines if the "Edit split shipments" (pencil icon) is visible in top shipments bar.
    var editSplitShipmentsOptionVisible: Bool {
        splitShipmentsFeatureAvailable &&
        hasMultipleProducts &&
        hasUnfulfilledShipments
    }

    /// Determines if the "Split Shipments" row is visible above the "Products" section
    var splitShipmentsRowVisible: Bool {
        splitShipmentsFeatureAvailable &&
        hasMultipleProducts &&
        shipments.count == 1 &&
        canViewLabel == false
    }
}

// MARK: Utils
private extension WooShippingCreateLabelsViewModel {

    func observeHAZMATNotices() {
        currentShipmentDetailsViewModel.$hazmatNotice
            .assign(to: &$hazmatNotice)
    }

    func observeSelectedPackage() {
        currentShipmentDetailsViewModel.$selectedPackage
            .assign(to: &$selectedPackage)
    }

    func observeSelectedRates() {
        currentShipmentDetailsViewModel.$selectedRate
            .assign(to: &$selectedRate)
    }

    func observeShippingRates() {
        currentShipmentDetailsViewModel.$shippingRates
            .assign(to: &$shippingRates)
    }

    func updateShipmentDetailsViewModels() {
        shipmentDetailViewModels = shipments.map { shipment in
            let originAddressPublisher = $selectedOriginAddress
                .map { $0?.toWooShippingAddress() }
                .eraseToAnyPublisher()
            return WooShippingShipmentDetailsViewModel(
                order: order,
                shipment: shipment,
                shippingLabel: shipment.purchasedLabel,
                originAddress: originAddressPublisher,
                destinationAddress: $destinationAddress.eraseToAnyPublisher(),
                stores: stores,
                onLabelPurchase: { [weak self] newLabel in
                    self?.handleLabelPurchaseSuccess(newLabel: newLabel, in: shipment)
                }, onLabelRefund: { [weak self] labelID in
                    self?.handleLabelRefundRequested(labelID: labelID, in: shipment)
                })
        }
        observeHAZMATNotices()
        observeSelectedPackage()
        observeSelectedRates()
        observeShippingRates()
    }

    func handleLabelPurchaseSuccess(newLabel: ShippingLabel, in shipment: Shipment) {
        let index = shipment.index
        shipments[index] = Shipment(index: index,
                                    contents: shipment.contents,
                                    purchasedLabel: newLabel,
                                    currency: order.currency,
                                    currencySettings: currencySettings,
                                    shippingSettingsService: shippingSettingsService)
        splitShipmentsViewModel.didPurchaseLabel(for: index, label: newLabel)
        onLabelPurchase?(markOrderComplete)
    }

    func handleLabelRefundRequested(labelID: Int64,
                                    in shipment: Shipment) {
        let shipmentIndex = shipment.index
        shipments[shipmentIndex] = Shipment(index: shipmentIndex,
                                            contents: shipment.contents,
                                            purchasedLabel: nil,
                                            currency: order.currency,
                                            currencySettings: currencySettings,
                                            shippingSettingsService: shippingSettingsService)
        splitShipmentsViewModel.didRequestRefund(for: shipmentIndex)
        refundNotice = Notice(message: Localization.refundNotice)
    }

    /// Observes the selected origin address and updates the displayed origin address and shipping service.
    func observeSelectedOriginAddress() {
        $selectedOriginAddress
            .sink { [weak self] selectedOriginAddress in
                guard let self else { return }
                originAddress = selectedOriginAddress?.formattedPostalAddress ?? ""
                originAddressUnverifiedNoticeLabel = {
                    if let selectedOriginAddress, !selectedOriginAddress.isVerified {
                        return Localization.OriginAddressStatus.unverified
                    }
                    return nil
                }()
            }
            .store(in: &subscriptions)
    }

    /// Observes the destination address to update UI and shipping service.
    func observeDestinationAddress() {
        /// Set the notice when the destination address status changes.
        $destinationAddressStatus
            .compactMap { $0 }
            .map { status in
                switch status {
                case .verified:
                    return Localization.DestinationAddressStatus.verified
                case .unverified:
                    return Localization.DestinationAddressStatus.unverified
                case .missing:
                    return Localization.DestinationAddressStatus.missing
                }
            }
            .assign(to: &$destinationAddressStatusNoticeLabel)

        $destinationAddress
            .map { [weak self] address -> String? in
                return self?.destinationPhoneNoticeLabel(for: address)
            }
            .assign(to: &$destinationPhoneNumberNoticeLabel)

        /// Clear the notice after a delay when the address is verified.
        $shouldShowNotices
            .combineLatest($destinationAddressStatusNoticeLabel)
            .filter { shouldShowNotices, destinationNotice in
                shouldShowNotices && destinationNotice == Localization.DestinationAddressStatus.verified
            }
            .delay(for: .seconds(2), scheduler: RunLoop.current)
            .map { _ in nil }
            .assign(to: &$destinationAddressStatusNoticeLabel)
    }

    func destinationPhoneNoticeLabel(for address: WooShippingAddress?) -> String? {
        guard let address else {
            return nil
        }
        if address.phoneDigits.isEmpty {
            return Localization.DestinationPhoneNumber.missing
        }
        if !address.hasValidPhoneNumberForShipping {
            return Localization.DestinationPhoneNumber.invalid
        }
        return nil
    }

    /// Ensures that initial notices are only displayed after the view is ready
    /// to avoid overwhelming users with too many information at once when opening the screen.
    func observeViewStates() {
        $state
            .filter { $0 == .ready }
            .delay(for: initialNoticeDelay, scheduler: RunLoop.current)
            .combineLatest($shipments, $selectedShipmentIndex)
            .map { _, shipments, selectedIndex in
                shipments[selectedIndex].isPurchased == false
            }
            .assign(to: &$shouldShowNotices)
    }

    /// Gets the destination address as a `ShippingLabelAddress`.
    /// The order's billing phone is used as a fallback if there is no shipping phone.
    ///
    func getDestinationAddress(order: Order, address: Address?) -> WooShippingAddress? {
        guard let phone = address?.phone, phone.isNotEmpty else {
            let destinationAddress = address?.copy(phone: order.billingAddress?.phone)
            return destinationAddress?.toWooShippingAddress()
        }
        return address?.toWooShippingAddress()
    }

    func observePaymentMethod() {
        $paymentMethod
            .combineLatest($shipments, $selectedShipmentIndex)
            .map { paymentMethod, shipments, selectedIndex -> WooShippingPaymentMethodLine? in
                if shipments[selectedIndex].isPurchased {
                    return nil
                }

                guard let paymentMethod else {
                    return .add
                }

                return WooShippingPaymentMethodLine.cardLineWithPaymentMethod(
                    paymentMethod,
                    isEditable: true
                )
            }
            .assign(to: &$paymentMethodLine)
    }

    func setupPaymentMethod(accountSettings: ShippingLabelAccountSettings?) {
        self.paymentMethod = accountSettings?.paymentMethods.first {
            return $0.paymentMethodID == accountSettings?.selectedPaymentMethodID
        }
    }

    func configureShipmentResultsController() {
        let reloadShipments = { [weak self] in
            guard let self else { return }
            let fetchedShipments = shipmentResultsController.fetchedObjects
            splitShipmentsViewModel = WooShippingSplitShipmentsViewModel(order: order,
                                                                         remoteShipments: fetchedShipments,
                                                                         items: itemsDataSource.items,
                                                                         stores: stores)
            shipments = splitShipmentsViewModel.shipments
        }

        shipmentResultsController.onDidChangeContent = {
            reloadShipments()
        }

        shipmentResultsController.onDidResetContent = {
            reloadShipments()
        }

        do {
            try shipmentResultsController.performFetch()
            reloadShipments()
        } catch {
            DDLogError("⛔️ Unable to fetch shipments: \(error)")
        }
    }

    func configureOriginAddressResultsController() {
        let updateSelectedAddress = { [weak self] in
            guard let self else { return }
            let addresses = originAddressResultsController.fetchedObjects
            updateSelectedOriginAddress(addresses: addresses)
        }
        originAddressResultsController.onDidChangeContent = {
            updateSelectedAddress()
        }

        originAddressResultsController.onDidResetContent = {
            updateSelectedAddress()
        }

        do {
            try originAddressResultsController.performFetch()
            updateSelectedAddress()
        } catch {
            DDLogError("⛔️ Unable to fetch origin addresses: \(error)")
        }
    }

    func updateSelectedOriginAddress(addresses: [WooShippingOriginAddress]) {
        selectedOriginAddress = addresses.first(where: \.defaultAddress)
        originAddresses = WooShippingOriginAddressListViewModel(addresses: addresses,
                                                                selectedAddressID: selectedOriginAddress?.id)
        originAddresses.onSelect = { [weak self] selectedAddress in
            self?.selectedOriginAddress = selectedAddress
        }
    }

    /// Shipping Label Account Settings ResultsController monitoring
    ///
    func configureAccountSettingsResultsController() {
        let updateSettings = { [weak self] in
            guard let self else { return }
            let settings = accountSettingsResultsController.fetchedObjects.first
            updateAccountSettings(accountSettings: settings)
        }
        accountSettingsResultsController.onDidChangeContent = {
            updateSettings()
        }

        accountSettingsResultsController.onDidResetContent = {
            updateSettings()
        }

        do {
            try accountSettingsResultsController.performFetch()
            updateSettings()
        } catch {
            DDLogError("⛔️ Unable to fetch woo shipping account settings: \(error)")
        }
    }

    func updateAccountSettings(accountSettings: ShippingLabelAccountSettings?) {
        markOrderComplete = accountSettings?.lastOrderCompleted ?? false

        if let accountSettings {
            paymentMethodsViewModel = ShippingLabelPaymentMethodsViewModel(accountSettings: accountSettings)
        }
        setupPaymentMethod(accountSettings: accountSettings)
    }
}

private extension WooShippingCreateLabelsViewModel {
    enum Constants {
        static let missingUPSDAPTermsOfServiceAcceptance = "missing_upsdap_terms_of_service_acceptance"
        static let serverErrorResponse = "wcc_server_error_response"
    }
    enum Localization {
        enum OriginAddressStatus {
            static let unverified = NSLocalizedString(
                "wooShipping.createLabels.addressVerification.originUnverified",
                value: "Origin address unverified",
                comment: "Notice when a origin address is unverified on the shipping label creation screen"
            )
        }

        enum DestinationAddressStatus {
            static let verified = NSLocalizedString("wooShipping.createLabels.addressVerification.destinationVerified",
                                                               value: "Verified destination address",
                                                               comment: "Notice when a destination address is verified on the shipping label creation screen")
            static let unverified = NSLocalizedString("wooShipping.createLabels.addressVerification.destinationUnverified",
                                                                 value: "Destination address unverified",
                                                                 comment: "Notice when a destination address is unverified on the shipping label creation screen")
            static let missing = NSLocalizedString("wooShipping.createLabels.addressVerification.destinationMissing",
                                                              value: "Destination address missing",
                                                              comment: "Notice when a destination address is missing on the shipping label creation screen")
        }

        enum LabelPurchaseError {
            static let title = NSLocalizedString("wooShipping.createLabels.labelPurchaseError.title",
                                                   value: "Error purchasing shipping label.",
                                                   comment: "Title of the notice when purchasing a shipping label fails")
            static let message = NSLocalizedString("wooShipping.createLabels.labelPurchaseError.message",
                                                   value: "We are unable to purchase the shipping label. Please try again.",
                                                   comment: "Message in the notice when purchasing a shipping label fails")
            static let retry = NSLocalizedString("wooShipping.createLabels.labelPurchaseError.retry",
                                                   value: "Retry",
                                                   comment: "Button to retry label purchase when an error occurs")
        }

        enum DestinationPhoneNumber {
            static let missing = NSLocalizedString(
                "wooShipping.createLabels.destinationPhoneNumber.missing",
                value: "Phone number is required for the destination address.",
                comment: "Notice when the destination phone number is missing on the shipping label creation screen"
            )
            static let invalid = NSLocalizedString(
                "wooShipping.createLabels.destinationPhoneNumber.invalid",
                value: "Please enter a valid phone number for the destination address.",
                comment: "Notice when the destination phone number is invalid"
            )
        }

        enum PhoneNumberError {
            static let title = NSLocalizedString(
                "wooShipping.createLabels.phoneNumberError.title",
                value: "Invalid phone number.",
                comment: "Title for the notice when the label purchase fails due to an invalid destination phone number"
            )
            static let message = NSLocalizedString(
                "wooShipping.createLabels.phoneNumberError.message",
                value: "Please enter a valid phone number for the destination address.",
                comment: "Message for the notice when the label purchase fails due to an invalid destination phone number"
            )
            static let editAddress = NSLocalizedString(
                "wooShipping.createLabels.phoneNumberError.editAddress",
                value: "Edit address",
                comment: "Action button title to edit the destination address when phone number is invalid"
            )
        }

        static let refundNotice = NSLocalizedString(
            "wooShipping.createLabels.refundNotice",
            value: "You have successfully submitted a request for refund. You can purchase a new label.",
            comment: "Notice to display after requesting refund for a shipping label"
        )
    }
}

private extension WooShippingCreateLabelsViewModel {
    func invalidPhoneNumberMessage(from error: Error) -> String? {
        guard case let DotcomError.unknown(code, message, data) = error,
              code == Constants.serverErrorResponse else {
            return nil
        }
        let dataMessage = data?["message"]?.value as? String
        let candidates = [message, dataMessage].compactMap { $0 }
        guard candidates.contains(where: { $0.range(of: "phone", options: .caseInsensitive) != nil }) else {
            return nil
        }
        return Localization.PhoneNumberError.message
    }
}

extension WooShippingOriginAddress {
    /// Converts the origin address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use in e.g. fetching available shipping rates or purchasing the label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        WooShippingAddress(company: company,
                           name: fullName,
                           email: email,
                           phone: phone,
                           country: country,
                           state: state,
                           address1: address1,
                           address2: address2,
                           city: city,
                           postcode: postcode)
    }
}

private extension ShippingLabelAddress {
    /// Converts the address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use as a destination address in the shipping label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        WooShippingAddress(company: company,
                           name: name,
                           email: nil, // ignoring as we don't display email on UI for purchased labels
                           phone: phone,
                           country: country,
                           state: state,
                           address1: address1,
                           address2: address2,
                           city: city,
                           postcode: postcode)
    }
}

private extension Address {
    /// Converts the address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use as a destination address in the shipping label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        return WooShippingAddress(company: company ?? "",
                                  name: fullName,
                                  email: email,
                                  phone: phone ?? "",
                                  country: country,
                                  state: state,
                                  address1: address1,
                                  address2: address2 ?? "",
                                  city: city,
                                  postcode: postcode)
    }
}
