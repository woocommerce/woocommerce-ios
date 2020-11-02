import Foundation
import Yosemite

/// Actions in the downloadable file form bottom sheet to add a new downloadable file.
enum DownloadableFileSource {
    case device
    case wordPressMediaLibrary
    case fileURL
}

extension DownloadableFileSource {
    var title: String {
        switch self {
        case .device:
            return NSLocalizedString("From device",
                                     comment: "Title of the downloadable file bottom sheet action for adding file from device.")
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
        case .device:
            return .invisibleImage
        case .wordPressMediaLibrary:
            return .cameraImage
        case .fileURL:
            return .wordPressLogoImage
        }
    }
}
