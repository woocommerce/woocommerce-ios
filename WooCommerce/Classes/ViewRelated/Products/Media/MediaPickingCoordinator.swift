import UIKit
import SwiftUI
import protocol WooFoundation.Analytics

/// The source of the media to pick from.
enum MediaPickingSource: Hashable, Identifiable {
    var id: Self {
        return self
    }

    /// Device camera.
    case camera
    /// Device photo library.
    case photoLibrary
    /// Site's media library.
    case siteMediaLibrary
    /// Media attached to given product.
    case productMedia(productID: Int64)
}

/// Prepares the alert controller that will be presented when trying to add media to a site.
///
final class MediaPickingCoordinator {
    private lazy var cameraCapture: CameraCaptureCoordinator = {
        return CameraCaptureCoordinator(onCompletion: onCameraCaptureCompletion)
    }()

    private lazy var deviceMediaLibraryPicker: DeviceMediaLibraryPicker = {
        return DeviceMediaLibraryPicker(imagesOnly: imagesOnly,
                                        allowsMultipleSelections: allowsMultipleSelections,
                                        onCompletion: onDeviceMediaLibraryPickerCompletion)
    }()

    private lazy var wpMediaLibraryPicker: WordPressMediaLibraryPickerCoordinator =
        .init(siteID: siteID,
              imagesOnly: imagesOnly,
              allowsMultipleSelections: allowsMultipleSelections,
              onCompletion: onWPMediaPickerCompletion)

    private var productImagePickerViewModel: ProductImagePickerViewModel?

    private let siteID: Int64
    private let imagesOnly: Bool
    private let allowsMultipleSelections: Bool
    private let flow: Flow
    private let analytics: Analytics
    private let onCameraCaptureCompletion: CameraCaptureCoordinator.Completion
    private let onDeviceMediaLibraryPickerCompletion: DeviceMediaLibraryPicker.Completion
    private let onWPMediaPickerCompletion: WordPressMediaLibraryPickerViewController.Completion
    private let onProductImagePickerCompletion: ProductImagePickerView.Completion?

    init(siteID: Int64,
         imagesOnly: Bool,
         allowsMultipleSelections: Bool,
         flow: Flow,
         analytics: Analytics = ServiceLocator.analytics,
         onCameraCaptureCompletion: @escaping CameraCaptureCoordinator.Completion,
         onDeviceMediaLibraryPickerCompletion: @escaping DeviceMediaLibraryPicker.Completion,
         onWPMediaPickerCompletion: @escaping WordPressMediaLibraryPickerViewController.Completion,
         onProductImagePickerCompletion: ProductImagePickerView.Completion? = nil) {
        self.siteID = siteID
        self.imagesOnly = imagesOnly
        self.allowsMultipleSelections = allowsMultipleSelections
        self.flow = flow
        self.analytics = analytics
        self.onCameraCaptureCompletion = onCameraCaptureCompletion
        self.onDeviceMediaLibraryPickerCompletion = onDeviceMediaLibraryPickerCompletion
        self.onWPMediaPickerCompletion = onWPMediaPickerCompletion
        self.onProductImagePickerCompletion = onProductImagePickerCompletion
    }

    @MainActor
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

    @MainActor
    func showMediaPicker(source: MediaPickingSource, from origin: UIViewController) {
        analytics.track(.productImageSettingsAddImagesSourceTapped, withProperties: [
            "source": source.analyticsValue,
            "flow": flow.rawValue
        ])
        switch source {
        case .camera:
            showCameraCapture(origin: origin)
        case .photoLibrary:
            showDeviceMediaLibraryPicker(origin: origin)
        case .siteMediaLibrary:
            showSiteMediaPicker(origin: origin)
        case .productMedia(let productID):
            showProductImagePicker(productID: productID, from: origin)
        }
    }
}

// MARK: Alert Actions
//
private extension MediaPickingCoordinator {
    @MainActor
    func cameraAction(origin: UIViewController) -> UIAlertAction {
        let title = NSLocalizedString("Take a photo",
                                      comment: "Menu option for taking an image or video with the device's camera.")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            self?.showMediaPicker(source: .camera, from: origin)
        }
    }

    @MainActor
    func photoLibraryAction(origin: UIViewController) -> UIAlertAction {
        let title = NSLocalizedString("Choose from device",
                                      comment: "Menu option for selecting media from the device's photo library.")
        return UIAlertAction(title: title, style: .default) { [weak self] action in
            self?.showMediaPicker(source: .photoLibrary, from: origin)
        }
    }

    @MainActor
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
        wpMediaLibraryPicker.start(from: origin)
    }

    @MainActor
    func showProductImagePicker(productID: Int64, from origin: UIViewController) {
        let viewModel = ProductImagePickerViewModel(siteID: siteID, productID: productID)
        let viewController = UIHostingController(rootView: ProductImagePickerView(viewModel: viewModel, onSelection: { [weak self] selectedImage in
            self?.onProductImagePickerCompletion?(selectedImage)
            origin.dismiss(animated: true)
        }, onDismiss: { [weak self] in
            self?.onProductImagePickerCompletion?(nil)
            origin.dismiss(animated: true)
        }))
        origin.present(viewController, animated: true)
        productImagePickerViewModel = viewModel
    }
}

private extension MediaPickingSource {
    var analyticsValue: String {
        switch self {
        case .camera:
            return "camera"
        case .photoLibrary:
            return "device"
        case .siteMediaLibrary:
            return "wpmedia"
        case .productMedia:
            return "product_media"
        }
    }
}

extension MediaPickingCoordinator {
    // The flow for picking media
    enum Flow: String {
        case productForm = "product_form"
        case productFromImageForm = "product_from_image_form"
        case blazeEditAdForm = "blaze_edit_ad_form"
        case readTextFromProductPhoto = "read_text_from_product_photo"
    }
}
