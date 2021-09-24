import Combine
import UIKit
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType


/// View model for `ShippingLabelPackagesForm`.
///
final class ShippingLabelPackagesFormViewModel: ObservableObject {

    var foundMultiplePackages: Bool {
        selectedPackages.count > 1
    }

    /// Message displayed on the Move Item action sheet.
    ///
    @Published private(set) var moveItemActionSheetMessage: String = ""

    /// Option buttons displayed on the Move Item action sheet.
    ///
    @Published private(set) var moveItemActionSheetButtons: [ActionSheet.Button] = []

    /// References of view models for child items.
    ///
    @Published private(set) var itemViewModels: [ShippingLabelSinglePackageViewModel] = []

    /// Whether Done button on Package Details screen should be enabled.
    ///
    @Published private(set) var doneButtonEnabled: Bool = false

    private let order: Order
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private var resultsControllers: ShippingLabelPackageDetailsResultsControllers?
    private let onSelectionCompletion: (_ selectedPackages: [ShippingLabelPackageAttributes]) -> Void
    private let onPackageSyncCompletion: (_ packagesResponse: ShippingLabelPackagesResponse?) -> Void

    private var cancellables: Set<AnyCancellable> = []

    /// Validation states of all items.
    ///
    private var packagesValidation: [String: Bool] = [:] {
        didSet {
            configureDoneButton()
        }
    }

    /// List of packages that are validated.
    ///
    private var validatedPackages: [ShippingLabelPackageAttributes] {
        itemViewModels.compactMap {
            $0.validatedPackageAttributes
        }
    }

    /// List of selected package with basic info.
    ///
    @Published private var selectedPackages: [ShippingLabelPackageAttributes] = []

    /// Products contained inside the Order and fetched from Core Data
    ///
    @Published private var products: [Product] = []

    /// ProductVariations contained inside the Order and fetched from Core Data
    ///
    @Published private var productVariations: [ProductVariation] = []

    init(order: Order,
         packagesResponse: ShippingLabelPackagesResponse?,
         selectedPackages: [ShippingLabelPackageAttributes],
         onSelectionCompletion: @escaping (_ selectedPackages: [ShippingLabelPackageAttributes]) -> Void,
         onPackageSyncCompletion: @escaping (_ packagesResponse: ShippingLabelPackagesResponse?) -> Void,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.order = order
        self.stores = stores
        self.storageManager = storageManager
        self.selectedPackages = selectedPackages
        self.onSelectionCompletion = onSelectionCompletion
        self.onPackageSyncCompletion = onPackageSyncCompletion

        configureResultsControllers()
        syncProducts()
        syncProductVariations()
        configureDefaultPackage()
        configureItemViewModels(order: order, packageResponse: packagesResponse)
    }

    func confirmPackageSelection() {
        onSelectionCompletion(validatedPackages)
    }
}

// MARK: - Helper methods
//
private extension ShippingLabelPackagesFormViewModel {
    /// If no initial packages was input, set up default package from last selected package ID and all order items.
    ///
    func configureDefaultPackage() {
        guard selectedPackages.isEmpty,
              let selectedPackageID = resultsControllers?.accountSettings?.lastSelectedPackageID else {
            return
        }
        let items = order.items.compactMap { ShippingLabelPackageItem(orderItem: $0,
                                                                      products: products,
                                                                      productVariations: productVariations) }
        selectedPackages = [ShippingLabelPackageAttributes(packageID: selectedPackageID,
                                                           totalWeight: "",
                                                           items: items)]
    }

    /// Set up item view models on change selected packages.
    ///
    func configureItemViewModels(order: Order, packageResponse: ShippingLabelPackagesResponse?) {
        $selectedPackages
            .map { selectedPackages -> [ShippingLabelSinglePackageViewModel] in
                return selectedPackages.enumerated().map { index, details in
                    let isOriginal = details.packageID == ShippingLabelPackageAttributes.originalPackagingBoxID
                    return ShippingLabelSinglePackageViewModel(order: order,
                                                               orderItems: details.items,
                                                               packagesResponse: packageResponse,
                                                               selectedPackageID: details.packageID,
                                                               totalWeight: details.totalWeight,
                                                               isOriginalPackaging: isOriginal,
                                                               onItemMoveRequest: { [weak self] productOrVariationID, packageName in
                        self?.updateMoveItemActionSheet(for: productOrVariationID,
                                                           from: details,
                                                           packageIndex: index,
                                                           packageName: packageName)
                    },
                                                               onPackageSwitch: { [weak self] newPackage in
                        self?.switchPackage(currentPackage: details, newPackage: newPackage)
                    },
                                                               onPackagesSync: { [weak self] packagesResponse in
                        self?.onPackageSyncCompletion(packagesResponse)
                    })
                }
            }
            .sink { [weak self] viewModels in
                self?.itemViewModels = viewModels
                self?.observeItemViewModels()
            }
            .store(in: &cancellables)
    }

