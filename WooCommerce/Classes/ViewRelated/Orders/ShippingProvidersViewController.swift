import UIKit
import Yosemite

final class ShippingProvidersViewController: UIViewController {
    private let viewModel: ShippingProvidersViewModel

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

    init(viewModel: ShippingProvidersViewModel) {
        self.viewModel = viewModel
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
    }
}


// MARK : - Configure UI
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
//        registerTableViewCells()
//        configureSections()

        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
        table.dataSource = self
        table.delegate = self
    }
}



extension ShippingProvidersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }


}

extension ShippingProvidersViewController: UITableViewDelegate {
    
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
