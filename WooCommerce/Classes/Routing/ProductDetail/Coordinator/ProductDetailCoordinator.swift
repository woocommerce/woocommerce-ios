import UIKit
import Yosemite

/// Abstraction for building the concrete destination VC for a product detail flow.
protocol ProductDetailCoordinator {
    func viewController(
        product: Product,
        presentationStyle: ProductDetailNavigator.Presentation,
        isReadOnly: Bool,
        onDelete: (() -> Void)?) -> UIViewController
}
