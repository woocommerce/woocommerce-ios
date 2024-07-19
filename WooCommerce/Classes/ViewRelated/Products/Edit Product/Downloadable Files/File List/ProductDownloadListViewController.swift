import Combine
import UIKit
import Yosemite
import Photos
import MobileCoreServices
import enum Networking.DotcomError

final class ProductDownloadListViewController: UIViewController {
    private let product: ProductFormDataModel

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!

    let viewModel: ProductDownloadListViewModelOutput & ProductDownloadListActionHandler

    // Completion callback
    //
    typealias Completion = (_ data: ProductDownloadsEditableData, _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    // Device Media Library and Completion callbacks
    //
    private lazy var deviceMediaLibraryPicker: DeviceMediaLibraryPicker = {
        return DeviceMediaLibraryPicker(imagesOnly: false,
                                        allowsMultipleSelections: false,
                                        onCompletion: onDeviceMediaLibraryPickerCompletion)
    }()

    private lazy var wpMediaLibraryPicker: WordPressMediaLibraryPickerCoordinator =
        .init(siteID: product.siteID,
              imagesOnly: false,
              allowsMultipleSelections: false,
              onCompletion: onWPMediaPickerCompletion)

    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    private let localFileUploader: LocalFileUploader

    private var onDeviceLibraryPickerCompletion: DeviceMediaLibraryPicker.Completion?
    private var onWPLibraryPickerCompletion: WordPressMediaLibraryPickerViewController.Completion?
    private let productImageActionHandler: ProductImageActionHandler?
    private var cancellable: AnyCancellable?

    /// Loading view displayed while an user is uploading a new image
    ///
    private let loadingView = LoadingView(waitMessage: Localization.loadingMessage,
                                          backgroundColor: UIColor.black.withAlphaComponent(0.4))

    private lazy var downloadSettingsBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .moreImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentMoreActionSheetMenu(_:)))
        button.accessibilityTraits = .button
        button.accessibilityLabel = Localization.moreBarButtonAccessibilityLabel
        return button
    }()

    private lazy var doneBarButton = UIBarButtonItem(title: Localization.doneButton,
                                                     style: .done,
                                                     target: self,
                                                     action: #selector(doneButtonTapped))

    init(product: ProductFormDataModel,
         stores: StoresManager = ServiceLocator.stores,
         completion: @escaping Completion) {
        self.product = product
        viewModel = ProductDownloadListViewModel(product: product)
        onCompletion = completion
        productImageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                              productID: .product(id: product.productID),
                                                              imageStatuses: [],
                                                              stores: stores)
        localFileUploader = .init(siteID: product.siteID, productID: product.productID, stores: stores)
        super.init(nibName: type(of: self).nibName, bundle: nil)

        onDeviceLibraryPickerCompletion = { [weak self] assets in
            self?.onDeviceMediaLibraryPickerCompletion(assets: assets)
        }
        onWPLibraryPickerCompletion = { [weak self] mediaItems in
            self?.onWPMediaPickerCompletion(mediaItems: mediaItems)
        }
        cancellable = productImageActionHandler?.addAssetUploadObserver(self) { [weak self] asset, result in
            switch result {
            case let .success(productImage):
                ServiceLocator.analytics.track(.productDownloadableFileUploadingSuccess)
                self?.addDownloadableFile(fileName: productImage.name, fileURL: productImage.src)
            case let .failure(error):
                ServiceLocator.analytics.track(.productDownloadableFileUploadingFailed, withError: error)
                self?.showMediaUploadAlert(error: error)
            }
            self?.updateLoadingState(false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAddButton()
        configureAddButtonSeparator()
        registerTableViewCells()
        configureTableView()
        configureNavigationBar()
        handleSwipeBackGesture()
    }

    deinit {
        cancellable?.cancel()
    }
}

// MARK: - View Configuration
//
private extension ProductDownloadListViewController {
    func registerTableViewCells() {
        tableView.register(ImageAndTitleAndTextTableViewCell.loadNib(), forCellReuseIdentifier: ImageAndTitleAndTextTableViewCell.reuseIdentifier)
    }

    func configureAddButton() {
        addButton.setTitle(Localization.addFileButton, for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped(_:)), for: .touchUpInside)
        addButton.applySecondaryButtonStyle()
    }

    func configureAddButtonSeparator() {
        addButtonSeparator.backgroundColor = .systemColor(.separator)
    }

    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.removeLastCellSeparator()
        tableView.dragInteractionEnabled = true
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.reloadData()
    }

    func configureNavigationBar() {
        configureTitle()
        configureRightButtons()
    }

    func configureTitle() {
        title = Localization.title
    }

    func configureRightButtons() {
        var rightBarButtonItems = [UIBarButtonItem]()
        rightBarButtonItems.append(downloadSettingsBarButton)
        rightBarButtonItems.append(doneBarButton)
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
}

