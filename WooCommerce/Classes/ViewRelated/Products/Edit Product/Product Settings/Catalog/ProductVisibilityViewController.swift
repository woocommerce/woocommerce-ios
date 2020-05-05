import UIKit
import Yosemite

final class ProductVisibilityViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!
    
    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}
