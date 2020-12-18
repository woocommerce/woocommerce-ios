import SwiftUI
import UIKit

/// Displays instructions on how to print a shipping label from an iOS device.
final class ShippingLabelPrintingInstructionsViewController: UIHostingController<ShippingLabelPrintingInstructionsView> {
    private let onCloseButtonTapped: () -> Void

    /// - Parameter onCloseButtonTapped: Called when the user taps on the close button in the navigation bar.
    init(onCloseButtonTapped: @escaping () -> Void) {
        self.onCloseButtonTapped = onCloseButtonTapped
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .closeButton, style: .plain, target: self, action: #selector(closeButtonTapped))
    }
}

private extension ShippingLabelPrintingInstructionsViewController {
    @objc func closeButtonTapped() {
        onCloseButtonTapped()
    }
}

private extension ShippingLabelPrintingInstructionsViewController {
    enum Localization {
        static let navigationBarTitle =
            NSLocalizedString("Print from your Phone",
                              comment: "Navigation bar title of shipping label printing instructions screen")
    }
}
