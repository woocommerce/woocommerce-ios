import Combine
import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelSinglePackage`.
///
final class ShippingLabelSinglePackageViewModel: ObservableObject {

    typealias PackageSwitchHandler = (_ newPackage: ShippingLabelPackageAttributes) -> Void
    typealias PackagesSyncHandler = (_ packagesResponse: ShippingLabelPackagesResponse?) -> Void

    /// The id of the selected package. Defaults to last selected package, if any.
    ///
    let selectedPackageID: String

    /// Whether this package is shipped in original packaging.
    ///
    let isOriginalPackaging: Bool

    /// Move Item action buttons for each package item.
    ///
    let moveItemActionButtons: [String: [ActionSheet.Button]]

    /// View model for the package list
    ///
    lazy var packageListViewModel: ShippingLabelPackageListViewModel = {
        .init(siteID: order.siteID, packagesResponse: packagesResponse)
    }()

    @Published var totalWeight: String = ""

    /// Number of package in the list.
    ///
    let packageNumber: Int

    /// The items rows observed by the main view `ShippingLabelPackageItem`
    ///
    @Published private(set) var itemsRows: [ItemToFulfillRow] = []

    /// Whether package is valid.
    ///
    @Published private(set) var isValidPackage = false

    /// Whether totalWeight is valid
    ///
    @Published private(set) var isValidTotalWeight: Bool = false

    /// Whether the original package has valid dimensions.
    ///
    @Published private(set) var hasValidPackageDimensions = false

    /// Description of dimensions of the original package.
    ///
    @Published private(set) var originalPackageDimensions: String = ""

    /// The title of the selected package, if any.
    ///
    var selectedPackageName: String {
        if let selectedCustomPackage = packageListViewModel.selectedCustomPackage {
            return selectedCustomPackage.title
        } else if let selectedPredefinedPackage = packageListViewModel.selectedPredefinedPackage {
            return selectedPredefinedPackage.title
        } else {
            return Localization.selectPackagePlaceholder
        }
    }

    /// The package name to be displayed in Move Item action sheet.
    ///
    var packageName: String {
        if isOriginalPackaging {
            return orderItems.first?.name ?? ""
        }
        return selectedPackageName
    }

    /// Attributes of the package if validated.
    ///
    var validatedPackageAttributes: ShippingLabelPackageAttributes? {
        guard validateTotalWeight(totalWeight) else {
            return nil
        }
        if isOriginalPackaging, !hasValidPackageDimensions {
            return nil
        }
        return ShippingLabelPackageAttributes(packageID: selectedPackageID,
                                              totalWeight: totalWeight,
                                              items: orderItems)
    }

    private let order: Order
    private let orderItems: [ShippingLabelPackageItem]
    private let currency: String
    private let currencyFormatter: CurrencyFormatter
    private let onPackageSwitch: PackageSwitchHandler
    private let onPackagesSync: PackagesSyncHandler

    /// The packages  response fetched from API
    ///
    private var packagesResponse: ShippingLabelPackagesResponse?

    /// The weight unit used in the Store
    ///
    let weightUnit: String?

    /// Whether the user has edited the total package weight. If true, we won't make any automatic changes to the total weight.
    ///
    @Published private var isPackageWeightEdited: Bool = false

    init(order: Order,
         orderItems: [ShippingLabelPackageItem],
         packageNumber: Int,
         packagesResponse: ShippingLabelPackagesResponse?,
         selectedPackageID: String,
         totalWeight: String,
         moveItemActionButtons: [String: [ActionSheet.Button]],
         isOriginalPackaging: Bool = false,
         onPackageSwitch: @escaping PackageSwitchHandler,
         onPackagesSync: @escaping PackagesSyncHandler,
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.order = order
        self.orderItems = orderItems
        self.packageNumber = packageNumber
        self.currency = order.currency
        self.currencyFormatter = formatter
        self.weightUnit = weightUnit
        self.selectedPackageID = selectedPackageID
        self.moveItemActionButtons = moveItemActionButtons
        self.isOriginalPackaging = isOriginalPackaging
        self.onPackageSwitch = onPackageSwitch
        self.onPackagesSync = onPackagesSync
        self.packagesResponse = packagesResponse
        self.packageListViewModel.delegate = self

        packageListViewModel.didSelectPackage(selectedPackageID)
        configureItemRows()
        configureTotalWeight(initialTotalWeight: totalWeight)
        if isOriginalPackaging, let item = orderItems.first {
            configureOriginalPackageDimensions(for: item)
        }
        configureValidation(originalPackaging: isOriginalPackaging)
    }

    private func configureItemRows() {
        itemsRows = generateItemsRows()
    }

    /// Set value for total weight and observe its changes.
    ///
    private func configureTotalWeight(initialTotalWeight: String) {
        let calculatedWeight = calculateTotalWeight(customPackage: packageListViewModel.selectedCustomPackage)
        let localizedCalculatedWeight = NumberFormatter.localizedString(from: NSNumber(value: calculatedWeight)) ?? String(calculatedWeight)
        // Set total weight to initialTotalWeight if it's different from the calculated weight.
        // Otherwise use the calculated weight.
        if initialTotalWeight.isNotEmpty, initialTotalWeight != String(calculatedWeight) {
            isPackageWeightEdited = true
            totalWeight = initialTotalWeight
        } else {
            totalWeight = localizedCalculatedWeight
        }

        $totalWeight
            .map { $0 != localizedCalculatedWeight }
            .assign(to: &$isPackageWeightEdited)

        $totalWeight
            .map { [weak self] in self?.validateTotalWeight($0) ?? false }
            .assign(to: &$isValidTotalWeight)
    }

    /// Configure dimensions L x W x H <unit> for the original package.
    ///
    private func configureOriginalPackageDimensions(for item: ShippingLabelPackageItem) {
        let unit = packagesResponse?.storeOptions.dimensionUnit ?? ""
        let length = item.dimensions.length.isEmpty ? "0" : item.dimensions.length
        let width = item.dimensions.width.isEmpty ? "0" : item.dimensions.width
        let height = item.dimensions.height.isEmpty ? "0" : item.dimensions.height
        originalPackageDimensions = String(format: "%@ x %@ x %@ %@", length, width, height, unit)
        hasValidPackageDimensions = item.dimensions.length.isNotEmpty && item.dimensions.width.isNotEmpty && item.dimensions.height.isNotEmpty
    }

    private func configureValidation(originalPackaging: Bool) {
        $isValidTotalWeight.combineLatest($hasValidPackageDimensions)
            .map { validWeight, validDimensions -> Bool in
                guard originalPackaging else {
                    return validWeight
                }
                return validWeight && validDimensions
            }
            .assign(to: &$isValidPackage)
    }
}

// MARK: ShippingLabelPackageSelectionDelegate conformance
extension ShippingLabelSinglePackageViewModel: ShippingLabelPackageSelectionDelegate {
    func didSelectPackage(id: String) {
        let newTotalWeight = isPackageWeightEdited ? totalWeight : ""
        let newPackage = ShippingLabelPackageAttributes(packageID: id,
                                                        totalWeight: newTotalWeight,
                                                        items: orderItems)

        onPackageSwitch(newPackage)
    }

    func didSyncPackages(packagesResponse: ShippingLabelPackagesResponse?) {
        self.packagesResponse = packagesResponse
        onPackagesSync(packagesResponse)
    }
}

// MARK: - Helper methods
private extension ShippingLabelSinglePackageViewModel {
    /// Generate the items rows, creating an element in the array for every item (eg. if there is an item with quantity 3,
    /// we will generate 3 different items).
    ///
    func generateItemsRows() -> [ItemToFulfillRow] {
        var itemsToFulfill: [ItemToFulfillRow] = []
        for item in orderItems {
            var tempItemQuantity = Double(truncating: item.quantity as NSDecimalNumber)

            for _ in 0..<item.quantity.intValue {
                var weight = item.weight
                if tempItemQuantity < 1 {
                    weight *= tempItemQuantity
                } else {
                    tempItemQuantity -= 1
                }
                let unit: String = weightUnit ?? ""
                let subtitle = Localization.subtitle(weight: weight.description,
                                                     weightUnit: unit,
                                                     attributes: item.attributes)
                let actionSheetTitle = String(format: Localization.moveItemActionSheetMessage, packageNumber, packageName)
                itemsToFulfill.append(ItemToFulfillRow(productOrVariationID: item.productOrVariationID,
                                                       title: item.name,
                                                       subtitle: subtitle,
                                                       moveItemActionSheetTitle: actionSheetTitle,
                                                       moveItemActionSheetButtons: moveItemActionButtons[item.id] ?? []))
            }
        }
        return itemsToFulfill
    }

    /// Calculate total weight based on the weight of the selected package if it's a custom package;
    /// And the weight of items contained in the package.
    ///
    /// Note: Only custom package is needed for input because only custom packages have weight to be included in the total weight.
    ///
    func calculateTotalWeight(customPackage: ShippingLabelCustomPackage?) -> Double {
        var tempTotalWeight: Double = 0

        // Add each order item's weight to the total weight.
        for item in orderItems {
            tempTotalWeight += item.weight * Double(truncating: item.quantity as NSDecimalNumber)
        }

        // Add selected package weight to the total weight.
        // Only custom packages have a defined weight, so we only do this if a custom package is selected.
        if let selectedPackage = customPackage {
            tempTotalWeight += selectedPackage.boxWeight
        }
        return tempTotalWeight
    }

    /// Validate that total weight is a valid floating point number.
    ///
    func validateTotalWeight(_ totalWeight: String) -> Bool {
        guard totalWeight.isNotEmpty,
              let value = NumberFormatter.double(from: totalWeight) else {
            return false
        }
        return value > 0
    }
}

private extension ShippingLabelSinglePackageViewModel {
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
        static let moveItemActionSheetMessage = NSLocalizedString("This item is currently in Package %1$d: %2$@. Where would you like to move it?",
                                                                  comment: "Message in action sheet when an order item is about to " +
                                                                    "be moved on Package Details screen of Shipping Label flow." +
                                                                    "The package name reads like: Package 1: Custom Envelope.")
    }
}
