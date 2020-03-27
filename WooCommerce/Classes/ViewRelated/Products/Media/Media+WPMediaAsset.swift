import Foundation
import MobileCoreServices
import WPMediaPicker
import Yosemite

enum MediaType {
    case image
    case video
    case document
    case powerpoint
    case audio
    case other

    init(fileExtension: String) {
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)
        guard let fileUTI = unmanagedFileUTI?.takeRetainedValue() else {
            self = .document
            return
        }
        self.init(fileUTI: fileUTI)
    }

    init(mimeType: String) {
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
        guard let fileUTI = unmanagedFileUTI?.takeRetainedValue() else {
            self = .document
            return
        }
        self.init(fileUTI: fileUTI)
    }

    init(fileUTI: CFString) {
        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
            self = .image
        } else if (UTTypeConformsTo(fileUTI, kUTTypeVideo)) {
            self = .video
        } else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
            self = .video
        } else if (UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
            self = .video
        } else if (UTTypeConformsTo(fileUTI, kUTTypePresentation)) {
            self = .powerpoint
        } else if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
            self = .audio
        } else {
            self = .document
        }
    }
}

extension Media {
    var mediaType: MediaType {
        if mimeType.isEmpty == false {
            return MediaType(mimeType: mimeType)
        } else if fileExtension.isEmpty == false {
            return MediaType(fileExtension: fileExtension)
        } else {
            return .other
        }
    }
}

extension MediaType {
    var toWPMediaType: WPMediaType {
        switch self {
        case .image:
            return .image
        case .video:
            return .video
        case .audio:
            return .audio
        default:
            return .other
        }
    }
}

extension Media: WPMediaAsset {
    public func image(with size: CGSize, completionHandler: @escaping WPMediaImageBlock) -> WPMediaRequestID {
        let imageURL = thumbnailURL ?? src
        guard let url = URL(string: imageURL) else {
            return 0
        }

        let imageService = ServiceLocator.imageService
        DispatchQueue.global().async {
            imageService.retrieveImageFromCache(with: url) { (image) in
                if let image = image {
                    completionHandler(image, nil)
                    return
                }

                imageService.downloadImage(with: url, shouldCacheImage: true) { (image, error) in
                    completionHandler(image, error)
                }
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
