import Foundation
import Yosemite
import WooFoundation
import Combine

final class WooShippingShipmentDetailsViewModel: ObservableObject {

    private let order: Order
    private let stores: StoresManager
    private let originAddress: AnyPublisher<WooShippingOriginAddress?, Never>
    private let destinationAddress: AnyPublisher<WooShippingAddress?, Never>

    private var subscriptions: Set<AnyCancellable> = []

    @Published var hazmatCategory: ShippingLabelHazmatCategory?
    @Published var hazmatNotice: Notice?

    /// The purchased shipping label.
    @Published private var shippingLabel: ShippingLabel?

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

    /// Selected package data for the shipping label.
    @Published private(set) var selectedPackage: WooShippingPackageDataRepresentable?

    /// String representing the total weight for the shipment.
    @Published var shipmentWeight: String = ""

    /// View model for the label shipping service.
    private(set) var shippingService: WooShippingServiceViewModel?

    /// Selected shipping rate when creating a shipping label.
    @Published private var selectedRate: WooShippingSelectedRate?

    private var customsForm: ShippingLabelCustomsForm?

    lazy var customsFormViewModel: WooShippingCustomsFormViewModel = {
        WooShippingCustomsFormViewModel(order: order, onCompletion: { [weak self] form in
            self?.customsForm = form
        })
    }()

    /// Whether the custom information is completed or not.
    var customsInformationIsCompleted: Bool {
        customsForm != nil && customsFormViewModel.requiredInformationIsEntered
    }

    /// Check for the need of customs form
    ///
    @Published private(set) var customsFormRequired: Bool = false

    @Published var itnMissingNoticeLabel: String?

    private var debounceDuration: Double = 1

    init(order: Order,
         shipment: Shipment,
         originAddress: AnyPublisher<WooShippingOriginAddress?, Never>,
         destinationAddress: AnyPublisher<WooShippingAddress?, Never>,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.stores = stores
        self.shipment = shipment
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress

        observeSelectedPackage()
        observeLabelRates()
        observeCustomsForm()
        observeHAZMATChanges()
    }

    /// Handles package selection for the shipping label.
    /// Selecting a package also refreshes the available rates for the shipping service.
    func selectPackage(_ packageData: WooShippingPackageDataRepresentable) {
        selectedPackage = packageData
    }
}

private extension WooShippingShipmentDetailsViewModel {
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
            .combineLatest($selectedPackage)
            .sink { [weak self] weight, selectedPackage in
                guard let self, let selectedPackage, let shippingService else { return }
                let package = buildSelectedPackage(selectedPackage,
                                                   weight: Double(weight) ?? 0,
                                                   shipmentID: shipment.id)
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
        originAddress.combineLatest(destinationAddress)
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

        customsFormViewModel.$isMissingITN.combineLatest($customsFormRequired)
            .map { (isMissingITN, customsFormRequired) -> String? in
                if customsFormRequired, isMissingITN {
                    return Localization.itnMissing
                }
                return nil
            }
            .assign(to: &$itnMissingNoticeLabel)
    }

    /// Converts the package data to a `ShippingLabelPackageSelected` object.
    func buildSelectedPackage(_ packageData: WooShippingPackageDataRepresentable, weight: Double, shipmentID: String) -> ShippingLabelPackageSelected {
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
    }
}
