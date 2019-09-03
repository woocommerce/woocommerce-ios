import Foundation
import UIKit
import Yosemite


protocol ReviewsDataSource: UITableViewDataSource, UITableViewDelegate {
    var reviewsResultsController: ResultsController<StorageProductReview> { get }
}
