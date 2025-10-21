import UIKit
import Yosemite
@testable import WooCommerce

struct MockProductDetailCoordinator: ProductDetailCoordinator {
    func viewController(product: Product,
                        presentationStyle: ProductDetailNavigator.Presentation,
                        isReadOnly: Bool,
                        onDelete: (() -> Void)?) -> UIViewController {
        UIViewController()
    }
}
