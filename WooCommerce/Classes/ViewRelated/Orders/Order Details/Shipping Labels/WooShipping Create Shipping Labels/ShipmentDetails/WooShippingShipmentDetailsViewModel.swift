import Foundation
import ParcelFittingCheck
import Yosemite
import WooFoundation
import Combine
import protocol Storage.StorageManagerType

final class WooShippingShipmentDetailsViewModel: ObservableObject, ParcelFittingDelegate {

    private let order: Order
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let onLabelPurchase: ((ShippingLabel) -> Void)?
    private let onLabelRefund: ((Int64) -> Void)?
    private var subscriptions: Set<AnyCancellable> = []
    private let analytics: Analytics

    @Published var hazmatCategory: ShippingLabelHazmatCategory?
    @Published private(set) var hazmatNotice: Notice?

    /// The purchased shipping label.
    @Published private(set) var shippingLabel: ShippingLabel?

    /// View model for the section displayed after a shipping label is purchased.
    @Published private(set) var postPurchase: WooShippingPostPurchaseViewModel?

    /// Whether a purchased shipping label can be viewed (and printed, tracked, refunded, etc.).
    var canViewLabel: Bool {
        shippingLabel != nil
    }

    let shipment: Shipment

    var itemsCountLabel: String {
        shipment.quantity
    }

    var itemsDetailLabel: String {
        shipment.itemsDetailLabel
    }

    var itemsRowViewModels: [WooShippingItemRowViewModel] {
        shipment.items.map {
            WooShippingItemRowViewModel(item: $0, currency: order.currency)
        }
    }

    /// Address to ship from (store address).
    @Published private var originAddress: WooShippingAddress?

    /// Address to ship to (customer address),
    @Published private var destinationAddress: WooShippingAddress?

    /// Selected package data for the shipping label.
    @Published private(set) var selectedPackage: WooShippingPackageDataRepresentable?

    /// Cached AR state from the last unified AR flow, if used.
    private(set) var lastARMeasurement: ParcelDimensions?
    private(set) var lastARCarriers: [ParcelPresetCarrier] = []
    private(set) var lastARStarredPackageIDs: Set<String> = []
    private(set) var lastARDimensionUnit: UnitLength = .centimeters

    /// String representing the total weight for the shipment.
    @Published var shipmentWeight: String = ""

    /// View model for the label shipping service.
    @Published private(set) var shippingService: WooShippingServiceViewModel?

    /// Selected shipping rate when creating a shipping label.
    @Published private(set) var selectedRate: WooShippingSelectedRate?

    @Published private var customsForm: ShippingLabelCustomsForm?

    lazy private(set) var customsFormViewModel: WooShippingCustomsFormViewModel = {
        return WooShippingCustomsFormViewModel(
            order: order,
            shipment: shipment,
            originCountryCode: originCountryCodePublisher(),
            isHSTariffNumberRequired: isHSTariffNumberRequiredPublisher(),
            storageManager: storageManager
        ) { [weak self] form in
            self?.customsForm = form
        }
    }()

    /// Whether the custom information is completed or not.
    @Published private(set) var customsInformationIsCompleted = false

    /// Check for the need of customs form
    ///
    @Published private var customsFormRequired = false

    var shouldShowCustomsForm: Bool {
        customsFormRequired && shippingLabel == nil
    }

    @Published var itnMissingNoticeLabel: String?

    /// Total cost of the shipping label, formatted for display.
    var totalCost: String? {
        guard let amount = shippingLabel?.rate ?? selectedRate?.totalRate else {
            return nil
        }
        return currencyFormatter.formatAmount(Decimal(amount))
    }

    /// If the purchase button should be enabled.
    var isPurchaseButtonEnabled: Bool {
        // Don't allow purchasing if a label is already purchased
        shippingLabel == nil
        // or if any required fields are missing
        && originAddress != nil && destinationAddress != nil
        && destinationAddress?.hasValidPhoneNumberForShipping == true
        && selectedPackage != nil
        && selectedRate != nil
        && (!customsFormRequired || customsInformationIsCompleted)
    }

    /// Shipping rates for the purchased label, with formatted amount.
    @Published private(set) var shippingRates: [(title: String, amount: String)] = []

