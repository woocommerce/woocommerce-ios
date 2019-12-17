import UIKit
import Yosemite

class ProductEditPriceSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let product: Product
    
    init(product: Product) {
        self.product = product

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }


}
