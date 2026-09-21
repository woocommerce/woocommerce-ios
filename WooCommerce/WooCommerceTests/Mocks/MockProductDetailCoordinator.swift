import UIKit
import Yosemite
@testable import WooCommerce

class MockProductDetailWebCoordinator: ProductDetailWebCoordinator {
    override func viewController(product: Product, onDismiss: @escaping () -> Void) -> UIViewController {
        UIViewController()
    }
}

class MockProductDetailNativeCoordinator: ProductDetailNativeCoordinator {
    let viewControllerInstance = UIViewController()
    private(set) var onDuplicate: ProductDuplicateNavigationHandler?

    override func viewController(product: Product,
                        presentationStyle: ProductDetailNavigator.Presentation,
                        isReadOnly: Bool,
                        onDelete: (() -> Void)?,
                        onDuplicate: @escaping ProductDuplicateNavigationHandler) -> UIViewController {
        self.onDuplicate = onDuplicate
        return viewControllerInstance
    }
}
