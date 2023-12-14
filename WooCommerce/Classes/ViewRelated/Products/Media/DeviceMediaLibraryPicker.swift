import WPMediaPicker
import MobileCoreServices

/// Encapsulates launching and customization of a media picker to import media from the Photo Library.
///
final class DeviceMediaLibraryPicker: NSObject {
    typealias Completion = ((_ selectedMediaItems: [PHAsset]) -> Void)
    private let onCompletion: Completion
    private let dataSource = WPPHAssetDataSource()

    private let allowsMultipleImages: Bool

    private var origin: UIViewController?

    init(allowsMultipleImages: Bool, onCompletion: @escaping Completion) {
        self.allowsMultipleImages = allowsMultipleImages
        self.onCompletion = onCompletion
    }

    func presentPicker(origin: UIViewController) {
        let options = WPMediaPickerOptions()
        options.showActionBar = false
        options.showSearchBar = false
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.allowCaptureOfMedia = false
        options.badgedUTTypes = [UTType.gif.identifier]
        options.allowMultipleSelection = allowsMultipleImages

        let picker = WPNavigationMediaPickerViewController(options: options)
        picker.dataSource = dataSource
        picker.delegate = self

        picker.mediaPicker.collectionView?.backgroundColor = .listBackground

        self.origin = origin
        origin.present(picker, animated: true) { [weak self] in
            guard let self else { return }
            picker.presentationController?.delegate = self
        }
    }
}

// MARK: - WPMediaPickerViewControllerDelegate
//
extension DeviceMediaLibraryPicker: WPMediaPickerViewControllerDelegate {
    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        return nil
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard let assets = assets as? [PHAsset], assets.isEmpty == false else {
            return
        }
        dismissAndComplete(with: assets)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        dismissAndComplete(with: [])
    }
}

extension DeviceMediaLibraryPicker: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCompletion([])
    }
}

private extension DeviceMediaLibraryPicker {
    func dismissAndComplete(with assets: [PHAsset]) {
        let shouldAnimateMediaLibraryDismissal = assets.isEmpty
        origin?.dismiss(animated: shouldAnimateMediaLibraryDismissal) { [weak self] in
            self?.onCompletion(assets)
            self?.origin = nil
        }
    }
}
