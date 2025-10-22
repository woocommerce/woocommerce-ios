import UIKit
import Yosemite

/// Coordinator for the **admin web** product detail/editor flow.
class ProductDetailWebCoordinator: NSObject {
    private let site: Site?

    init(site: Site?) {
        self.site = site
    }

    func viewController(product: Product, onDismiss: @escaping () -> Void) -> UIViewController {
        guard let url = ProductAdminURLProvider.editURL(for: product, site: site) else {
            return UIViewController()
        }

        let viewModel = AdminWebViewModel(title: product.name, initialURL: url) { [onDismiss] in
            onDismiss()
        }
        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        return webViewController
    }
}

fileprivate class AdminWebViewModel: WPAdminWebViewModel {
    let onDismiss: (() -> Void)

    init(title: String, initialURL: URL, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(title: title, initialURL: initialURL)
    }

    override func handleDisappear() {
        onDismiss()
        super.handleDisappear()
    }
}
