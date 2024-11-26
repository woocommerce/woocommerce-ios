import Foundation

final class WooSavedPackagesSelectionViewModel: ObservableObject {
    @Published private var packagesRepository: WooShippingPackagesRepositoryProtocol
    @Published var selectedPackageId: String?  // Track the selected package index

    var customSavedPackages: [any WooShippingPackageDataRepresentable] {
        return packagesRepository.customSavedPackages
    }

    var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] {
        return packagesRepository.predefinedSavedPackages
    }

    init(packagesRepository: WooShippingPackagesRepositoryProtocol, selectedPackageId: String? = nil) {
        self.packagesRepository = packagesRepository
        self.selectedPackageId = selectedPackageId
    }

    var hasPackages: Bool {
        return customSavedPackages.isNotEmpty || predefinedSavedPackages.isNotEmpty
    }

    var loadingPackages: Bool {
        return packagesRepository.loadingPackages
    }

    var selectedPackage: WooShippingPackageDataRepresentable? {
        guard let selectedPackageId else { return nil }

        let packages = customSavedPackages + predefinedSavedPackages

        for packageItem in packages {
            if selectedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }

    func loadPackages() {
        packagesRepository.loadPackages()
    }

    func removePackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        if let error = await packagesRepository.deleteSavedPackage(packageToRemove) {
            return error
        }
        if self.selectedPackageId == packageToRemove.id {
            self.selectedPackageId = nil
        }
        return nil
    }
}
