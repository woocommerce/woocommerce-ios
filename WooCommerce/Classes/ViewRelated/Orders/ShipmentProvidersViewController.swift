import UIKit
import Yosemite

protocol ShipmentProviderListDelegate: AnyObject {
    func shipmentProviderList(_ list: ShipmentProvidersViewController, didSelect: ShipmentTrackingProvider, groupName: String)
}

final class ShipmentProvidersViewController: UIViewController {
    private let viewModel: ShippingProvidersViewModel
    private weak var delegate: ShipmentProviderListDelegate?

    @IBOutlet weak var table: UITableView!


    private lazy var searchController: UISearchController = {
        let returnValue = UISearchController(searchResultsController: nil)
        returnValue.hidesNavigationBarDuringPresentation = false
        returnValue.dimsBackgroundDuringPresentation = false
        returnValue.searchResultsUpdater = self
        returnValue.delegate = self

        return returnValue
    }()

    /// Dedicated NoticePresenter (use this here instead of AppDelegate.shared.noticePresenter)
    ///
    private lazy var noticePresenter: NoticePresenter = {
        let noticePresenter = NoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    /// Deinitializer
    ///
    deinit {
        stopListeningToNotifications()
    }

    init(viewModel: ShippingProvidersViewModel, delegate: ShipmentProviderListDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: type(of: self).nibName, bundle: nil)

        self.configureViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureNavigation()
        configureSearchController()
        configureTable()
        startListeningToNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
}


// MARK: - Configure UI
//
private extension ShipmentProvidersViewController {
    func configureBackground() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureNavigation() {
        configureTitle()
    }

    func configureTitle() {
        title = viewModel.title
    }

    func configureSearchController() {
        searchController.searchBar.textField?.backgroundColor = StyleManager.tableViewBackgroundColor

        guard table.tableHeaderView == nil else {
            return
        }
        table.tableHeaderView = searchController.searchBar
    }

    func configureTable() {
        registerTableViewCells()
        styleTableView()

        table.dataSource = self
        table.delegate = self
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [StatusListTableViewCell.self]

        for cell in cells {
            table.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    func styleTableView() {
        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}


// MARK: - Keyboard management
//
private extension ShipmentProvidersViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    /// Unregisters from the Notification Center
    ///
    func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Executed whenever `UIResponder.keyboardWillShowNotification` note is posted
    ///
    @objc func keyboardWillShow(_ note: Notification) {
        let bottomInset = keyboardHeight(from: note)

        table.contentInset.bottom = bottomInset
        table.scrollIndicatorInsets.bottom = bottomInset
    }

    /// Returns the Keyboard Height from a (hopefully) Keyboard Notification.
    ///
    func keyboardHeight(from note: Notification) -> CGFloat {
        let wrappedRect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? .zero

        return keyboardRect.height
    }
}

// MARK: - View model configuration and binding
//
private extension ShipmentProvidersViewController {
    func configureViewModel() {
        viewModel.onDataLoaded = { [weak self] in
            self?.table.reloadData()
        }

        viewModel.configureResultsController()
    }
}


// MARK: - Conformance to UITableViewDataSource
//
extension ShipmentProvidersViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusListTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? StatusListTableViewCell else {
                                                        fatalError()
        }

        cell.textLabel?.text = viewModel.titleForCellAt(indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeaderInSection(section)
    }
}


// MARK: - Conformance to UITableViewDelegate
//
extension ShipmentProvidersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.isCustom(indexPath: indexPath) {
            addCustomProvider()
            return
        }

        let provider = viewModel.provider(at: indexPath)
        let groupName = viewModel.groupName(at: indexPath)

        delegate?.shipmentProviderList(self, didSelect: provider, groupName: groupName)
    }
}


// MARK: - Search and filtering
//
extension ShipmentProvidersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        resetUIState(searchTerm: searchController.searchBar.text)
    }
}


extension ShipmentProvidersViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        resetUIState(searchTerm: "")
    }
}


// MARK: - Empty state
//
private extension ShipmentProvidersViewController {
    func resetUIState(searchTerm: String?) {
        guard let searchTerm = searchTerm,
            searchTerm.isEmpty == false else {
                viewModel.clearFilters()
                table.reloadData()
                presentEmptyStateIfNecessary()
                return
        }

        viewModel.filter(by: searchTerm)
        table.reloadData()
        presentEmptyStateIfNecessary(term: searchTerm)
    }

    func presentEmptyStateIfNecessary(term: String = "") {
        guard viewModel.isListEmpty else {
            removeEmptyState()
            return
        }

        let emptyState: EmptyListMessageWithActionView = EmptyListMessageWithActionView.instantiateFromNib()
        emptyState.messageText = NSLocalizedString("No results found for \(term)\nAdd a custom provider",
            comment: "Empty state for the list of shipment providers. It reads: 'No results for DHL. Add a custom provider'")
        emptyState.actionText = NSLocalizedString("Custom Provider",
                                                  comment: "Title of button to add a custom tracking provider if filtering the list yields no results."
        )

        emptyState.onAction = { [weak self] in
            self?.addCustomProvider()
        }

        emptyState.attach(to: view)
    }

    func removeEmptyState() {
        for subview in view.subviews where subview is EmptyListMessageWithActionView {
            subview.removeFromSuperview()
        }
    }

    func addCustomProvider() {
        let addCustomTrackingViewModel = AddCustomTrackingViewModel(order: viewModel.order)
        let addCustomTrackingViewController = ManualTrackingViewController(viewModel: addCustomTrackingViewModel)
        navigationController?.pushViewController(addCustomTrackingViewController, animated: true)
    }
}


// MARK: - Private constants
//
private struct Constants {
    static let rowHeight = CGFloat(48)
}
