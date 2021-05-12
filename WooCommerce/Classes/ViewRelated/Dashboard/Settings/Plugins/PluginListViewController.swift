import Combine
import UIKit

/// View Controller for the Plugin List Screen.
///
final class PluginListViewController: UIViewController {

    private let viewModel: PluginListViewModel

    @IBOutlet private var tableView: UITableView!

    private var cancellable: AnyCancellable?

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(resyncPlugins), for: .valueChanged)
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
        configureListStates()
        viewModel.activate { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: - UI Configurations
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
                    self.removeErrorStateView()
                    self.tableView.startGhostAnimation(style: .wooDefaultGhostStyle)
                case .results:
                    self.tableView.stopGhostAnimation()
                case .error:
                    self.tableView.stopGhostAnimation()
                    self.displayErrorStateView()
                }
            }
    }
}

// MARK: - Actions
//
private extension PluginListViewController {
    @objc func resyncPlugins() {
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

        NSLayoutConstraint.activate([
            errorStateView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            errorStateView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            errorStateView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            errorStateView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])
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
        let message = NSLocalizedString("Something went wrong",
                                        comment: "The text on the placeholder overlay when there is issue syncing site plugins")
        let details = NSLocalizedString("There was a problem while trying to load plugins. Check your internet and try again.",
                                        comment: "The details on the placeholder overlay when there is issue syncing site plugins")
        let buttonTitle = NSLocalizedString("Try again",
                                            comment: "Action to resync on the placeholder overlay when there is issue syncing site plugins")
        return EmptyStateViewController.Config.withButton(
            message: .init(string: message),
            image: .pluginListError,
            details: details,
            buttonTitle: buttonTitle) { [weak self] button in
            self?.resyncPlugins()
        }
    }
}
