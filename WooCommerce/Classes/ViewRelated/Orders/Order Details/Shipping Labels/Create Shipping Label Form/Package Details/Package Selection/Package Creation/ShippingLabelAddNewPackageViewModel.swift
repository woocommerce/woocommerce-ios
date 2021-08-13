import UIKit
import SwiftUI

/// View model for `ShippingLabelAddNewPackage`.
///
final class ShippingLabelAddNewPackageViewModel: ObservableObject {
    @Published var selectedIndex: Int
    var selectedView: PackageViewType {
        PackageViewType(rawValue: selectedIndex) ?? .customPackage
    }

    init(_ selectedIndex: Int = PackageViewType.customPackage.rawValue) {
        self.selectedIndex = selectedIndex
    }

    enum PackageViewType: Int {
        case customPackage = 0
        case servicePackage = 1
    }
}
