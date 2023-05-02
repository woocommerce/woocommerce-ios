import UIKit
import Combine

/// A task that downloads an image asynchronously.
///
public protocol ImageDownloadTask: Cancellable {}

/// Performs tasks related to downloading an image.
///
public protocol ImageDownloader {
    func downloadImage(with url: URL,
                       onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask?
}
