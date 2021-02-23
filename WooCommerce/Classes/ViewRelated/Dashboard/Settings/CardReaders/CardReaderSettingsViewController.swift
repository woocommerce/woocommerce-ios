import UIKit
import Combine

final class CardReaderSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var subscriptions = Set<AnyCancellable>()
    private var viewmodel = CardReaderSettingsViewModel()
    private var alert: UIAlertController?

    private lazy var connectView = CardReaderSettingsConnectView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()

        setTableSource()

        self.viewmodel = CardReaderSettingsViewModel()
        viewmodel.$activeView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeView in
                self?.setTableSource()
            }
            .store(in: &subscriptions)
        viewmodel.$activeAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeAlert in
                self?.setAlert()
            }
            .store(in: &subscriptions)    }

    private func setTableSource() {
        alert?.dismiss(animated: true, completion: nil)

        switch self.viewmodel.activeView {
        case .connectYourReader:
            addCleanSlateView()
        case .manageYourReader:
            addListView()
        case .noReaderFound:
            addListView()
        }
    }

    private func setAlert() {
        switch self.viewmodel.activeAlert {
        case .none:
            noop()
        case .searching:
            addSearchingModal()
        case .foundReader:
            noop()
        case .connecting:
            noop()
        case .tutorial:
            noop()
        case .updateAvailable:
            noop()
        case .updateRequired:
            noop()
        case .updating:
            noop()
        }
    }

    private func addCleanSlateView() {
        connectView.onPressedConnect = {
            self.viewmodel.startSearch()
        }
        tableView.registerNib(for: BasicTableViewCell.self) // TODO move into connect
        tableView.registerNib(for: ButtonTableViewCell.self) // TODO move into connect
        tableView.dataSource = connectView
        tableView.delegate = connectView
        tableView.reloadData()
    }

    private func addListView() {
        // TODO Implement
    }

    private func noop() {
        // TODO cleanup
    }

    private func addSearchingModal() {
        // TODO Use FancyAlert instead
        alert = UIAlertController(
            title: "Scanning for readers",
            message: "Press the power button of your reader until you see a flashing blue light",
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
            self.viewmodel.stopSearch()
        }
        alert?.addAction(cancelAction)
        if alert != nil {
            self.present(alert!, animated: true, completion: nil)
        }
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsViewController {

    func configureNavigation() {
        title = NSLocalizedString("Card Readers", comment: "Card reader settings screen title")

        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }
}
