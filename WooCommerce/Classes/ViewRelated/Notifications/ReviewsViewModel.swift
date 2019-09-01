import Foundation
import UIKit
import WordPressUI


final class ReviewsViewModel {
    private let data = ReviewsDataSource()

    var isEmpty: Bool {
        return data.resultsController.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: UITableViewDelegate {
        return data
    }

    func displayPlaceholderNotes(tableView: UITableView) {
        let options = GhostOptions(reuseIdentifier: NoteTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options)

        data.resultsController.stopForwardingEvents()
    }

    /// Removes Placeholder Notes (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderNotes(tableView: UITableView) {
        tableView.removeGhostContent()
        data.resultsController.startForwardingEvents(to: tableView)
    }

    func configureResultsController(tableView: UITableView) {
        data.resultsController.startForwardingEvents(to: tableView)
        try? data.resultsController.performFetch()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells(tableView: UITableView) {
        let cells = [NoteTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}

private extension ReviewsViewModel {
    enum Settings {
        static let placeholderRowsPerSection = [3]
    }
}
