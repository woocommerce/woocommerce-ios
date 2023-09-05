import UIKit
import Yosemite

final class ProductImageEditMenuCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let productImage: ProductImage
    private let imageLoader: ProductUIImageLoader

    init(navigationController: UINavigationController,
         productImage: ProductImage,
         imageLoader: ProductUIImageLoader) {
        self.navigationController = navigationController
        self.productImage = productImage
        self.imageLoader = imageLoader
    }

    func start() {
        if #available(iOS 17.0, *) {
            let viewModel = ProductImageBackgroundRemovalViewModel(productImage: productImage, imageLoader: imageLoader)
            let controller = ProductImageBackgroundRemovalHostingController(viewModel: viewModel)
            navigationController.show(controller, sender: nil)
        }
    }
}