    var currentPackage: ShippingLabelPackageSelected? {
        guard let selectedPackage else {
            return nil
        }
        return buildSelectedPackage(selectedPackage,
                                    weight: Double(shipmentWeight) ?? 0,
                                    shipmentID: shipment.index.description,
                                    hazmatCategory: hazmatCategory,
                                    customsForm: customsForm)
    }

    var refundViewModel: WooShippingRefundViewModel? {
        guard let shippingLabel, shippingLabel.isRefundable else {
            return nil
        }
        return WooShippingRefundViewModel(shippingLabel: shippingLabel)
    }

    private var debounceDuration: Double

    init(order: Order,
         shipment: Shipment,
         shippingLabel: ShippingLabel?,
         originAddress: AnyPublisher<WooShippingAddress?, Never>,
         destinationAddress: AnyPublisher<WooShippingAddress?, Never>,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         debounceDuration: Double = 1,
         onLabelPurchase: ((ShippingLabel) -> Void)? = nil,
         onLabelRefund: ((Int64) -> Void)? = nil) {
        self.order = order
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.shipment = shipment
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.debounceDuration = debounceDuration
        self.onLabelPurchase = onLabelPurchase
        self.onLabelRefund = onLabelRefund

        if let shippingLabel {
            self.postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)
            self.shippingLabel = shippingLabel
            self.hazmatCategory = .init(rawValue: shippingLabel.hazmatCategory ?? "")
        }

