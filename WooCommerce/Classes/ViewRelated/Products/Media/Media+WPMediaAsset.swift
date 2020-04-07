import MobileCoreServices
import WPMediaPicker
import Yosemite

extension Media: WPMediaAsset {
    public func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        let imageURL = thumbnailURL ?? src
        guard let url = URL(string: imageURL) else {
            return 0
        }

        // TODO-2073: move image fetching to `WordPressMediaLibraryPickerDataSource` instead of having to use the `ServiceLocator` singleton on a `Media`
        // extension.
        let imageService = ServiceLocator.imageService
        imageService.retrieveImageFromCache(with: url) { (image) in
            if let image = image {
                completionHandler(image, nil)
                return
            }

            imageService.downloadImage(with: url, shouldCacheImage: true) { (image, error) in
                completionHandler(image, error)
            }
        }
        return Int32(mediaID)
    }

    public func cancelImageRequest(_ requestID: WPMediaRequestID) {}

    public func videoAsset(completionHandler: @escaping WPMediaAssetBlock) -> WPMediaRequestID {
        fatalError("Video is not supported")
    }

    public func assetType() -> WPMediaType {
        return mediaType.toWPMediaType
    }

    public func duration() -> TimeInterval {
        fatalError("Video is not supported")
    }

    public func baseAsset() -> Any {
        return self
    }

    public func identifier() -> String {
        return "\(mediaID)"
    }

    public func date() -> Date {
        return date
    }

    public func pixelSize() -> CGSize {
        guard let height = height, let width = width else {
            return .zero
        }
        return CGSize(width: width, height: height)
    }
}
