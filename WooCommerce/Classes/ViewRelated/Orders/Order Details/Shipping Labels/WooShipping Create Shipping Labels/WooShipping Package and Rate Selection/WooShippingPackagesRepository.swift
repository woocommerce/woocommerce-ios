import Foundation

protocol WooShippingPackagesRepositoryProtocol {
    var loadingSavedPackages: Bool { get }
    var customSavedPackages: [any WooShippingPackageDataRepresentable] { get }
    var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] { get }

    var loadingCarrierPackages: Bool { get }
    var carrierPackages: [WooShippingCarrierPackages] { get }
    var carrierPackagesPublisher: Published<[WooShippingCarrierPackages]>.Publisher { get }

    func loadPackages()
    func loadSavedPackages()
    func loadCarrierPackages()

    func deleteSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error?
    func saveCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error?
    func savePredefinedPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error?
}

enum WooShippingPackagesRepositoryError: Swift.Error {
    case customPackageWithSameIdAlreadyExists
    case predefinedPackageWithSameIdAlreadyExists
}

final class WooShippingPackagesRepository: ObservableObject, WooShippingPackagesRepositoryProtocol {
    @Published private(set) var loadingSavedPackages: Bool = false
    @Published private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var loadingCarrierPackages: Bool = false
    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []
    var carrierPackagesPublisher: Published<[WooShippingCarrierPackages]>.Publisher { $carrierPackages }

    static let shared = WooShippingPackagesRepository()

    // MARK: - Packages loading

    func loadPackages() {
        loadSavedPackages()
        loadCarrierPackages()
    }

    func loadSavedPackages() {
        guard !loadingSavedPackages else {
            return
        }

        loadingSavedPackages = true

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

        loadingSavedPackages = false
    }

    func loadCarrierPackages() {
        guard !loadingCarrierPackages else {
            return
        }

        loadingCarrierPackages = true

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

        loadingCarrierPackages = false
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
    func saveCustomPackage(_ packageToAdd: any WooShippingPackageDataRepresentable) async -> Error? {
        guard !customSavedPackages.contains(where: { package in
            return package.id == packageToAdd.id
        })  else {
            return WooShippingPackagesRepositoryError.customPackageWithSameIdAlreadyExists
        }
        customSavedPackages.append(packageToAdd)
        return nil
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
