import UIKit
import WordPressUI

enum GhostTableViewSectionHeaderVerticalSpace {
    case none
    case medium
    case large
}

/// This struct encapsulates the necessary data to configure an instance of `GhostTableViewController`
struct GhostTableViewOptions {
    fileprivate let ghostOptions: GhostOptions
    fileprivate let sectionHeaderVerticalSpace: GhostTableViewSectionHeaderVerticalSpace
    fileprivate let estimatedRowHeight: CGFloat
    fileprivate let cellClass: UITableViewCell.Type
    fileprivate let tableViewStyle: UITableView.Style
    fileprivate let backgroundColor: UIColor
    fileprivate let separatorStyle: UITableViewCell.SeparatorStyle
    fileprivate let isScrollEnabled: Bool

    init(sectionHeaderVerticalSpace: GhostTableViewSectionHeaderVerticalSpace = .large,
         cellClass: UITableViewCell.Type,
         rowsPerSection: [Int] = [3],
         estimatedRowHeight: CGFloat = 44,
         tableViewStyle: UITableView.Style = .plain,
         backgroundColor: UIColor = .listBackground,
         separatorStyle: UITableViewCell.SeparatorStyle = .singleLine,
         isScrollEnabled: Bool = true) {
        // By just passing the cellClass in the initializer we enforce that the GhostOptions reuseIdentifier is always that of the cellClass
        ghostOptions = GhostOptions(displaysSectionHeader: sectionHeaderVerticalSpace != .none,
                                    reuseIdentifier: cellClass.reuseIdentifier,
                                    rowsPerSection: rowsPerSection)
        self.sectionHeaderVerticalSpace = sectionHeaderVerticalSpace
        self.estimatedRowHeight = estimatedRowHeight
        self.cellClass = cellClass
        self.tableViewStyle = tableViewStyle
        self.backgroundColor = backgroundColor
        self.separatorStyle = separatorStyle
        self.isScrollEnabled = isScrollEnabled
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

        tableView.backgroundColor = options.backgroundColor
        tableView.separatorStyle = options.separatorStyle
        tableView.estimatedRowHeight = options.estimatedRowHeight
        tableView.isScrollEnabled = options.isScrollEnabled
        tableView.applyFooterViewForHidingExtraRowPlaceholders()
        registerCellClass()
        configureSectionHeaderHeight()
    }

    private func registerCellClass() {
        options.cellClass.nibExistsInMainBundle() ? tableView.registerNib(for: options.cellClass) : tableView.register(options.cellClass)
    }

    private func configureSectionHeaderHeight() {
        if options.sectionHeaderVerticalSpace == .medium {
            // WordPressUI uses `titleForHeaderInSection` in `GhostTableViewHandler` returning an empty string to render the section header.
            // This however creates a large heighted section. By setting the header height to 0 we decrease the size
            // thus showing a medium vertical space size
            tableView.estimatedSectionHeaderHeight = 0
            tableView.sectionHeaderHeight = 0
        }
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
