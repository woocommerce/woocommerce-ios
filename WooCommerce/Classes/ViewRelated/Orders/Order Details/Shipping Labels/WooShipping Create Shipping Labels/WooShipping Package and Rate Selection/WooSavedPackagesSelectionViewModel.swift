import Foundation

final class WooSavedPackagesSelectionViewModel: ObservableObject {
    @Published var customPackages: [any WooPackageDataRepresentable]
    @Published var predefinedPackages: [any WooPackageDataRepresentable]
    @Published var selectedPackageId: UUID? = nil  // Track the selected package index

    init(customPackages: [any WooPackageDataRepresentable],
         predefinedPackages: [any WooPackageDataRepresentable]) {
        self.customPackages = customPackages
        self.predefinedPackages = predefinedPackages
    }

    var hasPackages: Bool {
        return customPackages.isNotEmpty || predefinedPackages.isNotEmpty
    }

    var selectedPackage: WooPackageDataRepresentable? {
        guard let selectedPackageId else { return nil }

        let packages = customPackages + predefinedPackages

        for packageItem in packages {
            if selectedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }

    func removePackage(_ packageToRemove: WooPackageDataRepresentable) {
        customPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedPackages.removeAll { package in package.id == packageToRemove.id }

        if selectedPackageId == packageToRemove.id {
            selectedPackageId = nil
        }
    }
}