    /// Update title and buttons for the Move Item action sheet.
    ///
    func updateMoveItemActionSheet(for productOrVariationID: Int64,
                                   from currentPackage: ShippingLabelPackageAttributes,
                                   packageIndex: Int,
                                   packageName: String) {
        moveItemActionSheetMessage = String(format: Localization.moveItemActionSheetMessage, packageIndex + 1, packageName)
        moveItemActionSheetButtons = {
            var buttons: [ActionSheet.Button] = []
            // if package is not original packaging, add option to ship in original package
            if currentPackage.packageID != ShippingLabelPackageAttributes.originalPackagingBoxID {
                buttons.append(.default(Text(Localization.shipInOriginalPackage)) { [weak self] in
                    self?.shipInOriginalPackage(productOrVariationID: productOrVariationID, from: currentPackage)
                })
            }
            buttons.append(.cancel())
            return buttons
        }()
    }

    func shipInOriginalPackage(productOrVariationID: Int64, from currentPackage: ShippingLabelPackageAttributes) {
        var updatedPackages: [ShippingLabelPackageAttributes] = []
        for package in selectedPackages {
            if package == currentPackage {
                var matchingItem: ShippingLabelPackageItem?
                var updatedItems: [ShippingLabelPackageItem] = []
                for item in package.items {
                    if item.productOrVariationID == productOrVariationID, matchingItem == nil {
                        matchingItem = ShippingLabelPackageItem(copy: item, quantity: 1)
                        if item.quantity > 1 {
                            let newItem = ShippingLabelPackageItem(copy: item, quantity: item.quantity - 1)
                            updatedItems.append(newItem)
                        }
                    } else {
                        updatedItems.append(item)
                    }
                }

                guard let matchingItem = matchingItem else {
                    assertionFailure("⛔️ Cannot find item with product or variationID \(productOrVariationID) in current package!")
                    continue
                }

                // If the resulting item list is not empty, create a copy of the package with the list.
                if updatedItems.isNotEmpty {
                    let updatedPackage = ShippingLabelPackageAttributes(packageID: package.packageID,
                                                                        totalWeight: package.totalWeight,
                                                                        items: updatedItems)
                    updatedPackages.append(updatedPackage)
                }

                // Append a copy of matching item with quantity = 1
                let originalPackage = ShippingLabelPackageAttributes(packageID: ShippingLabelPackageAttributes.originalPackagingBoxID,
                                                                     totalWeight: "",
                                                                     items: [matchingItem])
                updatedPackages.append(originalPackage)

            } else {
                updatedPackages.append(package)
            }
        }
        selectedPackages = updatedPackages
    }

    /// Update selected packages when user switch any package.
    ///
    func switchPackage(currentPackage: ShippingLabelPackageAttributes, newPackage: ShippingLabelPackageAttributes) {
        selectedPackages = selectedPackages.map { package in
            if package == currentPackage {
                return newPackage
            } else {
                return package
            }
        }
    }

    /// Observe validation state of each package and save it by package ID.
    ///
    func observeItemViewModels() {
        itemViewModels.forEach { item in
            item.$isValidTotalWeight
                .sink { [weak self] isValid in
                    self?.packagesValidation[item.selectedPackageID] = isValid
                }
                .store(in: &cancellables)
        }
    }

    /// Disable Done button if any of the package validation fails.
    ///
    func configureDoneButton() {
        doneButtonEnabled = packagesValidation.first(where: { $0.value == false }) == nil
    }

    func configureResultsControllers() {
        resultsControllers = ShippingLabelPackageDetailsResultsControllers(siteID: order.siteID,
                                                                           orderItems: order.items,
                                                                           storageManager: storageManager,
           onProductReload: { [weak self] (products) in
            guard let self = self else { return }
            self.products = products
        }, onProductVariationsReload: { [weak self] (productVariations) in
            guard let self = self else { return }
            self.productVariations = productVariations
        })

        products = resultsControllers?.products ?? []
        productVariations = resultsControllers?.productVariations ?? []
    }
}

/// API Requests
///
private extension ShippingLabelPackagesFormViewModel {
    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.requestMissingProducts(for: order) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing Products: \(error)")
                onCompletion?(error)
                return
            }

            onCompletion?(nil)
        }

        stores.dispatch(action)
    }

    func syncProductVariations(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductVariationAction.requestMissingVariations(for: order) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing missing variations in an Order: \(error)")
                onCompletion?(error)
                return
            }
            onCompletion?(nil)
        }
        stores.dispatch(action)
    }
}

