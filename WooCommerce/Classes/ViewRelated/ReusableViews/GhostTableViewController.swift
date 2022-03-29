import UIKit
import WordPressUI

/// This struct encapsulates the necessary data to configure an instance of `GhostTableViewController`
struct GhostTableViewOptions {
    fileprivate let ghostOptions: GhostOptions
    fileprivate let estimatedRowHeight: CGFloat
    fileprivate let cellClass: UITableViewCell.Type
    fileprivate let tableViewStyle: UITableView.Style

    init(displaysSectionHeader: Bool = true,
         cellClass: UITableViewCell.Type,
         rowsPerSection: [Int] = [3],
         estimatedRowHeight: CGFloat = 44,
         tableViewStyle: UITableView.Style = .plain) {
        // By just passing the cellClass in the initializer we enforce that the GhostOptions reuseIdentifier is always that of the cellClass
        ghostOptions = GhostOptions(displaysSectionHeader: displaysSectionHeader, reuseIdentifier: cellClass.reuseIdentifier, rowsPerSection: rowsPerSection)
        self.estimatedRowHeight = estimatedRowHeight
        self.cellClass = cellClass
        self.tableViewStyle = tableViewStyle
    }
}

/// A view controller to display ghost animation over a table view
///
final class GhostTableViewController: UITableViewController {
    private let options: GhostTableViewOptions

    init(options: GhostTableViewOptions) {
        self.options = options
        super.init(style: options.tableViewStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make sure that Ghost will not have any dataSource or delegate to _swap_. This is
        // just to reduce the chance of having ”invalid number of rows” crashes because of
        // delegate swapping.
        tableView.dataSource = nil
        tableView.delegate = nil

        tableView.backgroundColor = UIColor.basicBackground
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = options.estimatedRowHeight
        tableView.applyFooterViewForHidingExtraRowPlaceholders()
        tableView.registerNib(for: options.cellClass)
    }

    /// Activate the ghost if this view is added to the parent.
    ///
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.displayGhostContent(options: options.ghostOptions,
                                      style: .wooDefaultGhostStyle)
    }

    /// Deactivate the ghost if this view is removed from the parent.
    ///
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.removeGhostContent()
    }
}
