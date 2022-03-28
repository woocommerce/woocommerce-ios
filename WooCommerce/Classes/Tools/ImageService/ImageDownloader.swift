import UIKit
import Combine

/// A task that downloads an image asynchronously.
///
protocol ImageDownloadTask: Cancellable {}

/// Performs tasks related to downloading an image.
///
protocol ImageDownloader {
    func downloadImage(with url: URL,
                       onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask?
}
