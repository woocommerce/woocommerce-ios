import Foundation
import Yosemite

/// Actions in the downloadable file form bottom sheet to add a new downloadable file.
enum DownloadableFileSource {
    case deviceMedia
    case deviceDocument
    case wordPressMediaLibrary
    case fileURL
}

extension DownloadableFileSource {
    var title: String {
        switch self {
        case .deviceMedia:
            return NSLocalizedString("downloadableFileSource.deviceMedia",
                                     value: "Media on device",
                                     comment: "Title of the downloadable file bottom sheet action for adding media from device.")
        case .deviceDocument:
            return NSLocalizedString("downloadableFileSource.deviceDocument",
                                     value: "Document on device",
                                     comment: "Title of the downloadable file bottom sheet action for adding document from device.")
        case .wordPressMediaLibrary:
            return NSLocalizedString("From WordPress Media Library",
                                     comment: "Title of the downloadable file bottom sheet action for adding file from WordPress Media Library.")
        case .fileURL:
            return NSLocalizedString("Enter file URL",
                                     comment: "Title of the downloadable file bottom sheet action for adding file from an URL.")
        }
    }

    var image: UIImage {
        switch self {
        case .deviceMedia:
            return .invisibleImage
        case .deviceDocument:
            return .documentImage
        case .wordPressMediaLibrary:
            return .cameraImage
        case .fileURL:
            return .wordPressLogoImage
        }
    }
}
