import UIKit
import WPMediaPicker
import CoreServices
import Yosemite

/// Displays a collection of media from WordPress media library for picking.
///
final class WordPressMediaLibraryPickerViewController: UIViewController {
    typealias Completion = ((_ selectedMediaItems: [Media]) -> Void)
    private let onCompletion: Completion

    private lazy var mediaPickerOptions: WPMediaPickerOptions = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = imagesOnly ? .image : .all
        options.allowCaptureOfMedia = false
        options.showSearchBar = false
        options.showActionBar = false
        options.badgedUTTypes = [UTType.gif.identifier]
        options.allowMultipleSelection = allowsMultipleSelections
        return options
    }()

    private lazy var mediaLibraryDataSource = WordPressMediaLibraryPickerDataSource(siteID: siteID,
                                                                                    productID: productID,
                                                                                    imagesOnly: imagesOnly)

    private var mediaPickerNavigationController: WPNavigationMediaPickerViewController!

    private let siteID: Int64
    private let productID: Int64?
    private let imagesOnly: Bool
    private let allowsMultipleSelections: Bool

    /// Initializer
    /// - Parameters:
    ///   - siteID: site to fetch media from
    ///   - productID: If non-nil loads only media attached to this product ID
    ///   - imagesOnly: load only images if `true`
    ///   - allowsMultipleSelections: Allows selecting more than one Media if `true`
    ///   - onCompletion: Called upon finishing media selection
    init(siteID: Int64,
         productID: Int64? = nil,
         imagesOnly: Bool,
         allowsMultipleSelections: Bool,
         onCompletion: @escaping Completion) {
        self.siteID = siteID
        self.productID = productID
        self.imagesOnly = imagesOnly
        self.allowsMultipleSelections = allowsMultipleSelections
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
private extension WordPressMediaLibraryPickerViewController {
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

        let emptyContentText = NSLocalizedString(
            "wordpressMediaLibraryPickerViewController.emptyContent.loading",
            value: "Loading media...",
            comment: "Placeholder text shown when loading media for the WordPress Media Library"
        )
        picker.mediaPicker.defaultEmptyView.text = emptyContentText
        picker.mediaPicker.defaultEmptyView.sizeToFit()
        self.mediaPickerNavigationController = picker

        picker.view.translatesAutoresizingMaskIntoConstraints = false

        add(picker)
        view.pinSubviewToAllEdges(picker.view)
    }
}

extension WordPressMediaLibraryPickerViewController: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        let cancellableMediaItems = assets as? [CancellableMedia] ?? []
        let mediaItems = cancellableMediaItems.map { $0.media }
        onCompletion(mediaItems)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion([])
    }
}
