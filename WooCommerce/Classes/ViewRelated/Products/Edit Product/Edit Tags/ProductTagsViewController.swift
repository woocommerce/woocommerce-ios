import UIKit
import Yosemite

class ProductTagsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // Completion callback
    //
    typealias Completion = (_ categories: [ProductCategory]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