        observeAddresses(originAddressPublisher: originAddress,
                         destinationAddressPublisher: destinationAddress)
        observeSelectedPackage()
        observeLabelRates()
        observeCustomsForm()
        observeHAZMATChanges()
        observeShippingRates()
        setupSelectedRateReset()
    }

    /// Handles package selection for the shipping label.
    /// Selecting a package also refreshes the available rates for the shipping service.
    func selectPackage(_ packageData: WooShippingPackageDataRepresentable) {
        selectedPackage = packageData
        lastARMeasurement = nil
        analytics.track(event: .WooShipping.packageSelectionStep(state: .selected))
    }

    func parcelFittingDidConfirm(_ result: ParcelFittingResult,
                                  carriers: [ParcelPresetCarrier],
                                  starredPackageIDs: Set<String>,
                                  dimensionUnit: UnitLength) {
        let packageData = WooShippingPackageData.from(result, carriers: carriers)
        selectedPackage = packageData
        lastARMeasurement = result.measurement
        lastARCarriers = carriers
        lastARStarredPackageIDs = starredPackageIDs
        lastARDimensionUnit = dimensionUnit
        analytics.track(event: .WooShipping.packageSelectionStep(state: .selected))
    }

    func parcelFittingDidCancel() {}

    func parcelFittingDidToggleStar(packageID: String, carrierID: String, isStarred: Bool) {
        let action: WooShippingAction
        if isStarred {
            let predefined = WooShippingPredefinedSavedOption(id: carrierID, predefinedPackageIDs: [packageID])
            action = .createPackage(siteID: order.siteID, customPackage: nil, predefinedOption: predefined) { result in
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error starring package from AR results: \(error)")
                }
            }
        } else {
            action = .deletePackage(siteID: order.siteID,
                                    packageID: packageID,
                                    packageType: .predefined,
                                    completion: { result in
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error unstarring package from AR results: \(error)")
                }
            })
        }
        stores.dispatch(action)
    }

    /// After accepting UPS TOS, the selected UPS package/rate need to be reloaded with user data.
    /// We need to reload the package list and update the selected package with the one with the same ID.
    /// Similarly, we need to reload the shipping rates and updated the selected rate with the one with the same service ID.
    /// When the backend supports this reloading, we can remove this extra step.
    /// Ref: pe5sF9-4kN-p2/#ups-tos-flow
    ///
    @MainActor
    func refreshPackagesAndShippingRates() async throws {
        let currentShipmentWeight = shipmentWeight

        guard let selectedRate, let selectedPackage,
              let updatedPackage = try await refreshSelectedPackage(from: selectedPackage) else {
            throw WooShippingLabelPurchaseError.failedToRefreshSelectedPackage
        }
        self.selectedPackage = updatedPackage

        /// If the shipment weight was manually entered, reuse it.
        if currentShipmentWeight != shipmentWeight {
            self.shipmentWeight = currentShipmentWeight
        }

        let finalPackage = buildSelectedPackage(updatedPackage,
                                                weight: Double(shipmentWeight) ?? 0,
                                                shipmentID: shipment.index.description,
                                                hazmatCategory: hazmatCategory,
                                                customsForm: customsForm)

        guard let shippingService else {
            throw WooShippingLabelPurchaseError.failedToRefreshSelectedRate
        }
        try await withCheckedThrowingContinuation { continuation in
            shippingService.loadLabelRates(for: finalPackage) { result in
                continuation.resume(with: result)
            }
        }
        guard let updatedRate = shippingService.refreshSelectedRate(from: selectedRate) else {
            throw WooShippingLabelPurchaseError.failedToRefreshSelectedRate
        }
        self.selectedRate = updatedRate
    }

    /// Purchases a shipping label with the provided label details and settings.
    @MainActor
    func purchaseLabel(markOrderComplete: Bool? = nil) async throws {
        guard let originAddress, let destinationAddress,
              let package = currentPackage,
              let selectedRate else {
            return
        }

        analytics.track(event: .WooShipping.purchaseStep(state: .started))
        let packagePurchase = WooShippingPackagePurchase(shipmentID: shipment.index.description,
                                                         package: package,
                                                         selectedRate: selectedRate,
                                                         productIDs: shipment.items.map(\.productOrVariationID))

        // Avoid sending email for destination address as that crashes the purchase API at the moment.
        // TODO: remove this workaround when backend fixes this and adoption rate is high enough.
        let destinationAddressWithoutEmail = destinationAddress.copy(email: nil)

        let purchasedLabel = try await withCheckedThrowingContinuation { continuation in
            let action = WooShippingAction.purchaseShippingLabel(siteID: order.siteID,
                                                                 orderID: order.orderID,
                                                                 originAddress: originAddress,
                                                                 destinationAddress: destinationAddressWithoutEmail,
                                                                 package: packagePurchase,
                                                                 markOrderComplete: markOrderComplete) { [weak self] result in
                switch result {
                case .success:
                    self?.analytics.track(event: .WooShipping.purchaseStep(state: .purchaseSuccess))
                case .failure(let error):
                    self?.analytics.track(event: .WooShipping.purchaseStep(state: .purchaseFailed, error: error))
                }
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
        /// Addresses are not included in purchased shipping label details
        /// so we have to manually populate the details.
        let updatedLabel = purchasedLabel.copy(originAddress: originAddress.toShippingLabelAddress(),
                                               destinationAddress: destinationAddress.toShippingLabelAddress())
        shippingLabel = updatedLabel
        postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: updatedLabel)
        onLabelPurchase?(updatedLabel)
    }

    func didRequestRefund(for labelID: Int64) {
        shippingLabel = nil
        postPurchase = nil
        onLabelRefund?(labelID)
    }
}

/// Accessor for manual collapsed product items section accessibility label
extension WooShippingShipmentDetailsViewModel {
    var itemsSummaryAccessibilityValue: String {
        return String.localizedStringWithFormat(
            Localization.itemsSummaryAccessibilityFormat,
            shipment.quantity,
            shipment.weight,
            shipment.price
        )
    }
}

private extension WooShippingShipmentDetailsViewModel {
    func observeAddresses(originAddressPublisher: AnyPublisher<WooShippingAddress?, Never>,
                          destinationAddressPublisher: AnyPublisher<WooShippingAddress?, Never>) {
        originAddressPublisher
            .assign(to: &$originAddress)

        destinationAddressPublisher
            .assign(to: &$destinationAddress)

        $destinationAddress
            .sink { [weak self] address in
                guard let country = address?.country else {
                    return
                }
                // Updating destination country code in the customs form to validate ITN
                self?.customsFormViewModel.updateDestinationCountry(code: country)
            }
            .store(in: &subscriptions)

        $originAddress.combineLatest($destinationAddress)
            .map { [weak self] originAddress, destinationAddress in
                guard let self else { return nil }
                return WooShippingServiceViewModel(order: order,
                                                   originAddress: originAddress,
                                                   destinationAddress: destinationAddress,
                                                   stores: stores) { [weak self] selectedRate in
                    self?.selectedRate = selectedRate
                }
            }
            .assign(to: &$shippingService)

        $originAddress.combineLatest($destinationAddress)
            .map { (originAddress, destinationAddress) -> Bool in
                guard let originAddress, let destinationAddress else {
                    return false
                }
                return WooShippingCustomsRequirements.isCustomsRequired(originCountry: originAddress.country,
                                                                        originState: originAddress.state,
                                                                        destinationCountry: destinationAddress.country,
                                                                        destinationState: destinationAddress.state)
            }
            .assign(to: &$customsFormRequired)
    }

