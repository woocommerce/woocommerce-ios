import UIKit
import Yosemite

final class ProductDetailRouter {
    enum PresentationStyle {
        case undefined
        case push
        case modal
        case contained(containerViewController: () -> UIViewController?)

        var asProductFormPresentationStyle: ProductFormPresentationStyle {
            switch self {
            case .push:
                    .navigationStack
            case .modal:
                    .navigationStack
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

    func open(product: Product,
              presenter: UIViewController,
              presentationStyle: PresentationStyle,
              onDismiss: (() -> Void)? = nil) {
        if  product.productType == .booking {
            let coordinator = WebViewProductDetailCoordinator(product: product,
                                                              productURLProvider: productURLProvider)
            coordinator.start(presenter: presenter, onDismiss: onDismiss)
        } else {
            let coordinator = NativeProductDetailCoordinator(product: product)
            coordinator.start(presenter: presenter,
                              presentationStyle: presentationStyle,
                              onDismiss: onDismiss)
        }
    }

    func viewController(product: Product,
                        presentationStyle: PresentationStyle = .undefined,
                        forceReadOnly: Bool,
                        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {
        if  product.productType == .booking {
            let coordinator = WebViewProductDetailCoordinator(product: product,
                                                              productURLProvider: productURLProvider)
            return coordinator.viewController()

        } else {
            let coordinator = NativeProductDetailCoordinator(product: product)
            return coordinator.viewController(presentationStyle: presentationStyle,
                                              forceReadOnly: forceReadOnly)
        }
    }
}

final class ProductURLProvider {
    func adminURL(for product: Product) -> URL? {
        return URL(string: "https://wordpress.com")
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

    func start(presenter: UIViewController,
               onDismiss: (() -> Void)? = nil) {
        let webViewController = viewController()
        webViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissWebView)
        )

        presenter.navigationController?.present(webViewController, animated: true)
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

    func start(presenter: UIViewController,
               presentationStyle: ProductDetailRouter.PresentationStyle,
               onDismiss: (() -> Void)? = nil) {

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
