import UIKit
import Yosemite

final class ProductSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    init(product: Product) {
        // TODO: implement init with view model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
