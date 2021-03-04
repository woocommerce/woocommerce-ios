import UIKit
import Combine
import Yosemite

final class CardReaderSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var subscriptions = Set<AnyCancellable>()
    private var viewModel = CardReaderSettingsViewModel()
    private var alert: UIAlertController?

    private lazy var connectView = CardReaderSettingsConnectView()
    private lazy var connectedView = CardReaderSettingsConnectedReaderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        setTableSource()
        setTableFooter()

        self.viewModel = CardReaderSettingsViewModel()
        viewModel.$activeView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeView in
                self?.setTableSource()
            }
            .store(in: &subscriptions)
        viewModel.$activeAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeAlert in
                self?.setAlert()
            }
            .store(in: &subscriptions)
        viewModel.$connectedReaderViewModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectedReaderViewModel in
                self?.connectedView.viewModel = connectedReaderViewModel
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }

    private func setTableSource() {
        switch viewModel.activeView {
        case .connectYourReader:
            addCleanSlateView()
        case .connectedToReader:
            addConnectedView()
        case .noReaders:
            noop() // TODO. Not yet implemented.
        }
    }

    /// Set the footer to supress unwanted separators on "short" tables.
    private func setTableFooter() {
        tableView.tableFooterView = UIView()
    }

    private func setAlert() {
        alert?.dismiss(animated: true, completion: nil)
        switch viewModel.activeAlert {
        case .none:
            noop()
        case .searching:
            addSearchingModal()
        case .foundReader:
            addFoundReaderModal()
        case .connecting:
            addConnectingToReaderModal()
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
            self.viewModel.startSearch()
        }

        for rowType in connectView.rowTypes() {
            tableView.registerNib(for: rowType)
        }

        tableView.dataSource = connectView
        tableView.delegate = connectView
        tableView.reloadData()
    }

    private func addConnectedView() {
        connectedView.onPressedDisconnect = {
            self.viewModel.disconnectAndForget()
        }

        for rowType in connectedView.rowTypes() {
            tableView.registerNib(for: rowType)
        }

        connectedView.viewModel = viewModel.connectedReaderViewModel
        tableView.dataSource = connectedView
        tableView.delegate = connectedView
        tableView.reloadData()
    }

    private func noop() {
        // TODO cleanup
    }

    private func addSearchingModal() {
        // TODO Use FancyAlert instead - all these strings will be moved there
        alert = UIAlertController(
            title: "Scanning for readers",
            message: "Press the power button of your reader until you see a flashing blue light",
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
            self.viewModel.stopSearch()
        }
        alert?.addAction(cancelAction)
        if alert != nil {
            self.present(alert!, animated: true, completion: nil)
        }
    }

    private func addFoundReaderModal() {
        // TODO Use FancyAlert instead - all these strings will be moved there
        let foundReaderName = viewModel.foundReadersViewModels[0].displayName
        alert = UIAlertController(
            title: "Found reader",
            message: "Do you want to connect to " + foundReaderName + "?",
            preferredStyle: UIAlertController.Style.alert
        )
        let okAction = UIAlertAction(title: "Connect to Reader", style: .default) { UIAlertAction in
            self.viewModel.connect()
        }
        alert?.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Keep Searching", style: .cancel) { UIAlertAction in
            self.viewModel.startSearch()
        }
        alert?.addAction(cancelAction)
        if alert != nil {
            self.present(alert!, animated: true, completion: nil)
        }
    }

    private func addConnectingToReaderModal() {
        // TODO Use FancyAlert instead
        alert = UIAlertController(
            title: "Connecting to reader",
            message: "Please wait",
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
            self.viewModel.stopConnect()
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
