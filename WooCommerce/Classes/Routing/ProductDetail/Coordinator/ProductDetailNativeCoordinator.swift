import Yosemite
import UIKit

/// Coordinator for the **native** product detail/editor flow.
/// Delegates VC construction to `ProductDetailsFactory` and applies the requested presentation style.
class ProductDetailNativeCoordinator {

    func viewController(
        product: Product,
        presentationStyle: ProductDetailNavigator.Presentation,
        isReadOnly: Bool,
        onDelete: (() -> Void)? = nil) -> UIViewController {
            return ProductDetailsFactory.productDetails(product: product,
                                                        presentationStyle: presentationStyle.asProductFormPresentationStyle,
                                                        forceReadOnly: isReadOnly,
                                                        onDeleteCompletion: onDelete ?? {})
        }
}
