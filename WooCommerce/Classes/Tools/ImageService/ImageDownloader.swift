import UIKit

/// Used for any activity or action that may be canceled.
/// `Cancellable` is also available starting iOS 13, please delete when the project is iOS 13+.
///
protocol Cancellable {
    func cancel()
}

/// A task that downloads an image asynchronously.
///
protocol ImageDownloadTask: Cancellable {}

/// Performs tasks related to downloading an image.
///
protocol ImageDownloader {
    func downloadImage(with url: URL,
                       onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask?
}
