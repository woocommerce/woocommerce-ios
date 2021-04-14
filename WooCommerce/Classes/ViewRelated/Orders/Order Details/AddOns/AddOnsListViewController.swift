import UIKit
import SwiftUI

/// Hosting controller that wraps an `AddOnsListView`
///
class AddOnsListViewController: UIHostingController<AddOnsListI1View> {
    init() {
        super.init(rootView: AddOnsListI1View())
        self.title = "Product Add-ons"
        addCloseNavigationBarButton()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Renders a list of add ons
///
struct AddOnsListI1View: View {
    var body: some View {
        Text("Hooooli")
    }
}
