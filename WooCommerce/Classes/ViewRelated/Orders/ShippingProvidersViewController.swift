import UIKit
import Yosemite

protocol ShipmentProviderListDelegate: AnyObject {
    func shipmentProviderList(_ list: ShippingProvidersViewController, didSelect: ShipmentTrackingProvider, groupName: String)
}

final class ShippingProvidersViewController: UIViewController {
    private let viewModel: ShippingProvidersViewModel
    private weak var delegate: ShipmentProviderListDelegate?

    @IBOutlet weak var table: UITableView!

    private lazy var searchController: UISearchController = {
        let returnValue = UISearchController(searchResultsController: nil)
        returnValue.hidesNavigationBarDuringPresentation = false
        returnValue.dimsBackgroundDuringPresentation = false
        returnValue.searchResultsUpdater = self
        returnValue.delegate = self

        returnValue.searchBar.tintColor = .black
        returnValue.searchBar.backgroundColor = .white

        return returnValue
    }()

    init(viewModel: ShippingProvidersViewModel, delegate: ShipmentProviderListDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureSearchController()
        configureTable()
        configureViewModel()
    }
}


// MARK: - Configure UI
//
private extension ShippingProvidersViewController {
    func configureNavigation() {
        configureTitle()
    }

    func configureTitle() {
        title = viewModel.title
    }

    func configureSearchController() {
        guard table.tableHeaderView == nil else {
            return
        }
        table.tableHeaderView = searchController.searchBar
    }

    func configureTable() {
        registerTableViewCells()
        styleTableView()

        table.dataSource = self
        table.delegate = self
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [StatusListTableViewCell.self]

        for cell in cells {
            table.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    func styleTableView() {
        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}


private extension ShippingProvidersViewController {
    func configureViewModel() {
        viewModel.configureResultsController(table: table)
    }
}


extension ShippingProvidersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = viewModel.resultsController.sections[section]
        return group.objects.first?.providers.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusListTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? StatusListTableViewCell else {
                                                        fatalError()
        }

        let group = viewModel.resultsController.sections[indexPath.section]
        let providerName = group.objects.first?.providers[indexPath.item].name ?? ""
        cell.textLabel?.text = providerName

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.resultsController.sections[section].name
    }
}

extension ShippingProvidersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = viewModel.resultsController.sections[indexPath.section]
        guard let provider = group.objects.first?.providers[indexPath.item] else {
            return
        }

        let groupName = viewModel.resultsController.sections[indexPath.section].name

        delegate?.shipmentProviderList(self, didSelect: provider, groupName: groupName)
    }
}

extension ShippingProvidersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        //
    }
}


extension ShippingProvidersViewController: UISearchControllerDelegate {

}


private struct Constants {
    static let rowHeight = CGFloat(48)
}
