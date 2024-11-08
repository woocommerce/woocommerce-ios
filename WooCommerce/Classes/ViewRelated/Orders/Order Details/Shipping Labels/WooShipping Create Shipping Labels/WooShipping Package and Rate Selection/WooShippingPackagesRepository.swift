import Foundation

protocol WooShippingPackagesRepositoryProtocol {
    var loadingSavedPackages: Bool { get }
    var customSavedPackages: [any WooShippingPackageDataRepresentable] { get }
    var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] { get }

    var loadingCarrierPackages: Bool { get }
    var carrierPackages: [WooShippingCarrierPackages] { get }

    func loadPackages()
    func loadSavedPackages()
    func loadCarrierPackages()

    func deleteSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error?
    func addCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error?
    func addPredefinedPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error?
}

final class WooShippingPackagesRepository: ObservableObject, WooShippingPackagesRepositoryProtocol {
    @Published private(set) var loadingSavedPackages: Bool = false
    @Published private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var loadingCarrierPackages: Bool = false
    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []

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

        loadingCarrierPackages = false
    }

    // MARK: - Packages updates

    func deleteSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        // delete the package locally and on backend
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        // do we need a special logic for custom packages and carrier packages?

        // return error if some error happens
        return nil
    }

    func addCustomPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error? {
        customSavedPackages.append(packageToAdd)

        return nil
    }

    func addPredefinedPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error? {
        predefinedSavedPackages.append(packageToAdd)

        return nil
    }
}
