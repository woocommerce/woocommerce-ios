import SwiftUI
import Kingfisher

final class CartItemRowViewModel: ObservableObject {
    private let cache: ImageCache = ImageCache.default
    let cartItem: CartItem
    @Published var cachedImage: UIImage? = nil

    init(_ cartItem: CartItem) {
        self.cartItem = cartItem

        cache.memoryStorage.config.countLimit = Constants.maxNumberOfImagesInCache
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
                    DDLogError("Error retrieving image \(imageCacheKey) from cache.")
                }
            }
        }
    }
}

private extension CartItemRowViewModel {
    enum Constants {
        // Limits memory cache to hold 100 images at most
        // Images in memory storage expire 5 minutes after the last access. Images in disk storage expire after one week.
        // https://swiftpackageindex.com/onevcat/kingfisher/master/documentation/kingfisher/commontasks_cache
        static let maxNumberOfImagesInCache: Int = 100
    }
}
