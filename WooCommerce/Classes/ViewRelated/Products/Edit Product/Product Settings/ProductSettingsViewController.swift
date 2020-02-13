import UIKit
import Yosemite

// MARK: - ProductSettingsViewController
//
final class ProductSettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var viewModel: ProductSettingsViewModel

    init(product: Product) {
        viewModel = ProductSettingsViewModel(product: product)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
    }

}

// MARK: - View Configuration
//
private extension ProductSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Product Settings", comment: "Product Settings navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        viewModel.registerTableViewCells(tableView)
        viewModel.registerTableViewHeaderFooters(tableView)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = viewModel.sections[section]
        switch section {
        case .publishSettings( _, let rows):
            return rows.count
        case .moreOptions( _, let rows):
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

    func configure(_ cell: UITableViewCell, section: ProductSettingsSection, indexPath: IndexPath) {
        switch section {
        case .publishSettings( _, let rows):
            configureCellInPublishSettingsSection(cell, row: rows[indexPath.row])
        case .moreOptions( _, let rows):
            configureCellInMoreOptionsSection(cell, row: rows[indexPath.row])
        }
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = viewModel.sections[section]

        var sectionTitle = ""
        switch section {
        case .publishSettings(let title, _):
            sectionTitle = title
        case .moreOptions(let title, _):
            sectionTitle = title
        }

        guard sectionTitle.isNotEmpty else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError("Unregistered \(TwoColumnSectionHeaderView.self) in UITableView")
        }

        headerView.leftText = sectionTitle
        headerView.rightText = nil

        return headerView
    }
}


// MARK: Configure rows in Publish Settings Section
//
private extension ProductSettingsViewController {
    func configureCellInPublishSettingsSection(_ cell: UITableViewCell, row: ProductSettingsSection.PublishSettingsRow) {
        switch row {
        case .visibility(let visibility):
            configureVisibilityCell(cell: cell, visibility: visibility)
        }
    }

    func configureVisibilityCell(cell: UITableViewCell, visibility: String?) {
        guard let cell = cell as? BasicTableViewCell else {
            fatalError()
        }

        cell.textLabel?.text = NSLocalizedString("Visibility", comment: "Visibility label in Product Settings")
        cell.detailTextLabel?.text = visibility
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: Configure rows in More Options Section
//
private extension ProductSettingsViewController {
    func configureCellInMoreOptionsSection(_ cell: UITableViewCell, row: ProductSettingsSection.MoreOptionsRow) {
        switch row {
        case .slug(let slug):
            configureSlugCell(cell: cell, slug: slug)
        }
    }

    func configureSlugCell(cell: UITableViewCell, slug: String?) {
        guard let cell = cell as? BasicTableViewCell else {
            fatalError()
        }

        cell.textLabel?.text = NSLocalizedString("Slug", comment: "Slug label in Product Settings")
        cell.detailTextLabel?.text = slug
        cell.accessoryType = .disclosureIndicator
    }
}
