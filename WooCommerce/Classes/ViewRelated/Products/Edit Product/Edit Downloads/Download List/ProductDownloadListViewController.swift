import UIKit
import CoreServices
import Yosemite
import WordPressUI

final class ProductDownloadListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!

    let viewModel: ProductDownloadListViewModelOutput & ProductDownloadListActionHandler

    // Completion callback
    //
    typealias Completion = (_ data: ProductDownloadsEditableData) -> Void
    private let onCompletion: Completion

    init(product: ProductFormDataModel, completion: @escaping Completion) {
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

        let moreBarButton: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .moreImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(moreButtonTapped))
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("Update products' downloadable files",
                                                          comment: "The action to update products' downloadable files settings")
            return button
        }()
        rightBarButtonItems.append(moreBarButton)

        let doneButtonTitle = NSLocalizedString("Done",
                                               comment: "Edit product downloadable files screen - button title to add downloadable files selection")
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
        ServiceLocator.analytics.track(.productDownloadableFilesDoneButtonTapped)
        viewModel.completeUpdating(onCompletion: onCompletion)
    }

    @objc private func moreButtonTapped() {
        ServiceLocator.analytics.track(.productDownloadableFilesMoreButtonTapped)
    }

    @objc private func addButtonTapped() {
        ServiceLocator.analytics.track(.productDownloadableFilesAddButtonTapped)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}
