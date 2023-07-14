import UIKit
import WPMediaPicker
import struct Yosemite.Media

/// Coordinates navigation for picking media from the site's WordPress media library.
/// `NSObject` is required for `UIAdaptivePresentationControllerDelegate` conformance.
final class WordPressMediaLibraryImagePickerCoordinator: NSObject {
    typealias Completion = WordPressMediaLibraryImagePickerViewController.Completion

    private var origin: UIViewController?

    private let siteID: Int64
    private let allowsMultipleImages: Bool
    private let onCompletion: Completion

    init(siteID: Int64, allowsMultipleImages: Bool, onCompletion: @escaping Completion) {
        self.siteID = siteID
        self.allowsMultipleImages = allowsMultipleImages
        self.onCompletion = onCompletion
    }

    /// Starts navigation to show the media picker.
    /// - Parameter origin: View controller to present the media picker.
    func start(from origin: UIViewController) {
        let wordPressMediaPickerViewController = WordPressMediaLibraryImagePickerViewController(
            siteID: siteID,
            allowsMultipleImages: allowsMultipleImages) { [weak self] selectedMediaItems in
                self?.dismissAndComplete(with: selectedMediaItems)
            }
        self.origin = origin
        origin.present(wordPressMediaPickerViewController, animated: true) { [weak self] in
            wordPressMediaPickerViewController.presentationController?.delegate = self
        }
    }
}

extension WordPressMediaLibraryImagePickerCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCompletion([])
    }
}

private extension WordPressMediaLibraryImagePickerCoordinator {
    func dismissAndComplete(with mediaItems: [Media]) {
        let shouldAnimateMediaLibraryDismissal = mediaItems.isEmpty
        origin?.dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
            self?.onCompletion(mediaItems)
            self?.origin = nil
        }
    }
}
