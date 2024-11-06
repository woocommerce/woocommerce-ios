import Foundation

final class WooShippingPackagesRepository: ObservableObject {
    @Published var loadingSavedPackages: Bool = false
    @Published var savedPackages: [any WooPackageDataRepresentable] = []
    @Published var loadingCarrierPackages: Bool = false
    @Published var carrierPackages: [WooShippingCarrierPackages] = []

    func loadPackages() {
        loadSavedPackages()
        loadCarrierPackages()
    }

    func loadSavedPackages() {
        loadingSavedPackages = true

        // TODO: add networking request to load live data

        savedPackages = [
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "DHL Express",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "USPS Priority Mail Flat Rate Boxes",
                                packageType: "box",
                                dimensions: "21.92 × 13.67 × 4.14 cm",
                                weight: "5 kg"),
            WooSavedPackageData(name: "Small Flat Rate Box",
                                type: "Custom package",
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
}
