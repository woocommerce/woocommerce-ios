import UIKit

class PluginListViewController: UIViewController {

    private let viewModel: PluginListViewModel

    @IBOutlet private var tableView: UITableView!
    
    init?(coder: NSCoder, viewModel: PluginListViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("⛔️ You must create this view controller with a view model!")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
