import ARKit
import Experiments
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

final class WooShippingAddCustomPackageViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService

    // Holds values for all dimension input fields.
    // Using a dictionary so we can easily add/remove new types
    // if needed just by adding new case in enum
    @Published var fieldValues: [WooShippingPackageUnitType: String]
    // Holds selected package type when custom package is selected, it can be `box` or `envelope`
    @Published var packageType: WooShippingPackageType
    // Holds value for toggle that determines if we are showing button for saving the template
    @Published var showSaveTemplate: Bool = false
    @Published var packageTemplateName: String = ""

    var isARParcelFittingAvailable: Bool {
        featureFlagService.isFeatureFlagEnabled(.arParcelFitting)
        && ARWorldTrackingConfiguration.isSupported
    }

    var packageID: String {
        packageTemplateName.isEmpty ? Constants.defaultBoxID : packageTemplateName
    }

    // MARK: Initialization

    init(selectedPackage: WooShippingPackageDataRepresentable? = nil,
         siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.siteID = siteID
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        if let selectedPackage {
            fieldValues = [
                .length: selectedPackage.length,
                .width: selectedPackage.width,
                .height: selectedPackage.height
            ]
            packageType = WooShippingPackageType(rawValue: selectedPackage.packageType) ?? .box
        } else {
            fieldValues = [:]
            packageType = .box
        }
    }

    // Field values are invalid if one of them is incomplete
    // - if we are saving template we check all field values
    // - if we are not saving template we check only dimensions
    var areFieldValuesIncomplete: Bool {
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

    /// Ensure that all dimensions are larger than 0
    var allDimensionsValid: Bool {
        let keysToCheck = WooShippingPackageUnitType.dimensionUnits
        for (key, value) in fieldValues {
            guard keysToCheck.contains(key) else { continue }
            let doubleValue = Double(value)
            guard let doubleValue, doubleValue > 0 else {
                return false
            }
        }
        return true
    }

    private var packageDataFromCurrentData: WooShippingPackageDataRepresentable {
        return WooShippingPackageData(id: packageID,
                                      name: packageTemplateName,
                                      length: fieldValues[.length] ?? "",
                                      width: fieldValues[.width] ?? "",
                                      height: fieldValues[.height] ?? "",
                                      weight: fieldValues[.weight] ?? "",
                                      source: .custom,
                                      packageType: packageType.rawValue)
    }

    var packageData: WooShippingPackageDataRepresentable? {
        guard validateCustomPackageInputFields() else { return nil }

        return packageDataFromCurrentData
    }

    enum Error: Swift.Error {
        case packageDataNotValid
        case failedSavingTemplate
        case failure(Swift.Error)
    }

    @MainActor
    /// Saves custom package as template remotely.
    ///
    func savePackageAsTemplateAction() async -> Result<WooShippingPackageDataRepresentable, Error> {
        guard let packageData else {
            return .failure(WooShippingAddCustomPackageViewModel.Error.packageDataNotValid)
        }

        let customPackage = WooShippingCustomPackage(id: "",
                                                     name: packageData.name,
                                                     rawType: packageData.packageType,
                                                     dimensions: "\(packageData.length) x \(packageData.width) x \(packageData.height)",
                                                     boxWeight: Double(packageData.weight) ?? 0)
        let result: Result<WooShippingPackageDataRepresentable, Error> = await withCheckedContinuation { continuation in
            let action = WooShippingAction.createPackage(siteID: siteID,
                                                         customPackage: customPackage,
                                                         predefinedOption: nil) { result in
                switch result {
                case let .success(packages):
                    guard let savedPackage = packages.customPackages.first(where: { $0.name == customPackage.name }) else {
                        return continuation.resume(returning: .failure(WooShippingAddCustomPackageViewModel.Error.failedSavingTemplate))
                    }
                    let packageData = WooShippingPackageData(id: savedPackage.id,
                                                             name: savedPackage.name,
                                                             length: savedPackage.getLength().description,
                                                             width: savedPackage.getWidth().description,
                                                             height: savedPackage.getHeight().description,
                                                             weight: savedPackage.boxWeight.description,
                                                             source: .custom,
                                                             packageType: savedPackage.rawType)
                    continuation.resume(returning: .success(packageData))
                case let .failure(error):
                    DDLogError("⛔️ Error saving custom package with WCShip: \(error)")
                    continuation.resume(returning: .failure(WooShippingAddCustomPackageViewModel.Error.failure(error)))
                }
            }
            stores.dispatch(action)
        }

        switch result {
        case .success(let success):
            analytics.track(event: .WooShipping.packageSelectionStep(state: .savingSuccess))
            return .success(success)
        case .failure(let failure):
            analytics.track(event: .WooShipping.packageSelectionStep(state: .savingFailed, error: failure))
            return .failure(WooShippingAddCustomPackageViewModel.Error.failure(failure))
        }
    }

    func validateCustomPackageInputFields() -> Bool {
        if areFieldValuesIncomplete {
            return false
        }
        if showSaveTemplate {
            return !packageTemplateName.isEmpty
        }
        return true
    }
}

private extension WooShippingAddCustomPackageViewModel {
    enum Constants {
        static let defaultBoxID = "custom_box"
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
