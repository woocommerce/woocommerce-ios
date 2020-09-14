import UIKit
import Yosemite
import WordPressUI

final class ProductDownloadListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!

    private let viewModel: [ProductDownload]

    // Completion callback
    //
    typealias Completion = (_ downloads: [ProductDownload]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.viewModel = product.downloads
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
    }

    func configureNavigationBar() {
        configureTitle()
        configureRightButton()
    }

    func configureTitle() {
        title = NSLocalizedString("Downloadable Files", comment: "Edit product downloadable files screen - Screen title")
    }

    func configureRightButton() {
        let applyButtonTitle = NSLocalizedString("Done",
                                               comment: "Edit product downloadable files screen - button title to add downloadable files selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }
}

// MARK: - Navigation actions handling
//
extension ProductDownloadListViewController {

    override func shouldPopOnBackButton() -> Bool {
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func doneButtonTapped() {
        ServiceLocator.analytics.track(.productDownloadableFileSettingsDoneButtonTapped)
        onCompletion(viewModel)
    }

    @objc private func addButtonTapped() {
        ServiceLocator.analytics.track(.productDownloadableFileSettingsAddButtonTapped)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UITableViewConformace conformance
//
extension ProductDownloadListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ImageAndTitleAndTextTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ImageAndTitleAndTextTableViewCell else {
            fatalError()
        }

        if let fileViewModel = viewModel[safe: indexPath.row] {
            configureCell(cell: cell, model: fileViewModel)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

// MARK: - UITableViewCell Setup
//
extension ProductDownloadListViewController {
    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductDownload) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.name,
                                                                    text: model.fileURL,
                                                                    image: UIImage.menuImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 1,
                                                                    isActionable: true)
        cell.updateUI(viewModel: viewModel)
    }
}
