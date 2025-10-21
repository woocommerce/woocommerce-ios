import UIKit
import Yosemite

/// Coordinator for the **admin web** product detail/editor flow.
final class ProductDetailWebCoordinator: NSObject, ProductDetailCoordinator {
    private var onDismiss: (() -> Void)?

    private let site: Site

    init(site: Site) {
        self.site = site
    }

    func viewController(product: Product,
                        presentationStyle: ProductDetailNavigator.Presentation,
                        isReadOnly: Bool,
                        onDelete: (() -> Void)? = nil) -> UIViewController {
        guard let url = ProductAdminURLProvider.editURL(for: product, site: site) else {
            return UIViewController()
        }

        let viewModel = WPAdminWebViewModel(title: product.name, initialURL: url)
        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)

        return webViewController
    }

    @objc
    private func dismissWebView() {
        let completion = onDismiss
        onDismiss = nil
        completion?()
    }
}
