import SwiftUI
import UIKit

/// Displays a grid view of all available paper size options for printing a shipping label.
final class ShippingLabelPaperSizeOptionsViewController: UIHostingController<ShippingLabelPaperSizeOptionListView> {
    private let onCloseButtonTapped: () -> Void

    /// - Parameter onCloseButtonTapped: Called when the user taps on the close button in the navigation bar.
    init(onCloseButtonTapped: @escaping () -> Void) {
        self.onCloseButtonTapped = onCloseButtonTapped
        super.init(rootView: ShippingLabelPaperSizeOptionListView(paperSizeOptions: [.legal, .letter, .label]))
        configureNavigationBar()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ShippingLabelPaperSizeOptionsViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: .closeButton, style: .plain, target: self, action: #selector(closeButtonTapped))
    }
}

private extension ShippingLabelPaperSizeOptionsViewController {
    @objc func closeButtonTapped() {
        onCloseButtonTapped()
    }
}

private extension ShippingLabelPaperSizeOptionsViewController {
    enum Localization {
        static let navigationBarTitle =
            NSLocalizedString("Label Format Options",
                              comment: "Navigation bar title of shipping label paper size options screen")
    }
}
