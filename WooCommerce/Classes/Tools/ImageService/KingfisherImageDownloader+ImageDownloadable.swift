import Kingfisher

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
