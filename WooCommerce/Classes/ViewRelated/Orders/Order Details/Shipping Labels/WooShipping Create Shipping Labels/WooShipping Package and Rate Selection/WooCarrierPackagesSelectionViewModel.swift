import Foundation
import SwiftUI

final class WooCarrierPackagesSelectionViewModel: ObservableObject {
    let carrierTabs: [WooShippingPackagesCarrierTab]
    let tabs: [TopTabItem<EmptyView>]

    init(carrierTabs: [WooShippingPackagesCarrierTab], tabs: [TopTabItem<EmptyView>]) {
        self.carrierTabs = carrierTabs
        self.tabs = tabs
        self.selectedTabIndex = carrierTabs.isEmpty ? nil : 0
    }

    @Published var selectedTabIndex: Int? = nil
    @Published var selectedPackageId: UUID? = nil

    var selectedPackage: WooPackageDataRepresentable? {
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

    var selectedCarrierTab: WooShippingPackagesCarrierTab? {
        guard let selectedTabIndex else { return nil }

        return carrierTabs[selectedTabIndex]
    }
}
