import UIKit
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
}
