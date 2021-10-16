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

    /// The packages  response fetched from API
    ///
    private var packagesResponse: ShippingLabelPackagesResponse?

    private var cancellables: Set<AnyCancellable> = []

    /// Validation states of all items by ID of each package.
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
    private var selectedPackages: [ShippingLabelPackageAttributes] = [] {
        didSet {
            configureItemViewModels(order: order)
        }
    }

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
        self.packagesResponse = packagesResponse
        self.stores = stores
        self.storageManager = storageManager
        self.selectedPackages = selectedPackages
        self.onSelectionCompletion = onSelectionCompletion
        self.onPackageSyncCompletion = onPackageSyncCompletion

        configureResultsControllers()
        syncProducts()
        syncProductVariations()
        configureDefaultPackage()
        configureItemViewModels(order: order)
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
        guard selectedPackages.isEmpty else {
            return
        }
        let selectedPackageID = resultsControllers?.accountSettings?.lastSelectedPackageID ?? ""
        let items = order.items.compactMap { ShippingLabelPackageItem(orderItem: $0,
                                                                      products: products,
                                                                      productVariations: productVariations) }
        selectedPackages = [ShippingLabelPackageAttributes(packageID: selectedPackageID,
                                                           totalWeight: "",
                                                           items: items)]
    }

    /// Set up item view models on change selected packages.
    ///
    func configureItemViewModels(order: Order) {
        itemViewModels = selectedPackages.enumerated().map { index, details -> ShippingLabelSinglePackageViewModel in
            return .init(id: details.id,
                         order: order,
                         orderItems: details.items,
                         packageNumber: index + 1,
                         packagesResponse: self.packagesResponse,
                         selectedPackageID: details.packageID,
                         totalWeight: details.totalWeight,
                         isOriginalPackaging: details.isOriginalPackaging,
                         onItemMoveRequest: { [weak self] in
                self?.itemViewModels.forEach {
                    $0.dismissPopover()
                }
            },
                         onPackageSwitch: { [weak self] newPackage in
                self?.switchPackage(currentPackage: details, newPackage: newPackage)
            },
                    onPackagesSync: { [weak self] packagesResponse in
                self?.packagesResponse = packagesResponse
                self?.onPackageSyncCompletion(packagesResponse)
            })
        }

        // We need the updated `itemViewModels` to get package names for selection,
        // so we have to update buttons after creating the view models.
        itemViewModels.enumerated().forEach { index, model in
            guard let details = selectedPackages.first(where: { $0.id == model.id }) else {
                return
            }
            let actionSheetButtons = moveItemActionButtons(for: details, packageIndex: index)
            model.updateActionSheetButtons(actionSheetButtons)
        }
        observeItemViewModels()
    }

    /// Update title and buttons for the Move Item action sheet.
    ///
    func moveItemActionButtons(for currentPackage: ShippingLabelPackageAttributes,
                               packageIndex: Int) -> [String: [ActionSheet.Button]] {
        var actionButtons: [String: [ActionSheet.Button]] = [:]
        currentPackage.items
            .forEach { item in
                var buttons: [ActionSheet.Button] = []

                // Add options to move to other packages.
                for (index, package) in selectedPackages.enumerated() {
                    guard !package.isOriginalPackaging else {
                        continue
                    }
                    if index != packageIndex {
                        guard let name = itemViewModels.first(where: { $0.id == package.id })?.packageName else {
                            continue
                        }
                        let packageTitle = String(format: Localization.packageName, index + 1, name)
                        buttons.append(.default(Text(packageTitle), action: { [weak self] in
                            ServiceLocator.analytics.track(.shippingLabelItemMoved, withProperties: ["destination": "existing_package"])
                            self?.moveItem(productOrVariationID: item.productOrVariationID, currentPackageIndex: packageIndex, newPackageIndex: index)
                        }))
                    }
                }

                if !currentPackage.isOriginalPackaging {
                    let hasMultipleItems = currentPackage.items.count > 1 || currentPackage.items.first(where: { $0.quantity > 1 }) != nil
                    if hasMultipleItems {
                        // Add option to add item to new package if current package has more than one item.
                        buttons.append(.default(Text(Localization.addToNewPackage)) { [weak self] in
                            ServiceLocator.analytics.track(.shippingLabelItemMoved, withProperties: ["destination": "new_package"])
                            self?.addItemToNewPackage(productOrVariationID: item.productOrVariationID, packageIndex: packageIndex)
                        })
                    }

                    // Add option to ship in original package
                    buttons.append(.default(Text(Localization.shipInOriginalPackage)) { [weak self] in
                        ServiceLocator.analytics.track(.shippingLabelItemMoved, withProperties: ["destination": "original_packaging"])
                        self?.shipInOriginalPackage(productOrVariationID: item.productOrVariationID, packageIndex: packageIndex)
                    })
                } else {
                    buttons.append(.default(Text(Localization.addToNewPackage)) { [weak self] in
                        ServiceLocator.analytics.track(.shippingLabelItemMoved, withProperties: ["destination": "new_package"])
                        self?.addItemToNewPackage(productOrVariationID: item.productOrVariationID, packageIndex: packageIndex)
                    })
                }
                buttons.append(.cancel())
                actionButtons[item.id] = buttons
            }
        return actionButtons
    }

    /// Move the item with `productOrVariationID` from `currentPackage` to a new package,
    /// and update items within `currentPackage` to reflect the change.
    ///
    func shipInOriginalPackage(productOrVariationID: Int64, packageIndex: Int) {
        var updatedPackages: [ShippingLabelPackageAttributes] = []
        for (index, package) in selectedPackages.enumerated() {
            if index == packageIndex {
                let (matchingItem, updatedItems) = package.partitionItems(using: productOrVariationID)

                guard let matchingItem = matchingItem else {
                    assertionFailure("⛔️ Cannot find item with product or variationID \(productOrVariationID) in current package!")
                    return
                }

                // If the resulting item list is not empty, create a copy of the package with the list.
                if updatedItems.isNotEmpty {
                    let updatedPackage = ShippingLabelPackageAttributes(packageID: package.packageID,
                                                                        totalWeight: package.totalWeight,
                                                                        items: updatedItems)
                    updatedPackages.append(updatedPackage)
                }

                // Create a package with original packaging box ID and the matching item.
                let originalPackage = ShippingLabelPackageAttributes(packageID: ShippingLabelPackageAttributes.originalPackagingBoxID,
                                                                     totalWeight: "",
                                                                     items: [matchingItem])
                updatedPackages.append(originalPackage)
            } else {
                updatedPackages.append(package)
            }
        }
        // This will trigger updating item view models, and therefore updates the package list UI.
        selectedPackages = updatedPackages
    }

    /// Move the item with `productOrVariationID` to a separate non-original package,
    /// and update the old package appropriately.
    ///
    func addItemToNewPackage(productOrVariationID: Int64, packageIndex: Int) {
        guard let currentPackage = selectedPackages[safe: packageIndex] else {
            assertionFailure("⛔️ Cannot find package at index \(packageIndex)")
            return
        }
        var temporaryPackages = selectedPackages
        // Remove current package from list
        temporaryPackages.remove(at: packageIndex)

        if !currentPackage.isOriginalPackaging {
            let (matchingItem, updatedItems) = currentPackage.partitionItems(using: productOrVariationID)

            guard let matchingItem = matchingItem else {
                assertionFailure("⛔️ Cannot find item with product or variationID \(productOrVariationID) in current package!")
                return
            }

            // If the resulting item list is not empty, create a copy of the package with the items,
            // and add the new package to the list.
            if updatedItems.isNotEmpty {
                let updatedPackage = ShippingLabelPackageAttributes(packageID: currentPackage.packageID,
                                                                    totalWeight: "",
                                                                    items: updatedItems)
                temporaryPackages.append(updatedPackage)
            }

            // Create new package with the matching item, using same package ID as current package's
            let newPackage = ShippingLabelPackageAttributes(packageID: currentPackage.packageID,
                                                            totalWeight: "",
                                                            items: [matchingItem])
            temporaryPackages.append(newPackage)
        } else {
            // Get last selected package ID to use as ID of the new package if possible.
            let selectedPackageID = resultsControllers?.accountSettings?.lastSelectedPackageID ?? ""
            let newPackage = ShippingLabelPackageAttributes(packageID: selectedPackageID,
                                                            totalWeight: "",
                                                            items: currentPackage.items)
            temporaryPackages.insert(newPackage, at: packageIndex)
        }
        // This will trigger updating item view models, and therefore updates the package list UI.
        selectedPackages = temporaryPackages
    }

    /// Move the item with `productOrVariationID` to the specified package, and update current package accordingly.
    ///
    func moveItem(productOrVariationID: Int64, currentPackageIndex: Int, newPackageIndex: Int) {
        var temporaryPackages = selectedPackages
        guard let currentPackage = temporaryPackages[safe: currentPackageIndex],
              let newPackage = temporaryPackages[safe: newPackageIndex] else {
            assertionFailure("⛔️ Cannot find package at either of indices \(currentPackageIndex) and \(newPackageIndex)")
            return
        }

        var itemToMove: ShippingLabelPackageItem?
        var updatedCurrentPackage: ShippingLabelPackageAttributes?

        if currentPackage.isOriginalPackaging {
            itemToMove = currentPackage.items.first
        } else {
            let (matchingItem, updatedItems) = currentPackage.partitionItems(using: productOrVariationID)
            itemToMove = matchingItem

            // If the resulting item list is not empty, create a copy of the package with the items,
            // and add the new package to the list.
            if updatedItems.isNotEmpty {
                updatedCurrentPackage = ShippingLabelPackageAttributes(packageID: currentPackage.packageID,
                                                                       totalWeight: "",
                                                                       items: updatedItems)
            }
        }

        guard let itemToMove = itemToMove else {
            assertionFailure("⛔️ Cannot find item with product or variationID \(productOrVariationID) in current package!")
            return
        }
        var newItems = newPackage.items

        // If found an item with the same product or variation ID as the new item, increase its quantity.
        // Otherwise add the new item to the package's item list.
        if let itemIndex = newItems.firstIndex(where: { $0.productOrVariationID == itemToMove.productOrVariationID }) {
            let foundPackage = newItems[itemIndex]
            newItems[itemIndex] = ShippingLabelPackageItem(copy: foundPackage, quantity: foundPackage.quantity + 1)
        } else {
            newItems.append(itemToMove)
        }

        // Create a copy of the new package with updated items
        let updatedNewPackage = ShippingLabelPackageAttributes(packageID: newPackage.packageID,
                                                               totalWeight: "",
                                                               items: newItems)
        temporaryPackages[newPackageIndex] = updatedNewPackage

        if let updatedCurrentPackage = updatedCurrentPackage {
            temporaryPackages[currentPackageIndex] = updatedCurrentPackage
        } else {
            // Remove current package from list
            temporaryPackages.remove(at: currentPackageIndex)
        }

        // This will trigger updating item view models, and therefore updates the package list UI.
        selectedPackages = temporaryPackages
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
        packagesValidation.removeAll()
        itemViewModels.forEach { item in
            item.$isValidPackage
                .sink { [weak self] isValid in
                    self?.packagesValidation[item.id] = isValid && item.selectedPackageID.isNotEmpty
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
        static let packageName = NSLocalizedString("Package %1$d: %2$@",
                                                   comment: "Name of package to be listed in Move Item action sheet " +
                                                   "on Package Details screen of Shipping Label flow.")
        static let shipInOriginalPackage = NSLocalizedString("Ship in Original Packaging",
                                                             comment: "Option to ship in original packaging on action sheet when an order item is about to " +
                                                                "be moved on Package Details screen of Shipping Label flow.")
        static let addToNewPackage = NSLocalizedString("Add to new package",
                                                       comment: "Option to add item to new package on Package Details screen of Shipping Label flow.")
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
