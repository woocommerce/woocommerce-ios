import UIKit

/// View Controller for the Plugin List Screen.
///
final class PluginListViewController: UIViewController {

    private let viewModel: PluginListViewModel

    @IBOutlet private var tableView: UITableView!

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
        configureViewModel()
    }
}

// MARK: - UI Configurations
private extension PluginListViewController {
    func configureNavigation() {
        title = NSLocalizedString("Plugins", comment: "Title of the Plugin List screen")
    }

    func configureTableView() {
        tableView.registerNib(for: HeadlineLabelTableViewCell.self)
        tableView.estimatedRowHeight = CGFloat(44)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.allowsSelection = false
        tableView.dataSource = self
    }

    func configureViewModel() {
        viewModel.observePlugins { [weak self] in
            self?.tableView.reloadData()
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
        cell.update(style: .bodyWithLineLimit(count: 2),
                    headline: cellModel.name,
                    body: cellModel.description)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.titleForSection(at: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
