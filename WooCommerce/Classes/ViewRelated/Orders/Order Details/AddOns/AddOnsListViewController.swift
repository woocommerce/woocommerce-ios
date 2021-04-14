import UIKit
import SwiftUI

class AddOnsListViewController: UIHostingController<DummyView> {
    init() {
        super.init(rootView: DummyView())
        self.title = "Product Add-ons"
        addCloseNavigationBarButton()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct DummyView: View {
    var body: some View {
        Text("Hooooli")
    }
}
