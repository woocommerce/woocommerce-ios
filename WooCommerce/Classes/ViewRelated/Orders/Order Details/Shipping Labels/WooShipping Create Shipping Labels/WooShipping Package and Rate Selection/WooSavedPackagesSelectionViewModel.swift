import Foundation

final class WooSavedPackagesSelectionViewModel: ObservableObject {
    @Published var packagesRepository: WooShippingPackagesRepositoryProtocol
    @Published var selectedPackageId: UUID?  // Track the selected package index

    var customSavedPackages: [any WooPackageDataRepresentable] {
        return packagesRepository.customSavedPackages
    }

    var predefinedSavedPackages: [any WooPackageDataRepresentable] {
        return packagesRepository.predefinedSavedPackages
    }

    init(packagesRepository: WooShippingPackagesRepositoryProtocol, selectedPackageId: UUID? = nil) {
        self.packagesRepository = packagesRepository
        self.selectedPackageId = selectedPackageId
    }

    var hasPackages: Bool {
        return customSavedPackages.isNotEmpty || predefinedSavedPackages.isNotEmpty
    }

    var selectedPackage: WooPackageDataRepresentable? {
        guard let selectedPackageId else { return nil }

        let packages = customSavedPackages + predefinedSavedPackages

        for packageItem in packages {
            if selectedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }

    func removePackage(_ packageToRemove: WooPackageDataRepresentable) async -> Error? {
        if let error = await packagesRepository.deleteSavedPackage(packageToRemove) {
            return error
        }
        if self.selectedPackageId == packageToRemove.id {
            self.selectedPackageId = nil
        }
        return nil
    }
}
