import Combine
import UIKit

class PluginListViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!

    private let viewModel: PluginListViewModel

    private var cancellable: AnyCancellable?

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    init?(coder: NSCoder, viewModel: PluginListViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("⛔️ You must create this view controller with a view model!")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        configureListStates()
        viewModel.activate()
    }
}

// MARK: - UI configurations
//
private extension PluginListViewController {
    func configureNavigation() {
        title = NSLocalizedString("Plugins", comment: "Title of the Plugin List screen")
    }

    func configureTableView() {
        tableView.registerNib(for: PluginTableViewCell.self)
        tableView.estimatedRowHeight = CGFloat(44)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.addSubview(refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
    }

    func configureListStates() {
        cancellable = viewModel.$pluginListState
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .syncing:
                    self.tableView.startGhostAnimation(style: .wooDefaultGhostStyle)
                case .results:
                    self.tableView.stopGhostAnimation()
                    self.tableView.reloadData()
                case .error:
                    // TODO: show error state
                    self.tableView.stopGhostAnimation()
                }
            }
    }
}

// MARK: - Actions
//
private extension PluginListViewController {
    @objc
    func pullToRefresh() {
        viewModel.resyncPlugins { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}

// MARK: - UITableViewDataSource conformance
//
extension PluginListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(inSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PluginTableViewCell.self, for: indexPath)
        let cellModel = viewModel.cellModelForRow(at: indexPath)
        cell.update(viewModel: cellModel)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.titleForSection(at: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITableViewDelegate conformance
//
extension PluginListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
