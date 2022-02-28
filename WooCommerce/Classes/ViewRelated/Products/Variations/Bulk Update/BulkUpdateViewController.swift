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

    /// A child view controller that is shown when `displayGhostContent()` is called.
    ///
    private lazy var ghostTableViewController = GhostTableViewController()

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
            // `.notStarted` is the initial state of the VM
            // and transition to this state is not possible
            case .notStarted:
                ()
            case .syncing:
                self.displayGhostContent()
            case .synced, .error:
                self.removeGhostContent()
            }
        }.store(in: &subscriptions)

        viewModel.activate()
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

private extension BulkUpdateViewController {
    /// Renders the Placeholder Content.
    ///
    func displayGhostContent() {
        guard let ghostView = ghostTableViewController.view else {
            return
        }

        ghostView.translatesAutoresizingMaskIntoConstraints = false
        addChild(ghostTableViewController)
        view.addSubview(ghostView)
        view.pinSubviewToAllEdges(ghostView)
        ghostTableViewController.didMove(toParent: self)
    }

    /// Removes the Placeholder Content.
    ///
    func removeGhostContent() {
        guard let ghostView = ghostTableViewController.view else {
            return
        }

        ghostTableViewController.willMove(toParent: nil)
        ghostView.removeFromSuperview()
        ghostTableViewController.removeFromParent()
    }

    /// A  controller that is shown when `displayGhostContent()` is called. Added as a child view controller.
    ///
    final class GhostTableViewController: UITableViewController {

        init() {
            super.init(style: .plain)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            tableView.dataSource = nil
            tableView.delegate = nil

            tableView.backgroundColor = .listBackground
            tableView.estimatedRowHeight = Constants.sectionHeight
            tableView.applyFooterViewForHidingExtraRowPlaceholders()
            tableView.registerNib(for: ValueOneTableViewCell.self)
        }

        /// Activate the ghost if this view is added to the parent.
        ///
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            let options = GhostOptions(reuseIdentifier: ValueOneTableViewCell.reuseIdentifier,
                                       rowsPerSection: Constants.placeholderRowsPerSection)
            tableView.displayGhostContent(options: options,
                                          style: .wooDefaultGhostStyle)
        }

        /// Deactivate the ghost if this view is removed from the parent.
        ///
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            tableView.removeGhostContent()
        }
    }
}
