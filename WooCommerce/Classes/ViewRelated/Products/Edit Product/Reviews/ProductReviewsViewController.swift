import UIKit
import Yosemite

/// The UI that shows the approved Reviews related to a specific product.
final class ProductReviewsViewController: UIViewController {

    private let product: Product

    @IBOutlet private weak var tableView: UITableView!
    
    init(product: Product) {
        self.product = product
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
