import UIKit

/// EditAttributesViewController: Displays the list of attributes for a product.
///
final class EditAttributesViewController: UIViewController {

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!
    @IBOutlet private var tableView: UITableView!

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
//        tableView.registerNib(for: ProductCategoryTableViewCell.self)
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
//        tableView.dataSource = self
//        tableView.delegate = self
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
        let rightBarButton = UIBarButtonItem(title: Localization.done,
                                             style: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }
}

// MARK: Button Actions & Navigation Handling
extension EditAttributesViewController {
    @objc private func doneButtonTapped() {
        // TODO: Create variation and notify back
    }

    @objc private func addButtonTapped() {
        // TODO: Launch add attribute flow and update product upon completion
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return false
    }
}

// MARK: Constants
private extension EditAttributesViewController {
    enum Localization {
        static let addNewAttribute = NSLocalizedString("Add New Attribute", comment: "Action to add new attribute on the Product Attributes screen")
        static let title = NSLocalizedString("Edit Attributes", comment: "Navigation title for the Product Attributes screen")
        static let done = NSLocalizedString("Done", comment: "Button title for the Done Action on the navigation bar")
    }
}
