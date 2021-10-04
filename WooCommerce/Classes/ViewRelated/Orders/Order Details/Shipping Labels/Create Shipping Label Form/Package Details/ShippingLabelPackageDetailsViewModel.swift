import Combine
import UIKit
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `ShippingLabelPackageDetails`.
///
final class ShippingLabelPackageDetailsViewModel: ObservableObject {

    private let order: Order
    private let orderItems: [OrderItem]
    private let currency: String
    private let currencyFormatter: CurrencyFormatter
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private var resultsControllers: ShippingLabelPackageDetailsResultsControllers?

    /// Products contained inside the Order and fetched from Core Data
    ///
    @Published private var products: [Product] = []

    /// ProductVariations contained inside the Order and fetched from Core Data
    ///
    @Published private var productVariations: [ProductVariation] = []

    /// The weight unit used in the Store
    ///
    let weightUnit: String?

    /// View model for the package list
    ///
    let packageListViewModel: ShippingLabelPackageListViewModel

    /// The items rows observed by the main view `ShippingLabelPackageDetails`
    ///
    @Published private(set) var itemsRows: [ItemToFulfillRow] = []

    /// The id of the selected package. Defaults to last selected package, if any.
    ///
    @Published var selectedPackageID: String?

    /// List of selected package with basic info.
    /// This is a workaround to work with multi-package solution which requires a list of packages.
    /// Since this legacy view model works only with one package, the returned list contains at most one item only.
    ///
    var selectedPackagesDetails: [ShippingLabelPackageAttributes] {
        guard let id = selectedPackageID, totalWeight.isNotEmpty else {
            return []
        }
        let items = orderItems.compactMap { ShippingLabelPackageItem(orderItem: $0,
                                                                     products: products,
                                                                     productVariations: productVariations) }
        return [ShippingLabelPackageAttributes(packageID: id, totalWeight: totalWeight, items: items)]
    }

    /// The title of the selected package, if any.
    ///
    var selectedPackageName: String {
        if let selectedCustomPackage = packageListViewModel.selectedCustomPackage {
            return selectedCustomPackage.title
        }
        else if let selectedPredefinedPackage = packageListViewModel.selectedPredefinedPackage {
            return selectedPredefinedPackage.title
        }
        else {
            return Localization.selectPackagePlaceholder
        }
    }

    @Published var totalWeight: String = ""

    /// Whether the user has edited the total package weight. If true, we won't make any automatic changes to the total weight.
    ///
    @Published private var isPackageWeightEdited: Bool = false

    /// Completion callback after package details are synced from remote
    ///
    private let onPackageSyncCompletion: (_ packagesResponse: ShippingLabelPackagesResponse?) -> Void

    /// Completion callback after selected package is saved
    ///
    private let onPackageSaveCompletion: (_ selectedPackages: [ShippingLabelPackageAttributes]) -> Void

    init(order: Order,
         packagesResponse: ShippingLabelPackagesResponse?,
         selectedPackages: [ShippingLabelPackageAttributes],
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit,
         onPackageSyncCompletion: @escaping (_ packagesResponse: ShippingLabelPackagesResponse?) -> Void,
         onPackageSaveCompletion: @escaping (_ selectedPackages: [ShippingLabelPackageAttributes]) -> Void) {
        self.order = order
        self.orderItems = order.items
        self.currency = order.currency
        self.currencyFormatter = formatter
        self.stores = stores
        self.storageManager = storageManager
        self.weightUnit = weightUnit
        self.packageListViewModel = ShippingLabelPackageListViewModel(siteID: order.siteID, packagesResponse: packagesResponse)
        // This is temporary solution while supporting both single and multiple packages solution.
        self.selectedPackageID = selectedPackages.first?.packageID
        self.onPackageSyncCompletion = onPackageSyncCompletion
        self.onPackageSaveCompletion = onPackageSaveCompletion
        self.packageListViewModel.delegate = self

        configureResultsControllers()
        setDefaultPackage()
        syncProducts()
        syncProductVariations()
        configureItemRows()

        // This is temporary solution while supporting both single and multiple packages solution.
        configureTotalWeights(initialTotalWeight: selectedPackages.first?.totalWeight)
    }

