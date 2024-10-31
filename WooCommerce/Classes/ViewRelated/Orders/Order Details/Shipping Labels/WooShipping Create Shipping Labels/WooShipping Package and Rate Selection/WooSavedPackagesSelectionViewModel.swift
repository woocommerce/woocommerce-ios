import Foundation

final class WooSavedPackagesSelectionViewModel: ObservableObject {
    let packages: [any WooPackageDataRepresentable]
    @Published var selectedPackageId: UUID? = nil  // Track the selected package index

    init(packages: [any WooPackageDataRepresentable]) {
        self.packages = packages
    }

    var selectedPackage: WooPackageDataRepresentable? {
        guard let selectedPackageId else { return nil }

        for packageItem in packages {
            if selectedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }
}
