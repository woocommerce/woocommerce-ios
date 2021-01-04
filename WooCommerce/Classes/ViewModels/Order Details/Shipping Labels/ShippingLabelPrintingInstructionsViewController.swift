import SwiftUI
import UIKit

/// Displays instructions on how to print a shipping label from an iOS device.
final class ShippingLabelPrintingInstructionsViewController: UIHostingController<ShippingLabelPrintingInstructionsView> {
    init() {
        super.init(rootView: ShippingLabelPrintingInstructionsView())
        configureNavigationBar()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ShippingLabelPrintingInstructionsViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
        addCloseNavigationBarButton()
    }
}

private extension ShippingLabelPrintingInstructionsViewController {
    enum Localization {
        static let navigationBarTitle =
            NSLocalizedString("Print from your Phone",
                              comment: "Navigation bar title of shipping label printing instructions screen")
    }
}
