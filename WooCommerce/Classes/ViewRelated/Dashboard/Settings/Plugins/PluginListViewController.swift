import UIKit

/// View Controller for the Plugin List Screen.
///
final class PluginListViewController: UIViewController {

    private let viewModel: PluginListViewModel

    init(viewModel: PluginListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
