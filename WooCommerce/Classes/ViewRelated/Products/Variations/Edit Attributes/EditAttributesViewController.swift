import UIKit
import Yosemite

/// EditAttributesViewController: Displays the list of attributes for a product.
///
final class EditAttributesViewController: UIViewController {

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!
    @IBOutlet private var tableView: UITableView!

    private let viewModel: EditAttributesViewModel

    private let noticePresenter: NoticePresenter

    /// Assign this closure to be notified after a variation is created.
    ///
    var onVariationCreation: ((Product) -> Void)?

    /// Assign this closure to be notified after an attribute  is created.
    ///
    var onAttributeCreation: ((Product) -> Void)?

    init(viewModel: EditAttributesViewModel, noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.viewModel = viewModel
        self.noticePresenter = noticePresenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
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
private extension EditAttributesViewController {
    func registerTableViewCells() {
        tableView.registerNib(for: ImageAndTitleAndTextTableViewCell.self)
    }

    func configureAddButton() {
        addButton.setTitle(Localization.addNewAttribute, for: .normal)
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
        removeNavigationBackBarButtonText()
    }

    func configureTitle() {
        title = Localization.title
    }

    func configureRightButton() {
        guard viewModel.showDoneButton else {
            return
        }
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }
}

// MARK: Button Actions & Navigation Handling
extension EditAttributesViewController {
    @objc private func doneButtonTapped() {
        createVariation()
    }

    @objc private func addButtonTapped() {
        navigateToAddAttributeViewController()
    }

    /// Creates a variation and presents a loading screen while it is created.
    ///
    private func createVariation() {
        let progressViewController = InProgressViewController(viewProperties: .init(title: Localization.generatingVariation,
                                                                                    message: Localization.waitInstructions))
        present(progressViewController, animated: true)
        viewModel.generateVariation { [onVariationCreation, noticePresenter] result in
            progressViewController.dismiss(animated: true)

            guard let variation = try? result.get() else {
                return noticePresenter.enqueue(notice: .init(title: Localization.generateVariationError, feedbackType: .error))
            }

            onVariationCreation?(variation)
        }
    }

    /// Navigates to `AddAttributeViewController` and upon completion, update the product and clean the navigation stack
    ///
    private func navigateToAddAttributeViewController() {
        let addAttributeVM = AddAttributeViewModel(product: viewModel.product)
        let addAttributeViewController = AddAttributeViewController(viewModel: addAttributeVM) { [weak self] updatedProduct in
            guard let self = self else { return }
            self.viewModel.updateProduct(updatedProduct)
            self.onAttributeCreation?(updatedProduct)
            self.tableView.reloadData()
            self.navigationController?.popToViewController(self, animated: true)
        }
        show(addAttributeViewController, sender: self)
    }
}

// MARK: - UITableView conformance
//
extension EditAttributesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.attributes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ImageAndTitleAndTextTableViewCell.self, for: indexPath)
        let cellViewModel = viewModel.attributes[indexPath.row]
        cell.updateUI(viewModel: cellViewModel)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Navigate to edit attribute
    }
}

// MARK: Constants
private extension EditAttributesViewController {
    enum Localization {
        static let addNewAttribute = NSLocalizedString("Add New Attribute", comment: "Action to add new attribute on the Product Attributes screen")
        static let title = NSLocalizedString("Edit Attributes", comment: "Navigation title for the Product Attributes screen")

        static let generatingVariation = NSLocalizedString("Generating Variation", comment: "Title for the progress screen while generating a variation")
        static let waitInstructions = NSLocalizedString("Please wait while we create the new variation",
                                                        comment: "Instructions for the progress screen while generating a variation")
        static let generateVariationError = NSLocalizedString("The variation couldn't be generated.",
                                                              comment: "Error title when failing to generate a variation.")
    }
}
