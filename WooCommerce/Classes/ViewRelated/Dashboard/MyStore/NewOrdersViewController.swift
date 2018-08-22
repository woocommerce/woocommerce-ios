import UIKit
import Yosemite
import CocoaLumberjack


class NewOrdersViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var bottomBorder: UIView!
    
    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
}


// MARK: - Public Interface
//
extension NewOrdersViewController {

    func syncNewOrders() {
        // TODO: grab data here!
    }
}


// MARK: - User Interface Configuration
//
private extension NewOrdersViewController {

    func configureView() {
        view.backgroundColor = StyleManager.wooWhite
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
    }
}
