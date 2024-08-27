import UIKit
import WPMediaPicker
import struct Yosemite.Media

/// Coordinates navigation for picking media from the site's WordPress media library.
/// `NSObject` is required for `UIAdaptivePresentationControllerDelegate` conformance.
final class WordPressMediaLibraryPickerCoordinator: NSObject {
    typealias Completion = WordPressMediaLibraryPickerViewController.Completion

    private var origin: UIViewController?

    private let siteID: Int64
    private let imagesOnly: Bool
    private let allowsMultipleSelections: Bool
    private let onCompletion: Completion

    init(siteID: Int64, imagesOnly: Bool, allowsMultipleSelections: Bool, onCompletion: @escaping Completion) {
        self.siteID = siteID
        self.imagesOnly = imagesOnly
        self.allowsMultipleSelections = allowsMultipleSelections
        self.onCompletion = onCompletion
    }

    /// Starts navigation to show the media picker.
    /// - Parameters:
    ///   - origin: View controller to present the media picker.
    ///   - productID: If non-nil loads only media attached to this product ID
    func start(from origin: UIViewController,
               productID: Int64? = nil) {
        let wordPressMediaPickerViewController = WordPressMediaLibraryPickerViewController(
            siteID: siteID,
            productID: productID,
            imagesOnly: imagesOnly,
            allowsMultipleSelections: allowsMultipleSelections) { [weak self] selectedMediaItems in
                self?.dismissAndComplete(with: selectedMediaItems)
            }
        self.origin = origin
        origin.present(wordPressMediaPickerViewController, animated: true) { [weak self] in
            wordPressMediaPickerViewController.presentationController?.delegate = self
        }
    }
}

extension WordPressMediaLibraryPickerCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCompletion([])
    }
}

private extension WordPressMediaLibraryPickerCoordinator {
    func dismissAndComplete(with mediaItems: [Media]) {
        let shouldAnimateMediaLibraryDismissal = mediaItems.isEmpty
        origin?.dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
            self?.onCompletion(mediaItems)
            self?.origin = nil
        }
    }
}
