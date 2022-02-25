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
        configureViewModel()
    }

    /// Setup receiving updates for data changes and actives the view model
    ///
    private func configureViewModel() {
        viewModel.$syncState.sink { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .notStarted:
                fallthrough
            case .syncing:
                self.displayPlaceholder()
            case .synced:
                fallthrough
            case .error:
                self.removePlaceholder()
                self.removePlaceholder()
                self.removePlaceholder()
            }
        }.store(in: &subscriptions)

        viewModel.activate()
    }

    /// Renders the placeholders for the the bulk update settings
    ///
    func displayPlaceholder() {
        // We currently support 2 options (Regular & Sale price)
        let options = GhostOptions(reuseIdentifier: ValueOneTableViewCell.reuseIdentifier, rowsPerSection: [2])
        tableView.displayGhostContent(options: options,
                                      style: .wooDefaultGhostStyle)
    }

    /// Removes the placeholder cells.
    ///
    func removePlaceholder() {
        tableView.removeGhostContent()
    }

    /// Configures the table view: registers Nibs & setup datasource / delegate
    ///
    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewHeaderSections()
        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewHeaderSections() {
        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    var sections: [Section] {
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

        return cell
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

// MARK: - Private Types
//
extension BulkUpdateViewController {
    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case regularPrice
        case salePrice

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
}
