import UIKit
import Yosemite

final class AttributeOptionPickerViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: AttributeOptionPickerViewModel

    typealias Completion = (_ attribute: ProductVariationAttribute?) -> Void
    private let onCompletion: Completion

    /// Init
    ///
    init(attribute: ProductAttribute, selectedOption: ProductVariationAttribute?, onCompletion: @escaping Completion) {
        self.viewModel = .init(attribute: attribute, selectedOption: selectedOption)
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        registerTableViewCells()
        configureTableView()
    }
}

// MARK: - View Configuration
//
private extension AttributeOptionPickerViewController {

    func configureNavigationBar() {
        title = viewModel.attributeName
    }

    func updateDoneButton() {
        if viewModel.isChanged {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                target: self,
                                                                action: #selector(doneButtonPressed))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        tableView.registerNib(for: BasicTableViewCell.self)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AttributeOptionPickerViewController: UITableViewDataSource {

    enum Row: Equatable {
        case anyAttribute
        case option(String)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.allRows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(BasicTableViewCell.self, for: indexPath)

        switch viewModel.allRows[indexPath.row] {
        case .anyAttribute:
            configureAnyAttribute(cell: cell)
        case .option(let optionName):
            configureAttribute(cell: cell, option: optionName)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AttributeOptionPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        viewModel.selectRow(at: indexPath)
        tableView.reloadData()
        updateDoneButton()
    }
}

// MARK: - Cell configuration
//
private extension AttributeOptionPickerViewController {
    func configureAnyAttribute(cell: BasicTableViewCell) {
        cell.textLabel?.text = Localization.anyAttributeOption

        if viewModel.selectedRow == .anyAttribute {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    func configureAttribute(cell: BasicTableViewCell, option: String?) {
        cell.textLabel?.text = option

        if case .option(let selectedOptionName) = viewModel.selectedRow, selectedOptionName == option {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
}

// MARK: - Navigation actions handling
//
extension AttributeOptionPickerViewController {

    @objc private func doneButtonPressed() {
        onCompletion(viewModel.resultAttribute)
    }
}

private extension AttributeOptionPickerViewController {
    enum Localization {
        static let anyAttributeOption = NSLocalizedString(
            "Any Attribute",
            comment: "Product variation attribute description where the attribute is set to any value.")
    }
}
