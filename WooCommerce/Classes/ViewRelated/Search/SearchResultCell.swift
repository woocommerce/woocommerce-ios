import UIKit

/// A search result table view cell that can be configured with a generic search model.
protocol SearchResultCell {
    associatedtype SearchModel

    static func register(for tableView: UITableView)
    func configureCell(searchModel: SearchModel)
}
