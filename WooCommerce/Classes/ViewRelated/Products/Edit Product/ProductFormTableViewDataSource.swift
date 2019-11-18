import UIKit

/// Configures the sections and rows of Product form table view based on the view model.
///
final class ProductFormTableViewDataSource: NSObject {
    private let viewModel: ProductFormTableViewModel

    init(viewModel: ProductFormTableViewModel) {
        self.viewModel = viewModel
        super.init()
    }
}

extension ProductFormTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = viewModel.sections[section]
        switch section {
        case .images:
            return 0
        case .primaryFields(let rows):
            return rows.count
        case .details(let rows):
            return rows.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = viewModel.sections[indexPath.section]
        let reuseIdentifier = section.reuseIdentifier(at: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        configure(cell, section: section, indexPath: indexPath)
        return cell
    }
}

private extension ProductFormTableViewDataSource {
    func configure(_ cell: UITableViewCell, section: ProductFormSection, indexPath: IndexPath) {
        switch section {
        case .primaryFields(let rows):
            configureCellInPrimaryFieldsSection(cell, row: rows[indexPath.row])
        default:
            fatalError("Not implemented yet")
        }
    }
}

// MARK: Configure rows in Primary Fields Section
//
private extension ProductFormTableViewDataSource {
    func configureCellInPrimaryFieldsSection(_ cell: UITableViewCell, row: ProductFormSection.PrimaryFieldRow) {
        switch row {
        case .name(let name):
            configureName(cell: cell, name: name)
        case .description(let description):
            configureDescription(cell: cell, description: description)
        default:
            fatalError("Not implemented yet")
        }
    }

    func configureName(cell: UITableViewCell, name: String?) {
        if let name = name, name.isEmpty == false {
            guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
                fatalError()
            }
            let title = NSLocalizedString("Title",
                                          comment: "Title in the Product Title row on Product form screen when the description is non-empty.")
            let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: title, text: name)
            cell.updateUI(viewModel: viewModel)
        } else {
            guard let cell = cell as? BasicTableViewCell else {
                fatalError()
            }
            let placeholder = NSLocalizedString("Title (required)", comment: "Placeholder in the Product Title row on Product form screen.")
            cell.textLabel?.text = placeholder
            cell.textLabel?.applyBodyStyle()
            cell.textLabel?.textColor = .textSubtle
        }
        cell.accessoryType = .disclosureIndicator
    }
    
    func configureDescription(cell: UITableViewCell, description: String?) {
        if let description = description, description.isEmpty == false {
            guard let cell = cell as? ImageAndTitleAndTextTableViewCell else {
                fatalError()
            }
            let title = NSLocalizedString("Description",
                                          comment: "Title in the Product description row on Product form screen when the description is non-empty.")
            let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: title, text: description)
            cell.updateUI(viewModel: viewModel)
        } else {
            guard let cell = cell as? BasicTableViewCell else {
                fatalError()
            }
            let placeholder = NSLocalizedString("Describe your product", comment: "Placeholder in the Product description row on Product form screen.")
            cell.textLabel?.text = placeholder
            cell.textLabel?.applyBodyStyle()
            cell.textLabel?.textColor = .textSubtle
        }
        cell.accessoryType = .disclosureIndicator
    }
}