// MARK: - Navigation actions handling
//
extension ProductDownloadListViewController {
    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func doneButtonTapped() {
        viewModel.completeUpdating(onCompletion: onCompletion)
    }

    @objc private func addButtonTapped(_ sender: UIButton) {
        let title = Localization.bottomSheetTitle
        let viewProperties = BottomSheetListSelectorViewProperties(subtitle: title)
        let actions = viewModel.bottomSheetActions
        let dataSource = DownloadableFileBottomSheetListSelectorCommand(actions: actions) { [weak self] action in
            self?.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                switch action {
                case .deviceMedia:
                    self.showDeviceMediaLibraryPicker(origin: self)
                case .deviceDocument:
                    self.showDeviceDocumentPicker(origin: self)
                case .wordPressMediaLibrary:
                    self.showSiteMediaPicker(origin: self)
                case .fileURL:
                    self.addDownloadableFile(fileName: nil, fileURL: nil)
                }
            }
        }
        let listSelectorPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: dataSource)
        listSelectorPresenter.show(from: self, sourceView: sender, arrowDirections: .up)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: Action - Add/Edit Product Downloadable File Settings
//
private extension ProductDownloadListViewController {
    func addDownloadableFile(fileName: String?, fileURL: String?) {
        let downloadableFile = ProductDownload(downloadID: Constants.defaultAddProductDownloadID, name: fileName, fileURL: fileURL)
        openDownloadableFile(productDownload: downloadableFile, indexPath: nil, formType: .add)
    }

    func editDownloadableFile(indexPath: IndexPath) {
        let downloadableFile = viewModel.item(at: indexPath.row)?.downloadableFile
        openDownloadableFile(productDownload: downloadableFile, indexPath: indexPath, formType: .edit)
    }

    func openDownloadableFile(productDownload: ProductDownload?, indexPath: IndexPath?, formType: ProductDownloadFileViewController.FormType) {
        let viewController = ProductDownloadFileViewController(productDownload: productDownload,
                                                               downloadFileIndex: indexPath?.row,
                                                               formType: formType) { [weak self] (fileName, fileURL, fileID, hasUnsavedChanges) in
            self?.onAddEditDownloadableFileCompletion(fileName: fileName,
                                                      fileURL: fileURL,
                                                      fileID: fileID,
                                                      hasUnsavedChanges: hasUnsavedChanges,
                                                      indexPath: indexPath,
                                                      formType: formType)
        } deletion: { [weak self] in
            self?.onDownloadableFileDeletion(indexPath: indexPath)
        }

        navigationController?.pushViewController(viewController, animated: true)

    }

    func onAddEditDownloadableFileCompletion(fileName: String?,
                                             fileURL: String,
                                             fileID: String?,
                                             hasUnsavedChanges: Bool,
                                             indexPath: IndexPath?,
                                             formType: ProductDownloadFileViewController.FormType) {
        guard hasUnsavedChanges else {
            return
        }

        switch formType {
        case .add:
            viewModel.append(ProductDownloadDragAndDrop(downloadableFile: ProductDownload(downloadID: fileID ?? "",
                                                                                          name: fileName ?? "",
                                                                                          fileURL: fileURL)))
        case .edit:
            if let indexPath = indexPath {
                viewModel.update(at: indexPath.row,
                                 element: (ProductDownloadDragAndDrop(downloadableFile: ProductDownload(downloadID: fileID ?? "",
                                                                                                        name: fileName ?? "",
                                                                                                        fileURL: fileURL))))
            }
        }
        viewModel.completeUpdating(onCompletion: onCompletion)
        tableView.reloadData()
    }