private extension ShippingLabelPackagesFormViewModel {
    enum Localization {
        static let moveItemActionSheetMessage = NSLocalizedString("This item is currently in Package %1$d: %2$@. Where would you like to move it?",
                                                                  comment: "Message in action sheet when an order item is about to " +
                                                                    "be moved on Package Details screen of Shipping Label flow. " +
                                                                    "The package name reads like: Package 1: Custom Envelope.")
        static let shipInOriginalPackage = NSLocalizedString("Ship in Original Packaging",
                                                             comment: "Option to ship in original packaging on action sheet when an order item is about to " +
                                                                "be moved on Package Details screen of Shipping Label flow.")
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension ShippingLabelPackagesFormViewModel {

    static func sampleOrder() -> Order {
        return Order(siteID: 1234,
                     orderID: 963,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     status: .processing,
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodID: "stripe",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: sampleItems(),
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: sampleCoupons(),
                     refunds: [],
                     fees: [])
    }

    static func sampleAddress() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    static func sampleShippingLines() -> [ShippingLine] {
        return [ShippingLine(shippingID: 123,
                             methodTitle: "International Priority Mail Express Flat Rate",
                             methodID: "usps",
                             total: "133.00",
                             totalTax: "0.00",
                             taxes: [.init(taxID: 1, subtotal: "", total: "0.62125")])]
    }

    static func sampleCoupons() -> [OrderCouponLine] {
        let coupon1 = OrderCouponLine(couponID: 894,
                                      code: "30$off",
                                      discount: "30",
                                      discountTax: "1.2")

        return [coupon1]
    }

    static func sampleItems() -> [OrderItem] {
        let item1 = OrderItem(itemID: 890,
                              name: "Fruits Basket (Mix & Match Product)",
                              productID: 52,
                              variationID: 0,
                              quantity: 2,
                              price: NSDecimalNumber(integerLiteral: 30),
                              sku: "",
                              subtotal: "50.00",
                              subtotalTax: "2.00",
                              taxClass: "",
                              taxes: [.init(taxID: 1, subtotal: "2", total: "1.2")],
                              total: "30.00",
                              totalTax: "1.20",
                              attributes: [])

        let item2 = OrderItem(itemID: 891,
                              name: "Fruits Bundle",
                              productID: 234,
                              variationID: 0,
                              quantity: 1.5,
                              price: NSDecimalNumber(integerLiteral: 0),
                              sku: "5555-A",
                              subtotal: "10.00",
                              subtotalTax: "0.40",
                              taxClass: "",
                              taxes: [.init(taxID: 1, subtotal: "0.4", total: "0")],
                              total: "0.00",
                              totalTax: "0.00",
                              attributes: [])

        return [item1, item2]
    }

    static func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }

    static func taxes() -> [OrderItemTax] {
        return [OrderItemTax(taxID: 75, subtotal: "0.45", total: "0.45")]
    }

    static func samplePackageDetails() -> ShippingLabelPackagesResponse {
        return ShippingLabelPackagesResponse(storeOptions: sampleShippingLabelStoreOptions(),
                                             customPackages: sampleShippingLabelCustomPackages(),
                                             predefinedOptions: sampleShippingLabelPredefinedOptions(),
                                             unactivatedPredefinedOptions: sampleShippingLabelPredefinedOptions())
    }

    static func sampleShippingLabelStoreOptions() -> ShippingLabelStoreOptions {
        return ShippingLabelStoreOptions(currencySymbol: "$", dimensionUnit: "cm", weightUnit: "kg", originCountry: "US")
    }

    static func sampleShippingLabelCustomPackages() -> [ShippingLabelCustomPackage] {
        let customPackage1 = ShippingLabelCustomPackage(isUserDefined: true,
                                                        title: "Krabica",
                                                        isLetter: false,
                                                        dimensions: "1 x 2 x 3",
                                                        boxWeight: 1,
                                                        maxWeight: 0)
        let customPackage2 = ShippingLabelCustomPackage(isUserDefined: true,
                                                        title: "Obalka",
                                                        isLetter: true,
                                                        dimensions: "2 x 3 x 4",
                                                        boxWeight: 5,
                                                        maxWeight: 0)

        return [customPackage1, customPackage2]
    }

    static func sampleShippingLabelPredefinedOptions() -> [ShippingLabelPredefinedOption] {
        let predefinedPackages1 = [ShippingLabelPredefinedPackage(id: "small_flat_box",
                                                                  title: "Small Flat Rate Box",
                                                                  isLetter: false,
                                                                  dimensions: "21.91 x 13.65 x 4.13"),
                                  ShippingLabelPredefinedPackage(id: "medium_flat_box_top",
                                                                 title: "Medium Flat Rate Box 1, Top Loading",
                                                                 isLetter: false,
                                                                 dimensions: "28.57 x 22.22 x 15.24")]
        let predefinedOption1 = ShippingLabelPredefinedOption(title: "USPS Priority Mail Flat Rate Boxes",
                                                              providerID: "USPS",
                                                              predefinedPackages: predefinedPackages1)

        let predefinedPackages2 = [ShippingLabelPredefinedPackage(id: "LargePaddedPouch",
                                                                  title: "Large Padded Pouch",
                                                                  isLetter: true,
                                                                  dimensions: "30.22 x 35.56 x 2.54")]
        let predefinedOption2 = ShippingLabelPredefinedOption(title: "DHL Express",
                                                              providerID: "DHL",
                                                              predefinedPackages: predefinedPackages2)

        return [predefinedOption1, predefinedOption2]
    }
}
