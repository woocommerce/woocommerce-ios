import UIKit
import Yosemite


// MARK: - RefundDetailsViewController: Displays the details for a given Refund.
//
final class RefundDetailsViewController: UIViewController {

    /// Refund
    ///
    private let refund: Refund

    /// Main TableView.
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Refund to be rendered
    ///
    var viewModel: RefundDetailsViewModel! {
        didSet {
            // reload the table sections and data
        }
    }

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
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpNavigation()
        configureTableView()
    }

    /// Setup: Navigation
    ///
    func setUpNavigation() {
        let refundTitle = NSLocalizedString("Refund #%ld", comment: "It reads: Refund #<refund ID>")
        title = String.localizedStringWithFormat(refundTitle, refund.refundID)
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = viewModel.dataSource
    }
}


// MARK: - Constants
//
extension RefundDetailsViewController {
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
