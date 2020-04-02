import UIKit
@testable import WooCommerce

final class MockImageDownloadTask: ImageDownloadTask {
    private(set) var isCancelled: Bool = false

    func cancel() {
        isCancelled = true
    }
}

final class MockImageDownloadable: ImageDownloadable {
    // Mocks in-memory cache.
    private let imagesByKey: [String: UIImage]

    init(imagesByKey: [String: UIImage]) {
        self.imagesByKey = imagesByKey
    }

    func downloadImage(with url: URL, onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask? {
        if let image = imagesByKey[url.absoluteString] {
            onCompletion?(.success(image))
        } else {
            let error = NSError(domain: "MockDownloadable", code: 1, userInfo: nil)
            onCompletion?(.failure(error))
        }
        return MockImageDownloadTask()
    }
}
