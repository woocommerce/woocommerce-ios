import Foundation
import UIKit

class MockImageService: ImageService {

    func retrieveImageFromCache(with url: URL, completion: @escaping ImageCacheRetrievalCompletion) {
        // No-op
    }

    func downloadImage(with url: URL, shouldCacheImage: Bool, completion: ImageDownloadCompletion?) -> ImageDownloadTask? {
        return nil
    }

    func downloadAndCacheImageForImageView(_ imageView: UIImageView,
                                           with url: String?,
                                           placeholder: UIImage?,
                                           progressBlock: ImageDownloadProgressBlock?,
                                           completion: ImageDownloadCompletion?) {
        // No-op
    }
}
