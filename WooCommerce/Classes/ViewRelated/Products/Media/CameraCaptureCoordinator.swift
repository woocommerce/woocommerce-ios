import Photos
import UIKit

/// Encapsulates capturing media from a device camera.
///
final class CameraCaptureCoordinator {
    typealias Completion = ((_ media: PHAsset?, _ error: Error?) -> Void)
    private let onCompletion: Completion

    init(onCompletion: @escaping Completion) {
        self.onCompletion = onCompletion
    }

    func presentMediaCaptureIfAuthorized(origin: UIViewController) {
        // TODO-1713: camera capture
    }
}
