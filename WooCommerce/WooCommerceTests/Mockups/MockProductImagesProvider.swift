import Photos
import Yosemite
@testable import WooCommerce

struct MockProductImagesProvider: ProductImagesProvider {
    private let image: UIImage?

    init(image: UIImage?) {
        self.image = image
    }

    func requestImage(productImage: ProductImage, completion: @escaping (UIImage) -> Void) {
        guard let image = image else {
            return
        }
        completion(image)
    }

    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void) {
        guard let image = image else {
            return
        }
        completion(image)
    }

    func update(from asset: PHAsset, to productImage: ProductImage) {
    }
}
