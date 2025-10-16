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

    init(productURLProvider: ProductURLProvider) {
        self.productURLProvider = productURLProvider
    }

    func viewController(product: Product,
                        presentationStyle: PresentationStyle = .undefined,
                        forceReadOnly: Bool,
                        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {

        let viewController: UIViewController
        if  product.productType == .booking {
            let coordinator = WebViewProductDetailCoordinator(product: product,
                                                              productURLProvider: productURLProvider)
            viewController = coordinator.viewController()

        } else {
            let coordinator = NativeProductDetailCoordinator(product: product)
            viewController = coordinator.viewController(presentationStyle: presentationStyle,
                                              forceReadOnly: forceReadOnly)
        }

        return viewController
    }
}

final class WebViewProductDetailCoordinator: NSObject {
    private let product: Product
    private let productURLProvider: ProductURLProvider

    private var onDismiss: (() -> Void)?

    init(product: Product, productURLProvider: ProductURLProvider) {
        self.product = product
        self.productURLProvider = productURLProvider
    }

    func viewController(onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {
        guard let url = productURLProvider.adminURL(for: product) else {
            return UIViewController() // TODO: What do we do in this case?
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
    func adminURL(for product: Product) -> URL? {
        return URL(string: "https://wordpress.com")
    }
}
