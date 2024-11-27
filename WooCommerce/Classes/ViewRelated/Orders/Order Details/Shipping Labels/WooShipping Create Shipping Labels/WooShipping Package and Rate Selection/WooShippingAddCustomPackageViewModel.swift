import Foundation
import Yosemite

final class WooShippingAddCustomPackageViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64
    let storeOptions: ShippingLabelStoreOptions

    // Holds values for all dimension input fields.
    // Using a dictionary so we can easily add/remove new types
    // if needed just by adding new case in enum
    @Published var fieldValues: [WooShippingPackageUnitType: String] = [:]
    // Holds selected package type when custom package is selected, it can be `box` or `envelope`
    @Published var packageType: WooShippingPackageType = .box
    // Holds value for toggle that determines if we are showing button for saving the template
    @Published var showSaveTemplate: Bool = false
    @Published var packageTemplateName: String = ""
    @Published var packagesRepository: WooShippingPackagesRepositoryProtocol

    // MARK: Initialization

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         storeOptions: ShippingLabelStoreOptions,
         stores: StoresManager = ServiceLocator.stores,
         packagesRepository: WooShippingPackagesRepositoryProtocol) {
        self.storeOptions = storeOptions
        self.stores = stores
        self.siteID = siteID
        self.packagesRepository = packagesRepository
    }

    // Field values are invalid if one of them is empty
    // - if we are saving template we check all field values
    // - if we are not saving template we check only dimensions
    var areFieldValuesInvalid: Bool {
        let keysToCheck: [WooShippingPackageUnitType] = showSaveTemplate ? WooShippingPackageUnitType.allCases : WooShippingPackageUnitType.dimensionUnits

        var validFieldsCount: Int = 0

        for (key, value) in fieldValues {
            guard keysToCheck.contains(key) else { continue }
            if value.isEmpty {
                return true
            }
            validFieldsCount += 1
        }
        return validFieldsCount != keysToCheck.count
    }

    private var packageDataFromCurrentData: WooShippingPackageDataRepresentable? {
        return WooShippingPackageData(id: UUID().uuidString,
                                      name: packageTemplateName,
                                      length: fieldValues[.length] ?? "",
                                      width: fieldValues[.width] ?? "",
                                      height: fieldValues[.height] ?? "",
                                      dimensionsUnit: storeOptions.dimensionUnit,
                                      weight: fieldValues[.weight] ?? "",
                                      weightUnit: storeOptions.weightUnit,
                                      source: .custom,
                                      packageType: packageType.rawValue)
    }

    private func preparePackageData() -> WooShippingPackageDataRepresentable? {
        guard validateCustomPackageInputFields() else { return nil }

        return packageDataFromCurrentData
    }

    enum Error: Swift.Error {
        case packageDataNotValid
        case failedSavingTemplate
        case failure(Swift.Error)
    }

    func addPackageAction(package: WooShippingPackageDataRepresentable? = nil) async -> Result<WooShippingPackageDataRepresentable, Error> {
        guard let packageData = package ?? preparePackageData() else {
            return .failure(WooShippingAddCustomPackageViewModel.Error.packageDataNotValid)
        }

        // TODO: use WooShippingAction to POST the package to backend
        // - if successful, return the package data
        // - if not, return error

        return .success(packageData)
    }

    @MainActor
    /// Saves custom package as template remotely.
    ///
    func savePackageAsTemplateAction() async -> Result<WooShippingPackageDataRepresentable, Error> {
        guard let packageData = preparePackageData() else {
            return .failure(WooShippingAddCustomPackageViewModel.Error.packageDataNotValid)
        }

        let result =  await packagesRepository.saveCustomPackage(packageData,
                                                                 dimensionsUnit: storeOptions.dimensionUnit,
                                                                 weightUnit: storeOptions.weightUnit,
                                                                 siteID: siteID,
                                                                 stores: stores)
        switch result {
        case .success(let success):
            return .success(success)
        case .failure(let failure):
            return .failure(WooShippingAddCustomPackageViewModel.Error.failure(failure))
        }
    }

    func validateCustomPackageInputFields() -> Bool {
        guard !areFieldValuesInvalid else {
            return false
        }
        if showSaveTemplate {
            return !packageTemplateName.isEmpty
        }
        return true
    }
}

enum WooShippingPackageUnitType: CaseIterable {
    case length, width, height
    case weight
    var name: String {
        switch self {
        case .length:
            return Localization.length
        case .width:
            return Localization.width
        case .height:
            return Localization.height
        case .weight:
            return Localization.packageWeight
        }
    }

    static var dimensionUnits: [WooShippingPackageUnitType] {
        return [.length, .width, .height]
    }
}

extension WooShippingPackageUnitType {
    enum Localization {
        static let length = NSLocalizedString("wooShipping.createLabel.addPackage.length",
                                              value: "Length",
                                              comment: "Info label for length input field")
        static let width = NSLocalizedString("wooShipping.createLabel.addPackage.width",
                                             value: "Width",
                                             comment: "Info label for width input field")
        static let height = NSLocalizedString("wooShipping.createLabel.addPackage.height",
                                              value: "Height",
                                              comment: "Info label for height input field")
        static let packageWeight = NSLocalizedString("wooShipping.createLabel.addPackage.packageWeight",
                                                     value: "Package weight",
                                                     comment: "Info label for weight input field")
    }
}

enum WooShippingPackageType: String, CaseIterable {
    case box, envelope
    var name: String {
        switch self {
        case .box:
            return Localization.box
        case .envelope:
            return Localization.envelope
        }
    }
}

extension WooShippingPackageType {
    enum Localization {
        static let box = NSLocalizedString("wooShipping.createLabel.addPackage.box",
                                           value: "Box",
                                           comment: "Info label for selected box as a package type")
        static let envelope = NSLocalizedString("wooShipping.createLabel.addPackage.envelope",
                                                value: "Envelope",
                                                comment: "Info label for selected envelope as a package type")
    }
}
