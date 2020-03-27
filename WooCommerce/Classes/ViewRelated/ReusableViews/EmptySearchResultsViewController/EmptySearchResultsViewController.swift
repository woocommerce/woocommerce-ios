
import UIKit

/// Shows a view with a message and a standard empty search results image.
///
/// This is generally used with `SearchUICommand`.
///
final class EmptySearchResultsViewController: UIViewController {
    
    @IBOutlet private var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        messageLabel.applyBodyStyle()
    }
}
