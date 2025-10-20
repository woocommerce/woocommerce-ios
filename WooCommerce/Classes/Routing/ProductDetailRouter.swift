import UIKit
import Yosemite

final class ProductDetailRouter {
    enum PresentationStyle {
        case undefined
        case contained(containerViewController: () -> UIViewController?)

        var asProductFormPresentationStyle: ProductFormPresentationStyle {
            switch self {
            case .contained(let containerViewController):
                    .contained(containerViewController: containerViewController)
            case .undefined:
                    .navigationStack
            }
        }
    }

    static var shared = ProductDetailRouter(productURLProvider: ProductURLProvider())

    private let productURLProvider: ProductURLProvider
    private let ciabChecker: CIABEligibilityCheckerProtocol
    private let stores: StoresManager

    init(productURLProvider: ProductURLProvider,
         ciabChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(),
         stores: StoresManager = ServiceLocator.stores) {
        self.productURLProvider = productURLProvider
        self.ciabChecker = ciabChecker
        self.stores = stores
    }

    func viewController(product: Product,
                        presentationStyle: PresentationStyle = .undefined,
                        forceReadOnly: Bool,
                        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {

        let viewController: UIViewController
        if shouldOpenInWeb(product: product) {
            let coordinator = WebViewProductDetailCoordinator(productURLProvider: productURLProvider)
            viewController = coordinator.viewController(product: product,
                                                        site: stores.sessionManager.defaultSite!)

        } else {
            let coordinator = NativeProductDetailCoordinator(product: product)
            viewController = coordinator.viewController(presentationStyle: presentationStyle,
                                                        forceReadOnly: forceReadOnly)
        }

        return viewController
    }

    private func shouldOpenInWeb(product: Product) -> Bool {
        return ciabChecker.isCurrentSiteCIAB && product.productType == .booking
    }
}

final class WebViewProductDetailCoordinator: NSObject {
    private let productURLProvider: ProductURLProvider

    private var onDismiss: (() -> Void)?

    init(productURLProvider: ProductURLProvider) {
        self.productURLProvider = productURLProvider
    }

    func viewController(product: Product,
                        site: Site,
                        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {
        guard let url = productURLProvider.adminURL(for: product, site: site) else {
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

final class NativeProductDetailCoordinator {
    private let product: Product

    init(product: Product) {
        self.product = product
    }

    func viewController(
        presentationStyle: ProductDetailRouter.PresentationStyle,
        forceReadOnly: Bool,
        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {
            return ProductDetailsFactory.productDetails(product: product,
                                                        presentationStyle: presentationStyle.asProductFormPresentationStyle,
                                                        forceReadOnly: false,
                                                        onDeleteCompletion: onDeleteCompletion ?? {})
        }
}

final class ProductURLProvider {
    func adminURL(for product: Product, site: Site) -> URL? {
        return site.adminURLWithFallback()?.appendingPathComponent("?page=next-admin&p=/woocommerce/products/edit/\(product.productID)")
    }
}
