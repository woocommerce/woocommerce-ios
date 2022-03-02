import UIKit
import Yosemite
import WordPressUI
import Combine

/// Displays a list of settings for the user to choose to bulk update them for all variations
///
final class BulkUpdateViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: BulkUpdateViewModel

    private var subscriptions = Set<AnyCancellable>()

    /// A second tableview used to display the placeholder content when `displayGhostContent()` is called.
    ///
    private let ghostTableView = UITableView(frame: .zero, style: .plain)

    init(viewModel: BulkUpdateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureGhostTableView()
        configureViewModel()
    }

    /// Setup receiving updates for data changes and actives the view model
    ///
    private func configureViewModel() {
        viewModel.$syncState.sink { [weak self] state in
            guard let self = self else { return }

            switch state {
            // `.notStarted` is the initial state of the VM
            // and transition to this state is not possible
            case .notStarted:
                return
            case .syncing:
                self.displayGhostContent()
            case .synced:
                self.removeGhostContent()
                self.tableView.reloadData()
            case .error:
                self.removeGhostContent()
            }
        }.store(in: &subscriptions)

        viewModel.activate()
    }

    /// Configures the ghost view: registers Nibs and table view settings
    ///
    private func configureGhostTableView() {
        ghostTableView.registerNib(for: ValueOneTableViewCell.self)
        ghostTableView.translatesAutoresizingMaskIntoConstraints = false
        ghostTableView.backgroundColor = .listBackground
        ghostTableView.isScrollEnabled = false
        ghostTableView.isHidden = true

        view.addSubview(ghostTableView)
        view.pinSubviewToAllEdges(ghostTableView)
    }

    /// Configures the table view: registers Nibs & setup datasource / delegate
    ///
    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewHeaderSections()
        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    /// Renders the Placeholder content.
    ///
    private func displayGhostContent() {
        let options = GhostOptions(reuseIdentifier: ValueOneTableViewCell.reuseIdentifier, rowsPerSection: Constants.placeholderRowsPerSection)
        ghostTableView.displayGhostContent(options: options, style: .wooDefaultGhostStyle)
        ghostTableView.startGhostAnimation()
        ghostTableView.isHidden = false
    }

    /// Hides the Placeholder content.
    ///
    private func removeGhostContent() {
        ghostTableView.isHidden = true
        ghostTableView.stopGhostAnimation()
        ghostTableView.removeGhostContent()
    }

    private func registerTableViewHeaderSections() {
        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }

    private func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    private var sections: [Section] {
        return viewModel.sections
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension BulkUpdateViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Cell configuration
//
private extension BulkUpdateViewController {
    /// Configures a cell
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ValueOneTableViewCell where row == .regularPrice:
            configureRegularPrice(cell: cell)
        default:
            fatalError("Unidentified bulk update row type")
            break
        }
    }

    /// Configures the user facing properties of the cell displaying the regular price option
    ///
    func configureRegularPrice(cell: ValueOneTableViewCell) {

        cell.configure(with: viewModel.viewModelForDisplayingRegularPrice())
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension BulkUpdateViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Constants.sectionHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = viewModel.sections[section].title else {
            return nil
        }

        let reuseIdentifier = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? TwoColumnSectionHeaderView else {
            fatalError("Could not find section header view for reuseIdentifier \(reuseIdentifier)")
        }

        headerView.leftText = leftText
        headerView.rightText = nil

        return headerView
    }
}

// MARK: - Convenience Methods
//
private extension BulkUpdateViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

extension BulkUpdateViewController {
    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case regularPrice

        fileprivate var type: UITableViewCell.Type {
            return ValueOneTableViewCell.self
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private struct Constants {
    static let sectionHeight = CGFloat(44)
    static let placeholderRowsPerSection = [1]
}