    /// Observes the selected package and updates the shipment weight.
    func observeSelectedPackage() {
        let itemsWeight = shipment.items.map { $0.weight * Double(truncating: $0.quantity as NSDecimalNumber) }.reduce(0, +)
        $selectedPackage
            .map { selectedPackage in
                guard let selectedPackage else {
                    return itemsWeight.description
                }
                return (itemsWeight + (Double(selectedPackage.weight) ?? 0)).description
            }
            .assign(to: &$shipmentWeight)
    }

    /// Observes the selected package and shipment weight and requests the available shipping rates.
    func observeLabelRates() {
        $shipmentWeight
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest($selectedPackage, $shippingService)
            .combineLatest($customsForm, $hazmatCategory)
            .sink { [weak self] input in
                let ((weight, selectedPackage, shippingService), customsForm, hazmatCategory) = input
                guard let self, let selectedPackage, let shippingService else { return }
                let package = buildSelectedPackage(selectedPackage,
                                                   weight: Double(weight) ?? 0,
                                                   shipmentID: shipment.index.description,
                                                   hazmatCategory: hazmatCategory,
                                                   customsForm: customsForm)
                shippingService.loadLabelRates(for: package)
            }
            .store(in: &subscriptions)
    }

    func observeHAZMATChanges() {
        $hazmatCategory
            .dropFirst()
            .scan((nil, nil)) { (previous: (current: ShippingLabelHazmatCategory?,
                                            previous: ShippingLabelHazmatCategory?),
                                 newValue: ShippingLabelHazmatCategory?) in
                return (current: newValue, previous: previous.current)
            }
            .map { [weak self] (newValue, oldValue) in
                let noticeTitle = newValue != nil ? Localization.hazmatSet : Localization.hazmatRemoved
                return Notice(title: noticeTitle, actionTitle: Localization.undo, actionHandler: {
                    self?.hazmatCategory = oldValue
                })
            }
            .assign(to: &$hazmatNotice)
    }

    func observeCustomsForm() {
        customsFormViewModel.$isMissingITN.combineLatest($customsFormRequired)
            .map { (isMissingITN, customsFormRequired) -> String? in
                if customsFormRequired, isMissingITN {
                    return Localization.itnMissing
                }
                return nil
            }
            .assign(to: &$itnMissingNoticeLabel)

        customsFormViewModel.$requiredInformationIsEntered.combineLatest($customsFormRequired)
            .map { (requiredInfoIsEntered, customsFormRequired) -> Bool in
                requiredInfoIsEntered && customsFormRequired
            }
            .assign(to: &$customsInformationIsCompleted)
    }

