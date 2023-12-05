import UIKit
import Yosemite

final class ProductImageEditMenuCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let productImage: ProductImage
    private let imageLoader: ProductUIImageLoader
    private let actionHandler: ProductImageActionHandlerProtocol

    init(navigationController: UINavigationController,
         productImage: ProductImage,
         imageLoader: ProductUIImageLoader,
         actionHandler: ProductImageActionHandlerProtocol) {
        self.navigationController = navigationController
        self.productImage = productImage
        self.imageLoader = imageLoader
        self.actionHandler = actionHandler
    }

    func start() {
        guard #available(iOS 17.0, *) else {
            return
        }
        let viewModel = ProductImageBackgroundRemovalViewModel(productImage: productImage,
                                                               imageLoader: imageLoader,
                                                               actionHandler: actionHandler,
                                                               onSave: { [weak self] in
            self?.navigationController.popViewController(animated: true)
        })
        let controller = ProductImageBackgroundRemovalHostingController(viewModel: viewModel)
        navigationController.show(controller, sender: nil)
    }
}
