import SwiftUI
import UIKit
import Yosemite

/// Displays the Add New Package screen
final class ShippingLabelAddNewPackageViewController: UIHostingController<ShippingLabelAddNewPackage> {
    init() {
        super.init(rootView: ShippingLabelAddNewPackage())
        configureNavigationBar()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ShippingLabelAddNewPackageViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
    }
}

private extension ShippingLabelAddNewPackageViewController {
    enum Localization {
        static let navigationBarTitle =
            NSLocalizedString("Add New Package",
                              comment: "Navigation bar title of shipping label Add New package screen")
    }
}
