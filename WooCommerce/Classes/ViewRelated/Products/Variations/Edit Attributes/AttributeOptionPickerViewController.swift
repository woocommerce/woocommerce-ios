import UIKit
import Yosemite

final class AttributeOptionPickerViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    let attribute: ProductAttribute
    let selectedOption: ProductVariationAttribute?

    /// Init
    ///
    init(attribute: ProductAttribute, selectedOption: ProductVariationAttribute?) {
        self.attribute = attribute
        self.selectedOption = selectedOption
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
        title = attribute.name

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneButtonPressed))
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attribute.options.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(BasicTableViewCell.self, for: indexPath)
        if indexPath.row == 0 {
            configureAnyAttribute(cell: cell)
        } else {
            configureAttribute(cell: cell, option: attribute.options[safe: indexPath.row - 1])
        }

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AttributeOptionPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Cell configuration
//
private extension AttributeOptionPickerViewController {
    func configureAnyAttribute(cell: BasicTableViewCell) {
        cell.textLabel?.text = Localization.anyAttributeOption

        if selectedOption == nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    func configureAttribute(cell: BasicTableViewCell, option: String?) {
        cell.textLabel?.text = option

        if selectedOption?.option == option {
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
        // TODO-3518: Save updated attributes
    }

    private func presentAttributeOptions(for existingAttribute: ProductAttribute) {
        // TODO-3515: Show options for attribute
    }
}

private extension AttributeOptionPickerViewController {
    enum Localization {
        static let anyAttributeOption = NSLocalizedString(
            "Any Attribute",
            comment: "Product variation attribute description where the attribute is set to any value.")
    }
}
