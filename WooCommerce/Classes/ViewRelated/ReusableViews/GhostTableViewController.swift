import UIKit
import WordPressUI

/// A view controller to display ghost animation over a table view
///
final class GhostTableViewController: UITableViewController {

    /// Cell class for the table view cells
    private let cellClass: UITableViewCell.Type

    init(cellClass: UITableViewCell.Type = WooBasicTableViewCell.self) {
        self.cellClass = cellClass
        super.init(style: .plain)
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
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.applyFooterViewForHidingExtraRowPlaceholders()
        tableView.registerNib(for: cellClass)
    }

    /// Activate the ghost if this view is added to the parent.
    ///
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: cellClass.reuseIdentifier,
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

    private enum Constants {
        static let estimatedRowHeight = CGFloat(80)
        static let placeholderRowsPerSection = [3]
    }
}
