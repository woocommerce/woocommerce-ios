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
                                     comment: "Title of the product form bottom sheet action for editing inventory settings.")
        case .fromWordPressMediaLibrary:
            return NSLocalizedString("From WordPress Media Library",
                                     comment: "Title of the product form bottom sheet action for editing shipping settings.")
        case .fromFileURL:
            return NSLocalizedString("Enter file URL",
                                     comment: "Title of the product form bottom sheet action for editing categories.")
        }
    }
}
