import Kingfisher
import Combine

/// The `@retroactive` attribute is used to apply `ImageDownloadTask` conformance to `DownloadTask` from the Kingfisher module.
/// At the same time, `ImageDownloadTask` conform to `Cancellable` part of Combine module, 
/// This is necessary due to Swift 6 [SE-0364 proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md).
extension DownloadTask: @retroactive Cancellable {}
extension Kingfisher.DownloadTask: ImageDownloadTask {}

extension Kingfisher.ImageDownloader: ImageDownloader {
    func downloadImage(with url: URL, onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask? {
        return downloadImage(with: url, options: nil, completionHandler: { result in
            switch result {
            case .success(let imageResult):
                onCompletion?(.success(imageResult.image))
            case .failure(let kingfisherError):
                onCompletion?(.failure(kingfisherError))
            }
        })
    }
}
