import UIKit
@testable import WooFoundation

public final class MockImageDownloadTask: ImageDownloadTask {
    private(set) var isCancelled: Bool = false

    public func cancel() {
        isCancelled = true
    }
}

public final class MockImageDownloader: ImageDownloader {
    // Mocks in-memory cache.
    private let imagesByKey: [String: UIImage]

    public init(imagesByKey: [String: UIImage]) {
        self.imagesByKey = imagesByKey
    }

    public func downloadImage(with url: URL, onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask? {
        if let image = imagesByKey[url.absoluteString] {
            onCompletion?(.success(image))
        } else {
            let error = NSError(domain: "MockDownloadable", code: 1, userInfo: nil)
            onCompletion?(.failure(error))
        }
        return MockImageDownloadTask()
    }
}
