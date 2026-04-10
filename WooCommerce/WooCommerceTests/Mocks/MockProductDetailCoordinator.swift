import UIKit
import Yosemite
@testable import WooCommerce

class MockProductDetailWebCoordinator: ProductDetailWebCoordinator {
    override func viewController(product: Product, onDismiss: @escaping () -> Void) -> UIViewController {
        UIViewController()
    }
}

class MockProductDetailNativeCoordinator: ProductDetailNativeCoordinator {
    override func viewController(product: Product,
                        presentationStyle: ProductDetailNavigator.Presentation,
                        isReadOnly: Bool,
                        onDelete: (() -> Void)?) -> UIViewController {
        UIViewController()
    }
}
