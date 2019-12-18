import UIKit
import Yosemite


// MARK: - RefundDetailsViewController: Displays the details for a given Refund.
//
class RefundDetailsViewController: UIViewController {

    /// Refund
    ///
    private let refund: Refund


    /// Designated Initializer
    ///
    init(refund: Refund) {
        self.refund = refund
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

     /// NSCoder Conformance
     ///
     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) is not supported")
     }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpNavigation()
    }

    func setUpNavigation() {
        let refundTitle = NSLocalizedString("Refund #%ld", comment: "It reads: Refund #<refund ID>")
        title = String.localizedStringWithFormat(refundTitle, refund.refundID)
    }
}
