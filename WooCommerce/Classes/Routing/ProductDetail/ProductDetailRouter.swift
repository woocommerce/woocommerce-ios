import UIKit
import Yosemite

final class ProductDetailPresenter {
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

    static var shared = ProductDetailPresenter()

    private let ciabChecker: CIABEligibilityCheckerProtocol
    private let coordinatorFactory: ProductDetailCoordinatorFactoryProtocol

    init(ciabChecker: CIABEligibilityCheckerProtocol = CIABEligibilityChecker(),
         coordinatorFactory: ProductDetailCoordinatorFactoryProtocol = ProductDetailCoordinatorFactory.default) {
        self.ciabChecker = ciabChecker
        self.coordinatorFactory = coordinatorFactory
    }

    func viewController(product: Product,
                        presentationStyle: PresentationStyle = .undefined,
                        forceReadOnly: Bool,
                        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {

        let coordinator: ProductDetailCoordinator
        if shouldOpenInWeb(product: product) {
            coordinator = coordinatorFactory.webCoordinator()
        } else {
            coordinator = coordinatorFactory.nativeCoordinator()
        }

        let viewController = coordinator.viewController(product: product,
                                                        presentationStyle: presentationStyle,
                                                        forceReadOnly: forceReadOnly,
                                                        onDeleteCompletion: onDeleteCompletion)

        return viewController
    }

    private func shouldOpenInWeb(product: Product) -> Bool {
        return ciabChecker.isCurrentSiteCIAB && product.productType == .booking
    }
}

protocol ProductDetailCoordinator {
    func viewController(
        product: Product,
        presentationStyle: ProductDetailPresenter.PresentationStyle,
        forceReadOnly: Bool,
        onDeleteCompletion: (() -> Void)?) -> UIViewController
}

protocol ProductDetailCoordinatorFactoryProtocol {
    func webCoordinator() -> ProductDetailCoordinator
    func nativeCoordinator() -> ProductDetailCoordinator
}

class ProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    static let `default` = ProductDetailCoordinatorFactory()

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func webCoordinator() -> ProductDetailCoordinator {
        return WebViewProductDetailCoordinator(site: stores.sessionManager.defaultSite!)
    }

    func nativeCoordinator() -> ProductDetailCoordinator {
        return NativeProductDetailCoordinator()
    }
}
