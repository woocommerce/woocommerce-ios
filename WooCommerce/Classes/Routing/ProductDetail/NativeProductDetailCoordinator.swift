import Yosemite
import UIKit

class NativeProductDetailCoordinator: ProductDetailCoordinator {
    func viewController(
        product: Product,
        presentationStyle: ProductDetailPresenter.PresentationStyle,
        forceReadOnly: Bool,
        onDeleteCompletion: (() -> Void)? = nil) -> UIViewController {
            return ProductDetailsFactory.productDetails(product: product,
                                                        presentationStyle: presentationStyle.asProductFormPresentationStyle,
                                                        forceReadOnly: false,
                                                        onDeleteCompletion: onDeleteCompletion ?? {})
        }
}
