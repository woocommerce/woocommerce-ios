import Foundation

final class WooSavedPackagesSelectionViewModel: ObservableObject {
    @Published var packagesRepository: WooShippingPackagesRepository
    @Published var selectedPackageId: UUID? = nil  // Track the selected package index

    var customSavedPackages: [any WooPackageDataRepresentable] {
        return packagesRepository.customSavedPackages
    }

    var predefinedSavedPackages: [any WooPackageDataRepresentable] {
        return packagesRepository.predefinedSavedPackages
    }

    init(packagesRepository: WooShippingPackagesRepository) {
        self.packagesRepository = packagesRepository
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

    func removePackage(_ packageToRemove: WooPackageDataRepresentable, onCompletion: @escaping (Error?) -> Void) {
        packagesRepository.deleteSavedPackage(packageToRemove) { error in
            if error == nil {
                if self.selectedPackageId == packageToRemove.id {
                    self.selectedPackageId = nil
                }
            }
            onCompletion(error)
        }
    }
}
