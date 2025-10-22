import UIKit
import Yosemite

/// Coordinator for the **admin web** product detail/editor flow.
final class ProductDetailWebCoordinator: NSObject, ProductDetailCoordinator {
    var onDismiss: (() -> Void)?
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

        let viewModel = AdminWebViewModel(title: product.name, initialURL: url) { [onDismiss] in
            onDismiss?()
        }
        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)

        return webViewController
    }
}

fileprivate class AdminWebViewModel: WPAdminWebViewModel {
    var onDismiss: (() -> Void)?

    init(title: String, initialURL: URL, onDismiss: (() -> Void)?) {
        self.onDismiss = onDismiss
        super.init(title: title, initialURL: initialURL)
    }

    override func handleDismissal() {
        onDismiss?()
        super.handleDismissal()
    }
}
