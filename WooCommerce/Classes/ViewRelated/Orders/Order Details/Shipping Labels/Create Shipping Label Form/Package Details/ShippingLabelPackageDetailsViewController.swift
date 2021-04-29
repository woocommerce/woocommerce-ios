import SwiftUI
import UIKit
import Yosemite

/// Displays the Shipping Label Package Details
final class ShippingLabelPackageDetailsViewController: UIHostingController<ShippingLabelPackageDetails> {
    init(order: Order) {
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order)
        super.init(rootView: ShippingLabelPackageDetails(viewModel: viewModel))
        configureNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.title = ""
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ShippingLabelPackageDetailsViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
    }
}

private extension ShippingLabelPackageDetailsViewController {
    enum Localization {
        static let navigationBarTitle =
            NSLocalizedString("Package Details",
                              comment: "Navigation bar title of shipping label package details screen")
    }
}
