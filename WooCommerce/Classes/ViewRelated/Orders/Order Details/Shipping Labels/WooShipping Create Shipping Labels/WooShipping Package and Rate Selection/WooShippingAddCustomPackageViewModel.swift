import Foundation
import Yosemite

final class WooShippingAddCustomPackageViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64

    // Holds values for all dimension input fields.
    // Using a dictionary so we can easily add/remove new types
    // if needed just by adding new case in enum
    @Published var fieldValues: [WooShippingPackageUnitType: String] = [:]
    // Holds selected package type when custom package is selected, it can be `box` or `envelope`
    @Published var packageType: WooShippingPackageType = .box
    // Holds value for toggle that determines if we are showing button for saving the template
    @Published var showSaveTemplate: Bool = false
    @Published var packageTemplateName: String = ""
    @Published var storeOptions: ShippingLabelStoreOptions?
    @Published var isLoadingStoreOptions: Bool = false
    // MARK: Initialization

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         storeOptions: ShippingLabelStoreOptions? = nil,
         stores: StoresManager = ServiceLocator.stores) {
        self.storeOptions = storeOptions
        self.stores = stores
        self.siteID = siteID
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

    func clearFieldValues() {
        fieldValues.removeAll()
    }

    func resetValues() {
        clearFieldValues()
        packageType = .box
        showSaveTemplate = false
        packageTemplateName = ""
    }

    private var packageDataFromCurrentData: WooShippingPackageDataRepresentable? {
        guard let storeOptions else {
            return nil
        }
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

    func addPackageAction() -> WooShippingPackageDataRepresentable? {
        let packageData = preparePackageData()

        // Cleanup after adding package
        resetValues()

        // TODO: implement adding a package with the package data
        return packageData
    }

    @MainActor
    /// Saves custom package as template remotely.
    ///
    func savePackageAsTemplateAction() async -> WooShippingPackageDataRepresentable? {
        guard let packageData = preparePackageData(), let storeOptions else {
            return nil
        }
        let customPackage = WooShippingCustomPackage(id: "",
                                                     name: packageData.name,
                                                     rawType: packageData.packageType,
                                                     dimensions: "\(packageData.length) x \(packageData.width) x \(packageData.height)",
                                                     boxWeight: Double(packageData.weight) ?? 0)
        return await withCheckedContinuation { continuation in
            let action = WooShippingAction.createPackage(siteID: siteID,
                                                         customPackage: customPackage,
                                                         predefinedOption: nil) { [weak self] result in
                switch result {
                case let .success(packages):
                    guard let self, let savedPackage = packages.customPackages.first(where: { $0.name == customPackage.name }) else {
                        return continuation.resume(returning: nil)
                    }
                    let packageData = WooShippingPackageData(id: savedPackage.id,
                                                             name: savedPackage.name,
                                                             length: savedPackage.getLength().description,
                                                             width: savedPackage.getWidth().description,
                                                             height: savedPackage.getHeight().description,
                                                             dimensionsUnit: storeOptions.dimensionUnit,
                                                             weight: savedPackage.boxWeight.description,
                                                             weightUnit: storeOptions.weightUnit,
                                                             source: .custom,
                                                             packageType: savedPackage.rawType)
                    // Cleanup after package is successfully saved
                    resetValues()
                    continuation.resume(returning: packageData)
                case let .failure(error):
                    DDLogError("⛔️ Error saving custom package with WCShip: \(error)")
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
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

    func loadStoreOptions() {
        guard isLoadingStoreOptions == false else { return }

        isLoadingStoreOptions = true

        let action = WooShippingAction.loadAccountSettings(siteID: siteID) { result in
            switch result {
            case .success(let settings):
                self.storeOptions = settings.storeOptions
            case .failure(let error):
                // TODO: what to do if we do not have store options?
                DDLogError("⛔️ Error loading account settings: \(error)")
            }
            self.isLoadingStoreOptions = false
        }
        ServiceLocator.stores.dispatch(action)
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
