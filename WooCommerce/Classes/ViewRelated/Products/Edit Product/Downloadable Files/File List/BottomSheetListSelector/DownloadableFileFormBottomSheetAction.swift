import Foundation
import Yosemite

/// Actions in the downloadable file form bottom sheet to add a new downloadable file.
enum DownloadableFileFormBottomSheetAction {
    case fromDevice
    case fromWordPressMediaLibrary
    case fromFileURL
}

extension DownloadableFileFormBottomSheetAction {
    var title: String {
        switch self {
        case .fromDevice:
            return NSLocalizedString("From device",
                                     comment: "Title of the downloadable file bottom sheet action for adding file from device.")
        case .fromWordPressMediaLibrary:
            return NSLocalizedString("From WordPress Media Library",
                                     comment: "Title of the downloadable file bottom sheet action for adding file from WordPress Media Library.")
        case .fromFileURL:
            return NSLocalizedString("Enter file URL",
                                     comment: "Title of the downloadable file bottom sheet action for adding file from an URL.")
        }
    }

    var image: UIImage {
        switch self {
        case .fromDevice:
            return .invisibleImage
        case .fromWordPressMediaLibrary:
            return .cameraImage
        case .fromFileURL:
            return .wordPressLogoImage
        }
    }
}
