import UIKit

enum MediaPickingSource {
    case camera
    case photoLibrary
    case siteMediaLibrary
}

/// Prepares the alert controller that will be presented when trying to add media to a site.
///
final class MediaPickingCoordinator {
    private lazy var cameraCapture: CameraCaptureCoordinator = {
        return CameraCaptureCoordinator(onCompletion: onCameraCaptureCompletion)
    }()

    private lazy var deviceMediaLibraryPicker: DeviceMediaLibraryPicker = {
        return DeviceMediaLibraryPicker(allowsMultipleImages: allowsMultipleImages, onCompletion: onDeviceMediaLibraryPickerCompletion)
    }()

    private let siteID: Int64
    private let allowsMultipleImages: Bool
    private let onCameraCaptureCompletion: CameraCaptureCoordinator.Completion
    private let onDeviceMediaLibraryPickerCompletion: DeviceMediaLibraryPicker.Completion
    private let onWPMediaPickerCompletion: WordPressMediaLibraryImagePickerViewController.Completion

    init(siteID: Int64,
         allowsMultipleImages: Bool,
         onCameraCaptureCompletion: @escaping CameraCaptureCoordinator.Completion,
         onDeviceMediaLibraryPickerCompletion: @escaping DeviceMediaLibraryPicker.Completion,
         onWPMediaPickerCompletion: @escaping WordPressMediaLibraryImagePickerViewController.Completion) {
        self.siteID = siteID
        self.allowsMultipleImages = allowsMultipleImages
        self.onCameraCaptureCompletion = onCameraCaptureCompletion
        self.onDeviceMediaLibraryPickerCompletion = onDeviceMediaLibraryPickerCompletion
        self.onWPMediaPickerCompletion = onWPMediaPickerCompletion
    }

    func present(context: MediaPickingContext) {
        let origin = context.origin
        let fromView = context.view

        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        menuAlert.view.tintColor = .text

        menuAlert.addAction(photoLibraryAction(origin: origin))

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            menuAlert.addAction(cameraAction(origin: origin))
        }

        menuAlert.addAction(siteMediaLibraryAction(origin: origin))
        menuAlert.addAction(cancelAction())

        menuAlert.popoverPresentationController?.sourceView = fromView
        menuAlert.popoverPresentationController?.sourceRect = fromView.bounds

        origin.present(menuAlert, animated: true)
    }

    func showMediaPicker(source: MediaPickingSource, from origin: UIViewController) {
        switch source {
        case .camera:
            ServiceLocator.analytics.track(.productImageSettingsAddImagesSourceTapped, withProperties: ["source": "camera"])
            showCameraCapture(origin: origin)
        case .photoLibrary:
            ServiceLocator.analytics.track(.productImageSettingsAddImagesSourceTapped, withProperties: ["source": "device"])
            showDeviceMediaLibraryPicker(origin: origin)
        case .siteMediaLibrary:
            ServiceLocator.analytics.track(.productImageSettingsAddImagesSourceTapped, withProperties: ["source": "wpmedia"])
            showSiteMediaPicker(origin: origin)
        }
    }
}

// MARK: Alert Actions
//
private extension MediaPickingCoordinator {
    func cameraAction(origin: UIViewController) -> UIAlertAction {
        let title = NSLocalizedString("Take a photo",
                                      comment: "Menu option for taking an image or video with the device's camera.")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            self?.showMediaPicker(source: .camera, from: origin)
        }
    }

    func photoLibraryAction(origin: UIViewController) -> UIAlertAction {
        let title = NSLocalizedString("Choose from device",
                                      comment: "Menu option for selecting media from the device's photo library.")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            self?.showMediaPicker(source: .photoLibrary, from: origin)
        }
    }

    func siteMediaLibraryAction(origin: UIViewController) -> UIAlertAction {
        let title = NSLocalizedString("WordPress Media Library",
                                      comment: "Menu option for selecting media from the site's media library.")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            self?.showMediaPicker(source: .siteMediaLibrary, from: origin)
        }
    }

    func cancelAction() -> UIAlertAction {
        return UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss the media picking action sheet"), style: .cancel, handler: nil)
    }
}

// MARK: Alert Action Handlers
//
private extension MediaPickingCoordinator {
    func showCameraCapture(origin: UIViewController) {
        cameraCapture.presentMediaCaptureIfAuthorized(origin: origin)
    }

    func showDeviceMediaLibraryPicker(origin: UIViewController) {
        deviceMediaLibraryPicker.presentPicker(origin: origin)
    }

    func showSiteMediaPicker(origin: UIViewController) {
        let wordPressMediaPickerViewController = WordPressMediaLibraryImagePickerViewController(siteID: siteID,
                                                                                                allowsMultipleImages: allowsMultipleImages,
                                                                                                onCompletion: onWPMediaPickerCompletion)
        origin.present(wordPressMediaPickerViewController, animated: true)
    }
}
