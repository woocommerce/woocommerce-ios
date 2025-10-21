import UIKit
import Yosemite

final class WebViewProductDetailCoordinator: NSObject, ProductDetailCoordinator {
    private var onDismiss: (() -> Void)?

    private let site: Site

    init(site: Site) {
        self.site = site
    }

    func viewController(product: Product,
                        presentationStyle: ProductDetailPresenter.PresentationStyle,
                        forceReadOnly: Bool,
                        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {
        guard let url = ProductURLProvider.editAdminURL(for: product, site: site) else {
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
