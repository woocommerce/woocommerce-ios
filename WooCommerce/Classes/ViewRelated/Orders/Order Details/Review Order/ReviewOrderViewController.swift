import UIKit

/// View Control for Review Order screen
/// This screen is shown when Mark Order Complete button is tapped
///
final class ReviewOrderViewController: UIViewController {

    /// View model to provide order info for review
    ///
    private let viewModel: ReviewOrderViewModel
    
    /// Table view to display order details
    ///
    @IBOutlet private var tableView: UITableView!

    init(viewModel: ReviewOrderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
    }

}

// MARK: - UI Configuration
//
private extension ReviewOrderViewController {
    func configureNavigation() {
        title = viewModel.screenTitle
    }

    func configureTableView() {}
}