    private func observeShippingRates() {
        $shippingLabel.combineLatest($selectedRate)
            .map { [weak self] shippingLabel, selectedRate -> [(title: String, amount: String)] in
                guard let self else { return [] }
                if let shippingLabel {
                    return [self.formatShippingRate(name: shippingLabel.serviceName, rate: shippingLabel.rate)]
                } else if let selectedRate {
                    let baseRate = selectedRate.rate.rate
                    let formattedBaseRate = self.formatShippingRate(name: Localization.baseRateLabel(for: selectedRate), rate: baseRate)
                    let formattedAdditionalRates = [
                        selectedRate.signatureRate.map { self.formatShippingRate(name: Localization.signatureRequired, rate: $0.rate, basedOn: baseRate) },
                        selectedRate.adultSignatureRate.map { self.formatShippingRate(name: Localization.adultSignatureRequired,
                                                                                      rate: $0.rate,
                                                                                      basedOn: baseRate) },
                        selectedRate.carbonNeutralRate.map {
                            self.formatShippingRate(name: Localization.carbonNeutral,
                                                    rate: $0.rate,
                                                    basedOn: baseRate)
                        },
                        selectedRate.additionalHandlingRate.map {
                            self.formatShippingRate(name: Localization.additionalHandling,
                                                    rate: $0.rate,
                                                    basedOn: baseRate)
                        },
                        selectedRate.saturdayDeliveryRate.map {
                            self.formatShippingRate(name: Localization.saturdayDelivery,
                                                    rate: $0.rate,
                                                    basedOn: baseRate)
                        }
                    ].compacted()
                    return [formattedBaseRate] + formattedAdditionalRates
                } else {
                    return []
                }
            }
            .assign(to: &$shippingRates)
    }

    /// Observes changes in shipment details and resets the selected rate.
    /// This is to prevent displaying a stale price when critical details that affect pricing have changed.
    func setupSelectedRateReset() {
        $destinationAddress.removeDuplicates()
            .combineLatest($originAddress.removeDuplicates())
            .combineLatest(
                $selectedPackage.removeDuplicates(by: { $0?.id == $1?.id })
            )
            .combineLatest($shipmentWeight.removeDuplicates())
            .combineLatest($hazmatCategory.removeDuplicates())
            .combineLatest($customsForm.removeDuplicates())
            // Drop the initial values set on initialization, so we only react to changes.
            .dropFirst()
            .sink { [weak self] _ in
                self?.selectedRate = nil
                self?.shippingService?.clearSelectedRate()
            }
            .store(in: &subscriptions)
    }

    /// Converts the package data to a `ShippingLabelPackageSelected` object.
    func buildSelectedPackage(_ packageData: WooShippingPackageDataRepresentable,
                              weight: Double,
                              shipmentID: String,
                              hazmatCategory: ShippingLabelHazmatCategory?,
                              customsForm: ShippingLabelCustomsForm?) -> ShippingLabelPackageSelected {
        ShippingLabelPackageSelected(id: shipmentID,
                                     boxID: packageData.id,
                                     length: Double(packageData.length) ?? 0,
                                     width: Double(packageData.width) ?? 0,
                                     height: Double(packageData.height) ?? 0,
                                     weight: weight,
                                     isLetter: WooShippingPackageType(rawValue: packageData.packageType) == .envelope,
                                     hazmatCategory: hazmatCategory?.rawValue,
                                     customsForm: customsForm)
    }

    /// Provides the formatted label and amount for a shipping rate, based on the provided base rate.
    func formatShippingRate(name: String, rate: Double, basedOn baseRate: Double? = nil) -> (title: String, amount: String) {
        let amount = {
            guard let baseRate else {
                return rate
            }
            return rate - baseRate
        }()
        return (name, currencyFormatter.formatAmount(Decimal(amount)) ?? amount.description)
    }

    @MainActor
    func refreshSelectedPackage(from oldPackage: WooShippingPackageDataRepresentable) async throws -> WooShippingPackageDataRepresentable? {
        let packages = try await withCheckedThrowingContinuation { continuation in
            let loadPackagesAction = WooShippingAction.loadPackages(siteID: order.siteID) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(loadPackagesAction)
        }
        let customSavedPackages = packages.customPackages.map { $0.toPackageData() }
        let predefinedSavedPackages = packages.savedPredefinedPackages.map { $0.toPackageData() }

        if let foundPackage = (customSavedPackages + predefinedSavedPackages).first(where: { $0.id == oldPackage.id }) {
            return foundPackage
        }

        let carrierPackages = packages.allPredefinedOptions.compactMap { $0.toCarrierPackages() }
        var foundCarrierPackage: WooShippingPackageDataRepresentable?
        outerLoop: for carrierPackage in carrierPackages {
            let packageGroups = carrierPackage.packageGroups
            for group in packageGroups {
                if let foundPackage = group.packages.first(where: { $0.id == oldPackage.id }) {
                    foundCarrierPackage = foundPackage
                    break outerLoop
                }
            }
        }
        return foundCarrierPackage
    }

