import Foundation
import Yosemite

protocol WooShippingPackagesRepositoryProtocol {
    var customSavedPackages: [any WooShippingPackageDataRepresentable] { get }
    var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] { get }

    var carrierPackages: [WooShippingCarrierPackages] { get }
    var carrierPackagesPublisher: Published<[WooShippingCarrierPackages]>.Publisher { get }

    var loadingPackages: Bool { get }

    func loadPackages()

    func deleteSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error?
    func saveCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable,
                           dimensionsUnit: String,
                           weightUnit: String,
                           siteID: Int64,
                           stores: StoresManager) async -> Error?
    func savePredefinedPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error?
}

enum WooShippingPackagesRepositoryError: Swift.Error {
    case customPackageWithSameIdAlreadyExists
    case predefinedPackageWithSameIdAlreadyExists
    case failedSavingTemplate
}

final class WooShippingPackagesRepository: ObservableObject, WooShippingPackagesRepositoryProtocol {
    @Published private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var loadingPackages: Bool = false
    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []
    var carrierPackagesPublisher: Published<[WooShippingCarrierPackages]>.Publisher { $carrierPackages }

    static let shared = WooShippingPackagesRepository()

    // MARK: - Packages loading

    func loadPackages() {
        guard !loadingPackages else {
            return
        }

        loadingPackages = true

        // TODO: add networking request to load live data
        if customSavedPackages.isEmpty {
            customSavedPackages = [
                WooShippingPackageData(id: UUID().uuidString,
                                    name: "Small Flat Rate Box",
                                    length: "21.92",
                                    width: "13.67",
                                    height: "4.14",
                                    dimensionsUnit: "cm",
                                    weight: "5",
                                    weightUnit: "kg",
                                    source: .custom,
                                    packageType: "box"),
                WooShippingPackageData(id: UUID().uuidString,
                                    name: "Small Flat Rate Box",
                                    length: "21.92",
                                    width: "13.67",
                                    height: "4.14",
                                    dimensionsUnit: "cm",
                                    weight: "5",
                                    weightUnit: "kg",
                                    source: .custom,
                                    packageType: "box"),
                WooShippingPackageData(id: UUID().uuidString,
                                    name: "Small Flat Rate Box",
                                    length: "21.92",
                                    width: "13.67",
                                    height: "4.14",
                                    dimensionsUnit: "cm",
                                    weight: "5",
                                    weightUnit: "kg",
                                    source: .custom,
                                    packageType: "box"),
            ]
        }
        if predefinedSavedPackages.isEmpty {
            predefinedSavedPackages = [
                WooShippingPackageData(name: "Small Flat Rate Box 3",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 22",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
            ]
        }

        // TODO: add networking request to load live data
        let uspsPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 1",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box")
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 2",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 21",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 22",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
            ])
        ]
        let dhlPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 3", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 3",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 4", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 4",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
            ])
        ]
        let uspsCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.usps, packageGroups: uspsPackageGroups)
        let dhlCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.dhlExpress, packageGroups: dhlPackageGroups)

        carrierPackages = [uspsCarrier, dhlCarrier]

        loadingPackages = false
    }

    // MARK: - Packages updates

    @MainActor
    func deleteSavedPackage(_ packageToRemove: any WooShippingPackageDataRepresentable) async -> Error? {
        // delete the package locally and on backend
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        // do we need a special logic for custom packages and carrier packages?

        // return error if some error happens
        return nil
    }

    @MainActor
    func saveCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable,
                           dimensionsUnit: String,
                           weightUnit: String, siteID:
                           Int64, stores: StoresManager) async -> Error? {
        guard !customSavedPackages.contains(where: { package in
            return package.id == packageToAdd.id
        })  else {
            return WooShippingPackagesRepositoryError.customPackageWithSameIdAlreadyExists
        }

        let customPackage = WooShippingCustomPackage(id: "",
                                                     name: packageToAdd.name,
                                                     rawType: packageToAdd.packageType,
                                                     dimensions: "\(packageToAdd.length) x \(packageToAdd.width) x \(packageToAdd.height)",
                                                     boxWeight: Double(packageToAdd.weight) ?? 0)
        let savingPackageTemplateResult: Result<WooShippingPackageDataRepresentable, Error> = await withCheckedContinuation { continuation in
            let action = WooShippingAction.createPackage(siteID: siteID,
                                                         customPackage: customPackage,
                                                         predefinedOption: nil) { [weak self] result in
                switch result {
                case let .success(packages):
                    guard let self, let savedPackage = packages.customPackages.first(where: { $0.name == customPackage.name }) else {
                        return continuation.resume(returning: .failure(WooShippingAddCustomPackageViewModel.Error.failedSavingTemplate))
                    }
                    let packageData = WooShippingPackageData(id: savedPackage.id,
                                                             name: savedPackage.name,
                                                             length: savedPackage.getLength().description,
                                                             width: savedPackage.getWidth().description,
                                                             height: savedPackage.getHeight().description,
                                                             dimensionsUnit: dimensionsUnit,
                                                             weight: savedPackage.boxWeight.description,
                                                             weightUnit: weightUnit,
                                                             source: .custom,
                                                             packageType: savedPackage.rawType)
                    continuation.resume(returning: .success(packageData))
                case let .failure(error):
                    DDLogError("⛔️ Error saving custom package with WCShip: \(error)")
                    continuation.resume(returning: .failure(WooShippingPackagesRepositoryError.failedSavingTemplate))
                }
            }
            stores.dispatch(action)
        }
        switch savingPackageTemplateResult {
        case .success(let savedPackage):
            // append saved package so it is immediately available in UI without extra backend calls
            customSavedPackages.append(savedPackage)
            return nil
        case .failure(let error):
            return error
        }
    }

    @MainActor
    func savePredefinedPackage(_ packageToAdd: any WooShippingPackageDataRepresentable) async -> Error? {
        guard !predefinedSavedPackages.contains(where: { package in
            return package.id == packageToAdd.id
        })  else {
            return WooShippingPackagesRepositoryError.predefinedPackageWithSameIdAlreadyExists
        }
        predefinedSavedPackages.append(packageToAdd)
        return nil
    }
}
