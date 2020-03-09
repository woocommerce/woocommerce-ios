import MobileCoreServices
import WPMediaPicker

/// Encapsulates capturing media from a device camera.
///
final class CameraCaptureCoordinator {
    private var capturePresenter: WPMediaCapturePresenter?

    typealias Completion = ((_ media: PHAsset?, _ error: Error?) -> Void)
    private let onCompletion: Completion

    init(onCompletion: @escaping Completion) {
        self.onCompletion = onCompletion
    }

    func presentMediaCaptureIfAuthorized(origin: UIViewController) {
        guard hasPhotoLibraryPermission() else {
            requestPhotoLibraryPermission { [weak self] authorized in
                guard authorized else {
                    self?.onCompletion(nil, CameraCaptureError.photoLibraryPermissionNotAuthorized)
                    return
                }
                self?.presentMediaCapture(origin: origin)
            }
            return
        }
        presentMediaCapture(origin: origin)
    }

    private func presentMediaCapture(origin: UIViewController) {
        let capturePresenter = WPMediaCapturePresenter(presenting: origin)
        capturePresenter.mediaType = .image
        self.capturePresenter = capturePresenter
        capturePresenter.completionBlock = { [weak self] mediaInfo in
            if let mediaInfo = mediaInfo as NSDictionary? {
                self?.processMediaCaptured(mediaInfo)
            }
            self?.capturePresenter = nil
        }

        capturePresenter.presentCapture()
    }

    private func processMediaCaptured(_ mediaInfo: NSDictionary) {
        let completionBlock: WPMediaAddedBlock = { [weak self] media, error in
            guard let media = media as? PHAsset, error == nil else {
                guard self?.hasPhotoLibraryPermission() == true else {
                    self?.onCompletion(nil, CameraCaptureError.photoLibraryPermissionNotAuthorized)
                    return
                }
                self?.onCompletion(nil, error)
                return
            }

            self?.onCompletion(media, nil)
        }

        guard let mediaType = mediaInfo[UIImagePickerController.InfoKey.mediaType.rawValue] as? String else {
            onCompletion(nil, CameraCaptureError.unknownMediaType)
            return
        }

        switch mediaType {
        case String(kUTTypeImage):
            if let image = mediaInfo[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage,
                let metadata = mediaInfo[UIImagePickerController.InfoKey.mediaMetadata.rawValue] as? [AnyHashable: Any] {

                // Saves the image into Photo Library in case the followup tasks fail.
                WPPHAssetDataSource().add(image, metadata: metadata, completionBlock: completionBlock)
            }
        default:
            onCompletion(nil, CameraCaptureError.unsupportedMediaType(mediaType: mediaType))
        }
    }
}

// MARK: Permission Helpers
//
private extension CameraCaptureCoordinator {
    func hasPhotoLibraryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }

    func requestPhotoLibraryPermission(completion: @escaping (_ authorized: Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(status == .authorized)
        }
    }
}

private enum CameraCaptureError: Error {
    case unknownMediaType
    case unsupportedMediaType(mediaType: String)
    case photoLibraryPermissionNotAuthorized
}

extension CameraCaptureError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unknownMediaType:
            return NSLocalizedString("Unknown media type",
                                     comment: "Error message when capturing a unknown media type")
        case .unsupportedMediaType(let mediaType):
            let format = NSLocalizedString("Camera capture should not support media type: %@",
                                           comment: "Error message format when capturing a unsupported media type with device camera")
            return String.localizedStringWithFormat(format, mediaType)
        case .photoLibraryPermissionNotAuthorized:
            return NSLocalizedString("Please make sure the app can access Photos in device settings",
                                     comment: "Error message when an image captured by camera cannot be saved to the device Photos library")
        }
    }
}