    func originCountryCodePublisher() -> AnyPublisher<String?, Never> {
        $originAddress
            .map(\.?.country)
            .eraseToAnyPublisher()
    }

    func isHSTariffNumberRequiredPublisher() -> AnyPublisher<Bool, Never> {
        $destinationAddress
            /// HS tariff number is required for EU countries
            .map { address in
                guard let address else {
                    return false
                }

                return Country.countriesFollowingEUCustoms.contains(address.country)
            }
            .eraseToAnyPublisher()
    }
}

private extension WooShippingShipmentDetailsViewModel {
    enum Localization {
        static let itnMissing = NSLocalizedString(
            "wooShipping.shipmentDetails.itnMissing",
            value: "ITN is required.",
            comment: "Notice when a International Transaction Number is missing on the shipping label creation screen"
        )
        static let hazmatSet = NSLocalizedString(
            "wooShipping.shipmentDetails.hazmatSet",
            value: "Hazardous materials category set",
            comment: "Notice when a hazardous materials category is set on the shipping label creation screen"
        )

        static let hazmatRemoved = NSLocalizedString(
            "wooShipping.shipmentDetails.hazmatRemoved",
            value: "Remove hazardous materials category",
            comment: "Notice when a hazardous materials category is removed on the shipping label creation screen"
        )

        static let undo = NSLocalizedString(
            "wooShipping.shipmentDetails.undo",
            value: "Undo",
            comment: "Button to undo a change on the shipping label creation screen"
        )
        static func baseRateLabel(for selectedRate: WooShippingSelectedRate) -> String {
            if selectedRate.signatureRate == nil &&
                selectedRate.adultSignatureRate == nil &&
                selectedRate.carbonNeutralRate == nil &&
                selectedRate.additionalHandlingRate == nil &&
                selectedRate.saturdayDeliveryRate == nil {
                return selectedRate.rate.title
            } else {
                return String.localizedStringWithFormat(baseFeeFormat, selectedRate.rate.title)
            }
        }

        private static let baseFeeFormat = NSLocalizedString("wooShipping.createLabels.bottomSheet.baseFee",
                                                             value: "%1$@ (base fee)",
                                                             comment: "Label for row showing the base fee for the selected shipping service " +
                                                             "on the shipping label creation screen. Reads like: 'USPS - Media Mail (base fee)'")
        static let signatureRequired = NSLocalizedString("wooShipping.createLabels.bottomSheet.signatureRequired",
                                                         value: "Signature Required",
                                                         comment: "Label for row showing the additional cost to require a signature " +
                                                         "on the shipping label creation screen")
        static let adultSignatureRequired = NSLocalizedString("wooShipping.createLabels.bottomSheet.adultSignatureRequired",
                                                              value: "Adult Signature Required",
                                                              comment: "Label for row showing the additional cost to require an adult signature " +
                                                              "on the shipping label creation screen")
        static let carbonNeutral = NSLocalizedString(
            "wooShipping.createLabels.bottomSheet.carbonNeutral",
            value: "Carbon Neutral",
            comment: "Label for row showing the additional cost to require carbon neutral delivery " +
            "on the shipping label creation screen"
        )
        static let additionalHandling = NSLocalizedString(
            "wooShipping.createLabels.bottomSheet.additionalHandling",
            value: "Additional Handling",
            comment: "Label for row showing the additional cost to require additional handling " +
            "on the shipping label creation screen"
        )
        static let saturdayDelivery = NSLocalizedString(
            "wooShipping.createLabels.bottomSheet.saturdayDelivery",
            value: "Saturday Delivery",
            comment: "Label for row showing the additional cost to require Saturday delivery " +
            "on the shipping label creation screen"
        )
        static let itemsSummaryAccessibilityFormat = NSLocalizedString(
            "shipping-labels.packages.items.summary.accessibility-label",
            value: "%1$@ with a total weight of %2$@ and a total price of %3$@",
            comment: "Accessibility label for the summary of product items in a shipment." +
                " The %1$@ is items count." +
                " The %2$@ is total weight." +
                " The %3$@ is total price."
        )
    }
}
