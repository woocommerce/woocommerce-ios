
import Foundation
import UIKit

/// The view shown in Orders Search if there is no search keyword entered.
///
/// This shows a list of `OrderStatus` that the user can pick to filter Orders by status.
///
final class OrderSearchStarterViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!

    private lazy var viewModel = OrderSearchStarterViewModel()

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        KeyboardFrameObserver(onKeyboardFrameUpdate: handleKeyboardFrameUpdate(keyboardFrame:))
    }()

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        viewModel.activate(using: tableView)
    }

    private func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.delegate = self

        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension OrderSearchStarterViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Not available",
                                                message: "This is still under development.",
                                                preferredStyle: .alert)
        alertController.addActionWithTitle("Fine, I guess", style: .default) { _ in
            tableView.deselectSelectedRowWithAnimation(true)
        }
        present(alertController, animated: true, completion: nil)
    }
}

extension OrderSearchStarterViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        tableView
    }
}