    /// Observe changes in products and variations to update item rows.
    ///
    private func configureItemRows() {
        $products.combineLatest($productVariations) { [weak self] (products, variations) in
            guard let self = self else { return [] }
            return self.generateItemsRows(products: products, productVariations: variations)
        }
        .assign(to: &$itemsRows)
    }

    /// Observe changes in selected custom package, products and variations to update total package weight.
    /// - Parameter initialTotalWeight: the weight value that was input initially.
    /// If this value is different from the calculated weight, we can assume that user has updated the weight manually.
    ///
    private func configureTotalWeights(initialTotalWeight: String?) {
        if let initialTotalWeight = initialTotalWeight {
            let calculatedWeight = calculateTotalWeight(products: products,
                                                        productVariations: productVariations,
                                                        customPackage: packageListViewModel.selectedCustomPackage)
            // Return early if manual input is detected
            if initialTotalWeight != String(calculatedWeight) {
                isPackageWeightEdited = true
                return totalWeight = initialTotalWeight
            }
        }

        // Create a stream of changes of calculated weight.
        // This takes into account changes of selected custom package, products and variations.
        // The stream should be completed immediately if manual input of package weight is detected.
        //
        let calculatedWeight = packageListViewModel.$selectedCustomPackage.combineLatest($products, $productVariations)
            .map { [weak self] (customPackage, products, variations) -> Double in
                self?.calculateTotalWeight(products: products, productVariations: variations, customPackage: customPackage) ?? 0
            }
            .combineLatest($isPackageWeightEdited)
            .prefix(while: { (_, isEdited) in !isEdited })
            .map { (weight, _) in
                String(weight)
            }

        // Display calculated weight on UI
        //
        calculatedWeight
            .assign(to: &$totalWeight)

        // With every change of total weight, check with latest calculated weight.
        // If the values are different, we can assume that the weight was manually input,
        // and update `isPackageWeightEdited` to true to complete all Combine streams.
        //
        $totalWeight.withLatestFrom(calculatedWeight)
            .map { (totalWeight, calculatedWeight) -> Bool in
                totalWeight != calculatedWeight
            }
            .assign(to: &$isPackageWeightEdited)
    }

    private func configureResultsControllers() {
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

// MARK: - Helper methods
private extension ShippingLabelPackageDetailsViewModel {
    /// Generate the items rows, creating an element in the array for every item (eg. if there is an item with quantity 3,
    /// we will generate 3 different items), and we will remove virtual products.
    ///
    func generateItemsRows(products: [Product], productVariations: [ProductVariation]) -> [ItemToFulfillRow] {
        var itemsToFulfill: [ItemToFulfillRow] = []
        for item in orderItems {
            let isVariation = item.variationID > 0
            var product: Product?
            var productVariation: ProductVariation?

            if isVariation {
                productVariation = productVariations.first { $0.productVariationID == item.variationID }
            }
            else {
                product = products.first { $0.productID == item.productID }
            }
            if product?.virtual == false || productVariation?.virtual == false {
                var tempItemQuantity = Double(truncating: item.quantity as NSDecimalNumber)

                for _ in 0..<item.quantity.intValue {
                    let attributes = item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }
                    var weight = Double(productVariation?.weight ?? product?.weight ?? "0") ?? 0
                    if tempItemQuantity < 1 {
                        weight *= tempItemQuantity
                    } else {
                        tempItemQuantity -= 1
                    }
                    let unit: String = weightUnit ?? ""
                    let subtitle = Localization.subtitle(weight: weight.description,
                                                         weightUnit: unit,
                                                         attributes: attributes)
                    itemsToFulfill.append(ItemToFulfillRow(productOrVariationID: item.productOrVariationID, title: item.name, subtitle: subtitle))
                }
            }
        }
        return itemsToFulfill
    }

    /// Calculate total weight based on the weight of the selected package if it's a custom package;
    /// And the products and products variation inside the order items, only if they are not virtual products.
    ///
    /// Note: Only custom package is needed for input because only custom packages have weight to be included in the total weight.
    ///
    func calculateTotalWeight(products: [Product], productVariations: [ProductVariation], customPackage: ShippingLabelCustomPackage?) -> Double {
        var tempTotalWeight: Double = 0

        // Add each order item's weight to the total weight.
        for item in orderItems {
            let isVariation = item.variationID > 0
            var product: Product?
            var productVariation: ProductVariation?

            if isVariation {
                productVariation = productVariations.first { $0.productVariationID == item.variationID }
            }
            else {
                product = products.first { $0.productID == item.productID }
            }
            if product?.virtual == false || productVariation?.virtual == false {
                let itemWeight = Double(productVariation?.weight ?? product?.weight ?? "0") ?? 0
                tempTotalWeight += itemWeight * Double(truncating: item.quantity as NSDecimalNumber)
            }
        }

        // Add selected package weight to the total weight.
        // Only custom packages have a defined weight, so we only do this if a custom package is selected.
        if let selectedPackage = customPackage {
            tempTotalWeight += selectedPackage.boxWeight
        }
        return tempTotalWeight
    }
}

// MARK: - UI utils methods
extension ShippingLabelPackageDetailsViewModel {

