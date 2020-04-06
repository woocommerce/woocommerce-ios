import UIKit
import WPMediaPicker
import CoreServices
import Yosemite

/// Displays a collection of images from WordPress media library for picking.
///
final class WordPressMediaLibraryImagePickerViewController: UIViewController {
    typealias Completion = ((_ selectedMediaItems: [Media]) -> Void)
    private let onCompletion: Completion

    private lazy var mediaPickerOptions: WPMediaPickerOptions = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.allowCaptureOfMedia = false
        options.showSearchBar = false
        options.showActionBar = false
        options.badgedUTTypes = [String(kUTTypeGIF)]
        options.allowMultipleSelection = true
        return options
    }()

    private lazy var mediaLibraryDataSource: WordPressMediaLibraryPickerDataSource = WordPressMediaLibraryPickerDataSource(siteID: siteID)

    private var mediaPickerNavigationController: WPNavigationMediaPickerViewController!

    private let siteID: Int64

    init(siteID: Int64, onCompletion: @escaping Completion) {
        self.siteID = siteID
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMediaPickerChildViewController()
    }
}

// MARK: - Configurations
//
private extension WordPressMediaLibraryImagePickerViewController {
    func configureMediaPickerChildViewController() {
        let picker = WPNavigationMediaPickerViewController()
        picker.dataSource = mediaLibraryDataSource
        picker.startOnGroupSelector = false
        picker.showGroupSelector = false
        picker.delegate = self
        picker.modalPresentationStyle = .currentContext

        picker.mediaPicker.options = mediaPickerOptions
        picker.mediaPicker.collectionView?.backgroundColor = .listBackground
        picker.mediaPicker.title = NSLocalizedString("WordPress Media Library", comment: "Navigation bar title for WordPress Media Library image picker")

        let emptyImagesText = NSLocalizedString("No images yet",
                                                comment: "Placeholder text shown when there are no images for the WordPress Media Library yet")
        picker.mediaPicker.defaultEmptyView.text = emptyImagesText
        self.mediaPickerNavigationController = picker

        picker.view.translatesAutoresizingMaskIntoConstraints = false

        add(picker)
        view.pinSubviewToAllEdges(picker.view)
    }
}

extension WordPressMediaLibraryImagePickerViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        onCompletion(assets as? [Media] ?? [])
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion([])
    }
}