    func onDownloadableFileDeletion(indexPath: IndexPath?) {
        guard let indexPath = indexPath else {
            return
        }
        viewModel.remove(at: indexPath.row)
        viewModel.completeUpdating(onCompletion: onCompletion)
        tableView.reloadData()
    }
}

// MARK: Action - Downloadable file settings
//
private extension ProductDownloadListViewController {
    @objc func presentMoreActionSheetMenu(_ sender: UIBarButtonItem) {
        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        menuAlert.view.tintColor = .text

        let downloadSettingsAction = UIAlertAction(title: Localization.downloadSettingsAction, style: .default) { [weak self] (action) in
            self?.showDownloadableFilesSettings()
        }
        menuAlert.addAction(downloadSettingsAction)

        let cancelAction = UIAlertAction(title: Localization.cancelAction, style: .cancel)
        menuAlert.addAction(cancelAction)

        let popoverController = menuAlert.popoverPresentationController
        popoverController?.barButtonItem = sender

        present(menuAlert, animated: true)
    }

    func showDownloadableFilesSettings() {
        let viewController = ProductDownloadSettingsViewController(product: product) { [weak self]
            (downloadLimit, downloadExpiry, hasUnsavedChanges) in
            self?.onDownloadSettingsCompletion(downloadLimit: downloadLimit,
                                               downloadExpiry: downloadExpiry,
                                               hasUnsavedChanges: hasUnsavedChanges)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    func onDownloadSettingsCompletion(downloadLimit: Int64,
                                      downloadExpiry: Int64,
                                      hasUnsavedChanges: Bool) {

        guard hasUnsavedChanges else {
            return
        }

        viewModel.handleDownloadLimitChange(downloadLimit)
        viewModel.handleDownloadExpiryChange(downloadExpiry)
        viewModel.completeUpdating(onCompletion: onCompletion)
    }
}

// MARK: Alert Action Handlers
//
private extension ProductDownloadListViewController {
    func showDeviceMediaLibraryPicker(origin: UIViewController) {
        deviceMediaLibraryPicker.presentPicker(origin: origin)
    }

    func showDeviceDocumentPicker(origin: UIViewController) {
        let types: [UTType] = [.pdf, .text, .spreadsheet, .audio, .video, .zip, .presentation]
        let importMenu = UIDocumentPickerViewController(forOpeningContentTypes: types)
        importMenu.allowsMultipleSelection = false
        importMenu.delegate = self
        origin.present(importMenu, animated: true)
    }

    func showSiteMediaPicker(origin: UIViewController) {
        wpMediaLibraryPicker.start(from: origin)
    }

    func showMediaUploadAlert(error: Error) {
        let errorMessage: String = {
            switch error {
            case DotcomError.unknown(let code, _) where code == Constants.unsupportedMimeTypeCode:
                Localization.unsupportedFileType
            case MediaAssetExporter.AssetExportError.unsupportedPHAssetMediaType:
                Localization.unsupportedFileType
            default:
                Localization.errorUploadingLocalFile
            }
        }()
        let notice = Notice(title: errorMessage, feedbackType: .error)
        noticePresenter.enqueue(notice: notice)
    }
}

extension ProductDownloadListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // we don't support multiple selections, so we expect only one URL to be returned.
        guard let url = urls.first else {
            return
        }

        /// Double check that access to the file is granted.
        /// This should never return false, but who knows ¯\_(ツ)_/¯
        guard url.startAccessingSecurityScopedResource() else {
            url.stopAccessingSecurityScopedResource()
            DDLogError("⛔️ Error accessing local file for uploading: no permission granted.")
            let notice = Notice(title: Localization.permissionMissing, feedbackType: .error)
            noticePresenter.enqueue(notice: notice)
            return
        }

        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.updateLoadingState(true)
        }

        ServiceLocator.analytics.track(.productDownloadableDocumentSelected)

