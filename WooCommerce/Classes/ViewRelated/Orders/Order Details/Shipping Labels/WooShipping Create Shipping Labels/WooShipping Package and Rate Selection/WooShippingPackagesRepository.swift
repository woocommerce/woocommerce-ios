import Foundation

final class WooShippingPackagesRepository: ObservableObject {
    @Published var loadingSavedPackages: Bool = false
    @Published var customSavedPackages: [any WooPackageDataRepresentable] = []
    @Published var predefinedSavedPackages: [any WooPackageDataRepresentable] = []
    @Published var loadingCarrierPackages: Bool = false
    @Published var carrierPackages: [WooShippingCarrierPackages] = []

    // MARK: - Packages loading

    func loadPackages() {
        loadSavedPackages()
        loadCarrierPackages()
    }

    func loadSavedPackages() {
        loadingSavedPackages = true

        // TODO: add networking request to load live data

        customSavedPackages = [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
        ]
        predefinedSavedPackages = [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "DHL Express",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "USPS Priority Mail Flat Rate Boxes",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
        ]

        loadingSavedPackages = false
    }

    func loadCarrierPackages() {
        loadingCarrierPackages = true

        // TODO: add networking request to load live data

        loadingCarrierPackages = false
    }

    // MARK: - Packages updates

    func deleteSavedPackage(_ packageToRemove: WooPackageDataRepresentable, onCompletion: @escaping (Error?) -> Void) {
        // delete the package locally and on backend
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        // do we need a special logic for custom packages and carrier packages?

        // call onCompletion with error if some error happens
        onCompletion(nil)
    }

    func addCustomPackage(_ packageToAdd: WooPackageDataRepresentable, onCompletion: @escaping (Error?) -> Void) {
        customSavedPackages.append(packageToAdd)
        onCompletion(nil)
    }

    func addPredefinedPackage(_ packageToAdd: WooPackageDataRepresentable, onCompletion: @escaping (Error?) -> Void) {
        predefinedSavedPackages.append(packageToAdd)
        onCompletion(nil)
    }
}
