
import UIKit

final class EmptyStateViewController: UIViewController {
    
    @IBOutlet var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        messageLabel.applyBodyStyle()
    }
}
