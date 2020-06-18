import UIKit

/// AddProductCategoryViewController: Add a new category associated to the active Account.
///
final class AddProductCategoryViewController: UIViewController {

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
