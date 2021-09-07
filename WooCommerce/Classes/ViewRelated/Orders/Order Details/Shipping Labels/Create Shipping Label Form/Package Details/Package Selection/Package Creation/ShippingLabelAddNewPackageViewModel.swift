import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelAddNewPackage`.
///
final class ShippingLabelAddNewPackageViewModel: ObservableObject {
    @Published var selectedIndex: Int
    var selectedView: PackageViewType {
        PackageViewType(rawValue: selectedIndex) ?? .customPackage
    }

    // View models for child views (tabs)
    let customPackageVM = ShippingLabelCustomPackageFormViewModel()
    let servicePackageVM: ShippingLabelServicePackageListViewModel

    init(_ selectedIndex: Int = PackageViewType.customPackage.rawValue,
         packagesResponse: ShippingLabelPackagesResponse?) {
        self.selectedIndex = selectedIndex
        self.servicePackageVM = ShippingLabelServicePackageListViewModel(packagesResponse: packagesResponse)
    }

    enum PackageViewType: Int {
        case customPackage = 0
        case servicePackage = 1
    }
}
