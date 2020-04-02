import UIKit

protocol Cancellable {
    func cancel()
}

protocol ImageDownloadTask: Cancellable {}

protocol ImageDownloadable {
    func downloadImage(with url: URL,
                       onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask?
}
