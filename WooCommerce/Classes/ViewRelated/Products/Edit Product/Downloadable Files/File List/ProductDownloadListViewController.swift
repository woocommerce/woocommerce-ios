import UIKit
import Yosemite

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

    init(product: ProductFormDataModel, completion: @escaping Completion) {
        self.product = product
        viewModel = ProductDownloadListViewModel(product: product)
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
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
}

// MARK: - View Configuration
//
private extension ProductDownloadListViewController {
    func registerTableViewCells() {
        tableView.register(ImageAndTitleAndTextTableViewCell.loadNib(), forCellReuseIdentifier: ImageAndTitleAndTextTableViewCell.reuseIdentifier)
    }

    func configureAddButton() {
        addButton.setTitle(NSLocalizedString("Add File", comment: "Action to add downloadable file on the Product Downloadable Files screen"), for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
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
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.reloadData()
    }

    func configureNavigationBar() {
        configureTitle()
        configureRightButtons()
    }

    func configureTitle() {
        title = NSLocalizedString("Downloadable Files",
                                  comment: "Edit product downloadable files screen - Screen title")
    }

    func configureRightButtons() {
        var rightBarButtonItems = [UIBarButtonItem]()

        let downloadSettingsBarButton: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .moreImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(moreButtonTapped))
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("View downloadable file settings",
                                                          comment: "The action to update downloadable files settings for a product")
            return button
        }()
        rightBarButtonItems.append(downloadSettingsBarButton)

        let doneButtonTitle = NSLocalizedString("Done",
                                                comment: "Edit product downloadable files screen - button title to apply changes to downloadable files")
        let doneBarButton = UIBarButtonItem(title: doneButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
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
        // TODO: - add analytics
        viewModel.completeUpdating(onCompletion: onCompletion)
    }

    @objc private func moreButtonTapped() {
        // TODO: - add analytics
        presentMoreActionSheetMenu()
    }

    @objc private func addButtonTapped() {
        // TODO: - add analytics
        addEditDownloadableFile(indexPath: nil, formType: .add)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: Action - Add/Edit Product Downloadable File Settings
//
extension ProductDownloadListViewController {
    func addEditDownloadableFile(indexPath: IndexPath?, formType: ProductDownloadFileViewController.FormType) {
        let downloadableFile = viewModel.item(at: indexPath?.row ?? -1)?.downloadableFile
        let viewController = ProductDownloadFileViewController(productDownload: downloadableFile,
                                                               downloadFileIndex: indexPath?.row,
                                                               formType: formType) { [weak self]
            (fileName, fileURL, fileID, hasUnsavedChanges) in
            self?.onAddEditDownloadableFileCompletion(fileName: fileName,
                                                      fileURL: fileURL,
                                                      fileID: fileID,
                                                      hasUnsavedChanges: hasUnsavedChanges,
                                                      indexPath: indexPath,
                                                      formType: formType)
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
}

// MARK: Action - Downloadable file settings
//
private extension ProductDownloadListViewController {
    func presentMoreActionSheetMenu() {
        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        menuAlert.view.tintColor = .text

        let downloadSettingsTitle = NSLocalizedString("Download Settings",
                                                      comment: "Button title Download Settings in Downloadable Files More Options Action Sheet")
        let downloadSettingsAction = UIAlertAction(title: downloadSettingsTitle, style: .default) { [weak self] (action) in
            self?.showDownloadableFilesSettings()
        }
        menuAlert.addAction(downloadSettingsAction)

        let cancelTitle = NSLocalizedString("Cancel",
                                            comment: "Button title Cancel in Downloadable Files More Options Action Sheet")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        menuAlert.addAction(cancelAction)

        menuAlert.popoverPresentationController?.sourceView = view
        menuAlert.popoverPresentationController?.sourceRect = view.bounds

        present(menuAlert, animated: true)
    }

    func showDownloadableFilesSettings() {
        // TODO: - add analytics
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
        addEditDownloadableFile(indexPath: indexPath, formType: .edit)
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
