import Photos
import UIKit

/// Encapsulates launching and customization of a media picker to import media from the Photo Library.
///
final class DeviceMediaLibraryPicker: NSObject {
    typealias Completion = ((_ selectedMediaItems: [PHAsset]) -> Void)
    private let onCompletion: Completion

    init(onCompletion: @escaping Completion) {
        self.onCompletion = onCompletion
    }

    func presentPicker(origin: UIViewController) {
        // TODO-1713: presents device media library picker
    }
}
