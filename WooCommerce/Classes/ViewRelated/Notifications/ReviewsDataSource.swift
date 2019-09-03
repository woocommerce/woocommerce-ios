import Foundation
import UIKit
import Yosemite


/// Abstracts the datasource used to render the Product Review list
protocol ReviewsDataSource: UITableViewDataSource, UITableViewDelegate {
    var isEmpty: Bool { get }
    var reviewsProductsIDs: [Int] { get }

    func stopForwardingEvents()
    func startForwardingEvents(to tableView: UITableView)

    func fetchReviews() throws
}
