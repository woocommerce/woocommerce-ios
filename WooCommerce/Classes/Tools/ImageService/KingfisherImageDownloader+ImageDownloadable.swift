import Kingfisher

extension Kingfisher.DownloadTask: ImageDownloadTask {}

extension Kingfisher.ImageDownloader: ImageDownloadable {
    func downloadImage(with url: URL, onCompletion: ((Result<UIImage, Error>) -> Void)?) -> ImageDownloadTask? {
        downloadImage(with: url, options: nil) { result in
            switch result {
            case .success(let imageResult):
                onCompletion?(.success(imageResult.image))
            case .failure(let kingfisherError):
                onCompletion?(.failure(kingfisherError))
            }
        }
    }
}
