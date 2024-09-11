import SwiftUI
import Kingfisher

final class CartItemRowViewModel: ObservableObject {
    private let cache: ImageCache = ImageCache.default
    private let cartItem: CartItem
    @Published var cachedImage: UIImage? = nil

    init(_ cartItem: CartItem) {
        self.cartItem = cartItem

        cache.memoryStorage.config.countLimit = 100
        if let imageSource = cartItem.item.productImageSource {
            loadImageFromCache(imageCacheKey: imageSource)
        }
    }

    func loadImageFromCache(imageCacheKey: String) {
        if cache.isCached(forKey: imageCacheKey, processorIdentifier: DefaultImageProcessor().identifier) {
            cache.retrieveImage(forKey: imageCacheKey) { [weak self] result in
                switch result {
                case .success(let imageInCache):
                    switch imageInCache {
                    case .memory(let image), .disk(let image):
                        self?.cachedImage = image
                    case .none:
                        break
                    }
                case .failure:
                    DDLogError("Error retrieving image from cache")
                }
            }
        }
    }
}
