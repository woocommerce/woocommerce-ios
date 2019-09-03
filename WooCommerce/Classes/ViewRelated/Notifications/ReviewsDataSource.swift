import Foundation
import UIKit
import Yosemite


/// Abstracts the datasource used to render the Product Review list
protocol ReviewsDataSource: UITableViewDataSource, UITableViewDelegate {
    var reviewsResultsController: ResultsController<StorageProductReview> { get }
}
