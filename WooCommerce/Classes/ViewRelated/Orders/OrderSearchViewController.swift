import Foundation
import UIKit


/// OrderSearchViewController: Displays the "Search Orders" Interface
///
class OrderSearchViewController: UIViewController {

    /// Main SearchBar
    ///
    @IBOutlet var searchBar: UISearchBar!

    /// Dismiss Action
    ///
    @IBOutlet var cancelButton: UIButton!

    /// TableView
    ///
    @IBOutlet var tableView: UITableView!



    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        configureSearchBar()
        configureActions()

        registerTableViewCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
        searchBar.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}


// MARK: - User Interface Initialization
//
private extension OrderSearchViewController {

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: Search Bar
    ///
    func configureSearchBar() {
        searchBar.placeholder = NSLocalizedString("Search all orders", comment: "Orders Search Placeholder")
        searchBar.tintColor = .black
    }

    /// Setup: Actions
    ///
    func configureActions() {
        let title = NSLocalizedString("Cancel", comment: "")
        cancelButton.setTitle(title, for: .normal)
        cancelButton.titleLabel?.font = UIFont.body
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [ OrderTableViewCell.self ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - UISearchBarDelegate Conformance
//
extension OrderSearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // TODO: Wire Me!
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}


// MARK: - Actions
//
extension OrderSearchViewController {

    @IBAction func dismissWasPressed() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
}
