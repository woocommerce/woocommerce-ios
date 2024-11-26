import Foundation
import SwiftUI
import Combine

final class WooCarrierPackagesSelectionViewModel: ObservableObject {
    @Published private var packagesRepository: WooShippingPackagesRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.forEach {
            $0.cancel()
        }
    }

    var tabs: [TopTabItem<EmptyView>] {
        return carrierTabs.map { carrierTab in
            return TopTabItem(name: carrierTab.carrier.name, icon: carrierTab.carrier.logo, content: {
                EmptyView()
            })
        }
    }

    var carrierTabs: [WooShippingCarrierPackages] {
        return packagesRepository.carrierPackages
    }

    init(packagesRepository: WooShippingPackagesRepositoryProtocol) {
        self.packagesRepository = packagesRepository
        self.selectedTabIndex = carrierTabs.isEmpty ? nil : 0
        packagesRepository.carrierPackagesPublisher.sink { [weak self] _ in
            self?.carrierPackagesUpdated()
        }.store(in: &cancellables)
    }

    private func carrierPackagesUpdated() {
        if selectedTabIndex == nil {
            self.selectedTabIndex = carrierTabs.isEmpty ? nil : 0
        }
    }

    @Published var selectedTabIndex: Int? = nil
    @Published var selectedPackageId: String? = nil

    var selectedPackage: WooShippingPackageDataRepresentable? {
        guard let selectedPackageId else { return nil }

        for carrierTab in carrierTabs {
            for packageGroup in carrierTab.packageGroups {
                for packageItem in packageGroup.packages {
                    if selectedPackageId == packageItem.id {
                        return packageItem
                    }
                }
            }
        }

        return nil
    }

    var selectedCarrierTab: WooShippingCarrierPackages? {
        guard let selectedTabIndex else { return nil }

        return carrierTabs[selectedTabIndex]
    }

    func isPackageStarred(_ package: WooShippingPackageDataRepresentable) -> Bool {
        return packagesRepository.predefinedSavedPackages.contains { savedPackage in
            savedPackage.id == package.id
        }
    }

    func unstarPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        return await packagesRepository.deleteSavedPackage(packageToRemove)
    }

    func starPackage(_ packageToAdd: WooShippingPackageDataRepresentable) async -> Error? {
        return await packagesRepository.savePredefinedPackage(packageToAdd)
    }
}
