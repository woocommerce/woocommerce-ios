import UIKit
import Yosemite

/// Decides between **native** and **admin web** product detail flows and builds the destination VC.
final class ProductDetailNavigator {
    /// Describes how the **native** destination should be presented.
    enum Presentation {
        case push
        case contained(in: () -> UIViewController?)

        var asProductFormPresentationStyle: ProductFormPresentationStyle {
            switch self {
            case .contained(let inVC):
                    .contained(containerViewController: inVC)
            case .push:
                    .navigationStack
            }
        }
    }

    static var shared = ProductDetailNavigator()

    private let coordinatorFactory: ProductDetailCoordinatorFactoryProtocol
    private let stores: StoresManager

    init(coordinatorFactory: ProductDetailCoordinatorFactoryProtocol = ProductDetailCoordinatorFactory.default,
         stores: StoresManager = ServiceLocator.stores,
    ) {
        self.coordinatorFactory = coordinatorFactory
        self.stores = stores
    }

    /// Builds the destination `UIViewController` for the given product.
    /// - Parameters:
    ///   - product: The product to display.
    ///   - presentationStyle: How to present **native** detail (ignored for web).
    ///   - isReadOnly: Whether the native screen should be read-only.
    ///   - onDelete: Optional callback invoked after a successful product delete.
    ///   - onDuplicate: Optional callback invoked with the new duplicate after a successful product duplication,
    ///     letting the caller decide how to open it (native flow only).
    /// - Returns: A ready-to-present view controller (native or web).
    func makeDestination(product: Product,
                         presentationStyle: Presentation = .push,
                         isReadOnly: Bool,
                         onDismissWeb: (() -> Void)? = nil,
                         onDelete: (() -> Void)? = nil,
                         onDuplicate: ((Product) -> Void)? = nil) -> UIViewController {

        let viewController: UIViewController
        if shouldOpenInWeb(product: product) {
            let coordinator = coordinatorFactory.webCoordinator(site: stores.sessionManager.defaultSite)
            viewController = coordinator.viewController(product: product) {
                onDismissWeb?()
            }
        } else {
            let coordinator = coordinatorFactory.nativeCoordinator()
            let duplicateNavigation: ProductDuplicateNavigationHandler = { [self] sourceViewController, duplicatedProduct in
                if let onDuplicate {
                    onDuplicate(duplicatedProduct)
                } else {
                    replaceDestination(sourceViewController: sourceViewController, with: duplicatedProduct)
                }
            }
            viewController = coordinator.viewController(product: product,
                                                        presentationStyle: presentationStyle,
                                                        isReadOnly: isReadOnly,
                                                        onDelete: onDelete,
                                                        onDuplicate: duplicateNavigation)
        }

        return viewController
    }

    /// Replaces a native product editor with another product detail so Back cannot reveal the source editor's draft.
    func replaceDestination(sourceViewController: UIViewController, with duplicatedProduct: Product) {
        guard let navigationController = sourceViewController.navigationController,
              let sourceIndex = navigationController.viewControllers.firstIndex(where: { $0 === sourceViewController }) else {
            return
        }

        let destination = makeDestination(product: duplicatedProduct, isReadOnly: false)
        var viewControllers = navigationController.viewControllers
        viewControllers[sourceIndex] = destination
        navigationController.setViewControllers(viewControllers, animated: true)
    }

    private func shouldOpenInWeb(product: Product) -> Bool {
        product.productType == .legacyBooking
    }
}
