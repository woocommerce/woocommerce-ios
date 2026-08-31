import UIKit
import Yosemite
@testable import WooCommerce

class MockProductDetailWebCoordinator: ProductDetailWebCoordinator {
    override func viewController(product: Product, onDismiss: @escaping () -> Void) -> UIViewController {
        UIViewController()
    }
}

nonisolated class MockProductDetailNativeCoordinator: ProductDetailNativeCoordinator {
    nonisolated(unsafe) private(set) var viewControllerInstance: UIViewController?
    nonisolated(unsafe) private(set) var onDuplicate: ProductDuplicateNavigationHandler?

    override func viewController(product: Product,
                        presentationStyle: ProductDetailNavigator.Presentation,
                        isReadOnly: Bool,
                        onDelete: (() -> Void)?,
                        onDuplicate: @escaping ProductDuplicateNavigationHandler) -> UIViewController {
        self.onDuplicate = onDuplicate
        return MainActor.assumeIsolated {
            let viewController = viewControllerInstance ?? UIViewController()
            viewControllerInstance = viewController
            return viewController
        }
    }
}