    // Return true if the done button in the package details screen should be enabled
    func isPackageDetailsDoneButtonEnabled() -> Bool {
        return !selectedPackageID.isNilOrEmpty && totalWeight.isNotEmpty && Double(totalWeight) != 0 && Double(totalWeight) != nil
    }

    func savePackageSelection() {
        onPackageSaveCompletion(selectedPackagesDetails)
    }
}

// MARK: - Package Selection
extension ShippingLabelPackageDetailsViewModel: ShippingLabelPackageSelectionDelegate {
    func didSelectPackage(id: String) {
        selectedPackageID = id
    }

    func didSyncPackages(packagesResponse: ShippingLabelPackagesResponse?) {
        onPackageSyncCompletion(packagesResponse)
    }

    /// Sets the package passed through the init method, or set the last selected package, if any, as the default selected package
    ///
    func setDefaultPackage() {
        guard let selectedPackageID = selectedPackageID ?? resultsControllers?.accountSettings?.lastSelectedPackageID else {
            return
        }
        packageListViewModel.didSelectPackage(selectedPackageID)
        packageListViewModel.confirmPackageSelection()
    }
}

/// API Requests
///
private extension ShippingLabelPackageDetailsViewModel {
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

private extension ShippingLabelPackageDetailsViewModel {
    enum Localization {
        static let subtitleFormat =
            NSLocalizedString("%1$@", comment: "In Shipping Labels Package Details,"
                                + " the pattern used to show the weight of a product. For example, “1lbs”.")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@", comment: "In Shipping Labels Package Details if the product has attributes,"
                                + " the pattern used to show the attributes and weight. For example, “purple, has logo・1lbs”."
                                + " The %1$@ is the list of attributes (e.g. from variation)."
                                + " The %2$@ is the weight with the unit.")
        static func subtitle(weight: String?, weightUnit: String, attributes: [VariationAttributeViewModel]) -> String {
            let attributesText = attributes.map { $0.nameOrValue }.joined(separator: ", ")
            let formatter = WeightFormatter(weightUnit: weightUnit)
            let weight = formatter.formatWeight(weight: weight)
            if attributes.isEmpty {
                return String.localizedStringWithFormat(subtitleFormat, weight, weightUnit)
            } else {
                return String.localizedStringWithFormat(subtitleWithAttributesFormat, attributesText, weight)
            }
        }
        static let selectPackagePlaceholder = NSLocalizedString("Select a package",
                                                                comment: "Placeholder for the selected package in the Shipping Labels Package Details screen")
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension ShippingLabelPackageDetailsViewModel {

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
                                                              providerID: "usps",
                                                              predefinedPackages: predefinedPackages1)

        let predefinedPackages2 = [ShippingLabelPredefinedPackage(id: "LargePaddedPouch",
                                                                  title: "Large Padded Pouch",
                                                                  isLetter: true,
                                                                  dimensions: "30.22 x 35.56 x 2.54")]
        let predefinedOption2 = ShippingLabelPredefinedOption(title: "DHL Express",
                                                              providerID: "dhlexpress",
                                                              predefinedPackages: predefinedPackages2)

        return [predefinedOption1, predefinedOption2]
    }
}
