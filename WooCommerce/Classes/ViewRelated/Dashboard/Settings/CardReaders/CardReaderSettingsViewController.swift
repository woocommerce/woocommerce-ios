import UIKit
import Combine

final class CardReaderSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var subscriptions = Set<AnyCancellable>()
    private var viewmodel = CardReaderSettingsViewModel()
    private var alert: UIAlertController?

    private lazy var connectView = CardReaderSettingsConnectView()
    private lazy var connectedView = CardReaderSettingsConnectedReaderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        setTableSource()
        setTableFooter()

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
            .store(in: &subscriptions)
        viewmodel.$connectedReader
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectedReader in
                self?.connectedView.connectedReader = connectedReader
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)
    }

    private func setTableSource() {
        switch viewmodel.activeView {
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
        switch self.viewmodel.activeAlert {
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
            self.viewmodel.startSearch()
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
            self.viewmodel.disconnectAndForget()
        }

        for rowType in connectedView.rowTypes() {
            tableView.registerNib(for: rowType)
        }

        connectedView.connectedReader = viewmodel.connectedReader
        tableView.dataSource = connectedView
        tableView.delegate = connectedView
        tableView.reloadData()
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

    private func addFoundReaderModal() {
        // TODO Use FancyAlert instead
        let foundReaderName = self.viewmodel.foundReader?.serialNumber ?? ""
        alert = UIAlertController(
            title: "Found reader",
            message: "Do you want to connect to " + foundReaderName + "?",
            preferredStyle: UIAlertController.Style.alert
        )
        let okAction = UIAlertAction(title: "Connect to Reader", style: .default) { UIAlertAction in
            self.viewmodel.connect()
        }
        alert?.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Keep Searching", style: .cancel) { UIAlertAction in
            self.viewmodel.startSearch()
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
            self.viewmodel.stopConnect()
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
