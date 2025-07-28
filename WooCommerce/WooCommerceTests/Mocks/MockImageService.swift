import UIKit
import Combine
@testable import WooCommerce

final class MockImageService {
    private(set) var retrieveImageFromCacheCalled = false
    private var retrieveImageFromCacheCompletionImage: UIImage?

    func whenRetrieveImageFromCache(thenReturn image: UIImage?) {
        retrieveImageFromCacheCompletionImage = image
    }

    private(set) var downloadImageCalled = false
    private(set) var shouldCacheImageValue = false
    private var downloadImageValue: UIImage?
    private var downloadImageError: ImageServiceError?

    func whenDownloadImage(thenReturn image: UIImage) {
        downloadImageValue = image
    }

    func whenDownloadImage(thenThrow error: ImageServiceError) {
        downloadImageError = error
    }
}

extension MockImageService: ImageService {
    func storeImageInCache(_ image: UIImage, for url: URL) {
        // no-op
    }

    func retrieveImageFromCache(with url: URL, completion: @escaping ImageCacheRetrievalCompletion) {
        retrieveImageFromCacheCalled = true
        completion(retrieveImageFromCacheCompletionImage)
    }

    func downloadImage(with url: URL, shouldCacheImage: Bool, completion: ImageDownloadCompletion?) -> ImageDownloadTask? {
        downloadImageCalled = true
        shouldCacheImageValue = shouldCacheImage
        completion?(downloadImageValue, downloadImageError)
        return nil
    }

    func downloadAndCacheImageForImageView(_ imageView: UIImageView,
                                           with url: String?,
                                           placeholder: UIImage?,
                                           progressBlock: ImageDownloadProgressBlock?,
                                           completion: ImageDownloadCompletion?) {
        // no-op
    }

    func retrieveImage(
        with url: URL,
        targetSize: CGSize?,
        shouldCacheImage: Bool,
        completion: WooCommerce.ImageDownloadCompletion?
    ) -> (any Cancellable)? {
        // no-op
        return nil
    }

    func clearMemoryCache() {
        // no-op
    }
}
