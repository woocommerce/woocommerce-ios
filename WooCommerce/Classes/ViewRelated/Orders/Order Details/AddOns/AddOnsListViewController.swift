import UIKit
import SwiftUI
import Yosemite

/// Hosting controller that wraps an `AddOnsListView`
///
class AddOnsListViewController: UIHostingController<AddOnsListI1View> {
    init(addOns: [OrderItemAttribute]) {
        super.init(rootView: AddOnsListI1View())
        self.title = Localization.title
        addCloseNavigationBarButton()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Constants
private extension AddOnsListViewController {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "The title on the navigation bar when viewing an order item add-ons")
    }
}

/// Renders a list of add ons
///
struct AddOnsListI1View: View {
    var body: some View {
        Text("Hoooli")
    }
}
