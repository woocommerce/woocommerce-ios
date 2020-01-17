import WPMediaPicker
import MobileCoreServices

/// Encapsulates launching and customization of a media picker to import media from the Photo Library.
///
final class DeviceMediaLibraryPicker: NSObject {
    typealias Completion = ((_ selectedMediaItems: [PHAsset]) -> Void)
    private let onCompletion: Completion
    private let dataSource = WPPHAssetDataSource()

    // When cancelling the picker from the group library view, the presenting view controller is needed to dismiss the picker.
    // Ideally, `WPMediaPickerViewControllerDelegate`'s `mediaPickerControllerDidCancel` passes the view controller being presented.
    private var origin: UIViewController?

    init(onCompletion: @escaping Completion) {
        self.onCompletion = onCompletion
    }

    func presentPicker(origin: UIViewController) {
        self.origin = origin

        let options = WPMediaPickerOptions()
        options.showActionBar = false
        options.showSearchBar = false
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.allowCaptureOfMedia = false
        options.badgedUTTypes = [String(kUTTypeGIF)]

        let picker = WPNavigationMediaPickerViewController(options: options)
        picker.dataSource = dataSource
        picker.delegate = self

        picker.mediaPicker.collectionView?.backgroundColor = .listBackground

        origin.present(picker, animated: true)
    }
}

// MARK: - WPMediaPickerViewControllerDelegate
//
extension DeviceMediaLibraryPicker: WPMediaPickerViewControllerDelegate {
    func emptyViewController(forMediaPickerController picker: WPMediaPickerViewController) -> UIViewController? {
        return nil
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        picker.dismiss(animated: true)

        guard let assets = assets as? [PHAsset], assets.isEmpty == false else {
            return
        }

        onCompletion(assets)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        origin?.dismiss(animated: true)

        onCompletion([])

        origin = nil
    }
}
