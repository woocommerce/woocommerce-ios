import UIKit
import WordPressUI

/// View Controller for the Plugin List Screen.
///
final class PluginListViewController: UIViewController {

    private let viewModel: PluginListViewModel

    @IBOutlet private var tableView: UITableView!

    /// Separate table view for ghost animation.
    ///
    private let ghostTableView = UITableView(frame: .zero, style: .grouped)

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(syncPlugins), for: .valueChanged)
        return refreshControl
    }()

    /// View Controller to display error state.
    ///
    private lazy var errorStateViewController = EmptyStateViewController(style: .basic)

    /// Configurations for the error state view.
    ///
    private lazy var errorStateViewConfig = createErrorStateViewConfig()

    init(viewModel: PluginListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        configureGhostTableView()
        configureViewModel()
    }
}

// MARK: - UI Configurations
private extension PluginListViewController {
    func configureNavigation() {
        title = viewModel.pluginListTitle
    }

    func configureTableView() {
        tableView.registerNib(for: HeadlineLabelTableViewCell.self)
        tableView.estimatedRowHeight = CGFloat(44)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.addSubview(refreshControl)
        tableView.allowsSelection = false
        tableView.dataSource = self
    }

    func configureGhostTableView() {
        ghostTableView.registerNib(for: HeadlineLabelTableViewCell.self)
        ghostTableView.translatesAutoresizingMaskIntoConstraints = false
        ghostTableView.backgroundColor = .listBackground
        ghostTableView.isScrollEnabled = false
        ghostTableView.isHidden = true

        view.addSubview(ghostTableView)
        view.pinSubviewToAllEdges(ghostTableView)
    }

    func startGhostAnimation() {
        let options = GhostOptions(reuseIdentifier: HeadlineLabelTableViewCell.reuseIdentifier, rowsPerSection: [10])
        ghostTableView.displayGhostContent(options: options, style: .wooDefaultGhostStyle)
        ghostTableView.startGhostAnimation()
        ghostTableView.isHidden = false
    }

    func stopGhostAnimation() {
        ghostTableView.isHidden = true
        ghostTableView.stopGhostAnimation()
        ghostTableView.removeGhostContent()
    }

    func configureViewModel() {
        viewModel.observePlugins { [weak self] in
            self?.tableView.reloadData()
        }

        syncPlugins()
    }
}

// MARK: - Actions
//
private extension PluginListViewController {

    /// syncPlugins synchronizes all plugins
    ///
    @objc func syncPlugins() {
        removeErrorStateView()
        if viewModel.numberOfSections == 0 {
            startGhostAnimation()
        }
        viewModel.syncPlugins { [weak self] result in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            self.stopGhostAnimation()
            if result.isFailure {
                self.displayErrorStateView()
            }
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
        let cell = tableView.dequeueReusableCell(HeadlineLabelTableViewCell.self, for: indexPath)
        let cellModel = viewModel.cellModelForRow(at: indexPath)
        cell.update(style: .bodyWithLineLimit(count: 2), headline: cellModel.name, body: cellModel.description)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.titleForSection(at: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Error state configuration
//
private extension PluginListViewController {
    /// Displays the overlay when there is issue syncing site plugins.
    ///
    func displayErrorStateView() {
        guard let errorStateView = errorStateViewController.view else {
            return
        }
        errorStateViewController.configure(errorStateViewConfig)
        addChild(errorStateViewController)

        errorStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorStateView)
        view.pinSubviewToAllEdges(errorStateView)
        errorStateViewController.didMove(toParent: self)
    }

    /// Removes `errorStateViewController` child view controller if applicable.
    ///
    func removeErrorStateView() {
        guard errorStateViewController.parent == self else {
            return
        }
        errorStateViewController.willMove(toParent: nil)
        errorStateViewController.view.removeFromSuperview()
        errorStateViewController.removeFromParent()
    }

    /// Creates configurations for the error state view.
    ///
    private func createErrorStateViewConfig() -> EmptyStateViewController.Config {
        let message = viewModel.errorStateMessage
        let details = viewModel.errorStateDetails
        let buttonTitle = viewModel.errorStateActionTitle
        return EmptyStateViewController.Config.withButton(
            message: .init(string: message),
            image: .pluginListError,
            details: details,
            buttonTitle: buttonTitle) { [weak self] button in
            self?.syncPlugins()
        }
    }
}