        Task { @MainActor in
            do {
                let media = try await localFileUploader.uploadFile(url: url)
                ServiceLocator.analytics.track(.productDownloadableFileUploadingSuccess)
                addDownloadableFile(fileName: media.name, fileURL: media.src)
                updateLoadingState(false)
            } catch {
                ServiceLocator.analytics.track(.productDownloadableFileUploadingFailed, withError: error)
                updateLoadingState(false)
                showMediaUploadAlert(error: error)
            }

            url.stopAccessingSecurityScopedResource()
        }
    }

    func updateLoadingState(_ isLoading: Bool) {
        doneBarButton.isEnabled = !isLoading
        downloadSettingsBarButton.isEnabled = !isLoading

        if isLoading {
            loadingView.showLoader(in: view)
        } else {
            loadingView.hideLoader()
        }
    }
}

// MARK: Action handling for device media library picker
//
private extension ProductDownloadListViewController {
    func onDeviceMediaLibraryPickerCompletion(assets: [PHAsset]) {
        guard let asset = assets.first else {
            return
        }
        ServiceLocator.analytics.track(.productDownloadableOnDeviceMediaSelected, withProperties: ["type": asset.mediaType.rawValue])
        productImageActionHandler?.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
        updateLoadingState(true)
    }
}

// MARK: - Action handling for WordPress Media Library
//
private extension ProductDownloadListViewController {
    func onWPMediaPickerCompletion(mediaItems: [Media]) {
        guard mediaItems.isNotEmpty else {
            return
        }
        addDownloadableFile(fileName: mediaItems.first?.name, fileURL: mediaItems.first?.src)
    }
}

// MARK: - UITableView Datasource and Delegate conformance
//
extension ProductDownloadListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageAndTitleAndTextTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }

        if let viewModel = viewModel.item(at: indexPath.row) {
            configureCell(cell: cell, model: viewModel.downloadableFile)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editDownloadableFile(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let item = viewModel.item(at: sourceIndexPath.row) {
            viewModel.remove(at: destinationIndexPath.row)
            viewModel.insert(item, at: destinationIndexPath.row)
        }
    }
}

// MARK: - UITableViewCell Setup
//
private extension ProductDownloadListViewController {
    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductDownload) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.name,
                                                                    text: model.fileURL,
                                                                    image: UIImage.menuImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 1)
        cell.updateUI(viewModel: viewModel)
    }
}

// MARK: - Constants

private extension ProductDownloadListViewController {
    enum Localization {
        static let loadingMessage = NSLocalizedString("Please wait...",
                                                      comment: "Text on the loading view of the product downloadable file screen indicating the user to wait")
        static let addFileButton = NSLocalizedString("Add File", comment: "Action to add downloadable file on the Product Downloadable Files screen")
        static let title = NSLocalizedString("Downloadable Files",
                                             comment: "Edit product downloadable files screen - Screen title")
        static let moreBarButtonAccessibilityLabel = NSLocalizedString("View downloadable file settings",
                                                                       comment: "The action to update downloadable files settings for a product")
        static let doneButton = NSLocalizedString("Done",
                                                  comment: "Edit product downloadable files screen - button title to apply changes to downloadable files")
        static let bottomSheetTitle = NSLocalizedString("Select upload method",
                                                        comment: "Title of the bottom sheet from the product downloadable file to add a new downloadable file.")
        static let downloadSettingsAction = NSLocalizedString("Download Settings",
                                                              comment: "Button title Download Settings in Downloadable Files More Options Action Sheet")
        static let cancelAction = NSLocalizedString("Cancel",
                                                    comment: "Button title Cancel in Downloadable Files More Options Action Sheet")
        static let unsupportedFileType = NSLocalizedString(
            "productDownloadListViewController.notice.unsupportedFileType",
            value: "The selected file type is not supported.",
            comment: "Alert message about an unsupported file type when uploading file for a downloadable product."
        )
        static let errorUploadingLocalFile = NSLocalizedString(
            "productDownloadListViewController.notice.errorUploadingLocalFile",
            value: "Error uploading the file. Please try again.",
            comment: "Alert message to inform the user about a failure in uploading file for a downloadable product."
        )
        static let permissionMissing = NSLocalizedString(
            "productDownloadListViewController.notice.permissionMissing",
            value: "You don't have the permission to access the file.",
            comment: "Alert message about the missing permission to upload a local file for a downloadable product."
        )
    }
}

extension ProductDownloadListViewController {
    private enum Constants {
        static let defaultAddProductDownloadID: String = ""
        static let unsupportedMimeTypeCode = "unsupported_mime_type"
    }
}
