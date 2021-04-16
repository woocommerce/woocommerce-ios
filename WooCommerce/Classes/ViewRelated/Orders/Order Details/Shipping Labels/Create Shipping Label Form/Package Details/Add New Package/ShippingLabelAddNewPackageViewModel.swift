import UIKit
import SwiftUI

/// View model for `ShippingLabelAddNewPackage`.
///
final class ShippingLabelAddNewPackageViewModel: ObservableObject {
    @Published var selectedIndex: Int

    init(_ selectedIndex: Int = SelectedIndex.servicePackage.rawValue) {
        self.selectedIndex = selectedIndex
    }

    enum SelectedIndex: Int {
        case customPackage = 0
        case servicePackage = 1
    }
}
