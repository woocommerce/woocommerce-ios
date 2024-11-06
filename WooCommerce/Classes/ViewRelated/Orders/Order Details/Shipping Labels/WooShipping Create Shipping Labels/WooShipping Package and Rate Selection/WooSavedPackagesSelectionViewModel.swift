import Foundation

final class WooSavedPackagesSelectionViewModel: ObservableObject {
    @Published var packagesRepository: WooShippingPackagesRepository
    @Published var selectedPackageId: UUID? = nil  // Track the selected package index

    init(packagesRepository: WooShippingPackagesRepository) {
        self.packagesRepository = packagesRepository
    }

    var selectedPackage: WooPackageDataRepresentable? {
        guard let selectedPackageId else { return nil }

        for packageItem in packagesRepository.savedPackages {
            if selectedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }

    var packages: [any WooPackageDataRepresentable] {
        return packagesRepository.savedPackages
    }
}
