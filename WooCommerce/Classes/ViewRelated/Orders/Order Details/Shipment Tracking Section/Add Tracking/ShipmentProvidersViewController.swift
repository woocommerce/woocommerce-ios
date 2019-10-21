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

    /// Dedicated NoticePresenter (use this here instead of ServiceLocator.noticePresenter)
    ///
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    /// Footer spinner shown when loading data for the first time
    ///
    private lazy var footerSpinnerView = {
        return FooterSpinnerView(tableViewStyle: table.style)
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
        fetchGroups()
        startListeningToNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
}


// MARK: - Fetch data
//
extension ShipmentProvidersViewController {
    /// Loads shipment tracking groups
    ///
    fileprivate func fetchGroups() {
        footerSpinnerView.startAnimating()
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let orderID = viewModel.order.orderID

        let loadGroupsAction = ShipmentAction.synchronizeShipmentTrackingProviders(
            siteID: siteID,
            orderID: orderID
        ) { [weak self] error in
            if let error = error {
                self?.presentNotice(error)
            }
            ServiceLocator.analytics.track(.orderTrackingProvidersLoaded)
            self?.footerSpinnerView.stopAnimating()
        }

        ServiceLocator.stores.dispatch(loadGroupsAction)
    }
}


// MARK: - Configure UI
//
extension ShipmentProvidersViewController {
    fileprivate func configureBackground() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    fileprivate func configureNavigation() {
        configureTitle()
    }

    fileprivate func configureTitle() {
        title = viewModel.title
    }

    fileprivate func configureSearchController() {
        searchController.searchBar.textField?.backgroundColor = StyleManager.tableViewBackgroundColor

        guard table.tableHeaderView == nil else {
            return
        }
        table.tableHeaderView = searchController.searchBar
    }

    fileprivate func configureTable() {
        registerTableViewCells()
        styleTableView()

        if viewModel.isListEmpty {
            table.tableFooterView = footerSpinnerView
        }

        table.dataSource = self
        table.delegate = self
    }

    /// Registers all of the available TableViewCells
    ///
    fileprivate func registerTableViewCells() {
        let cells = [StatusListTableViewCell.self]

        for cell in cells {
            table.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    fileprivate func styleTableView() {
        table.estimatedRowHeight = Constants.rowHeight
        table.rowHeight = UITableView.automaticDimension
        table.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}


// MARK: - Keyboard management
//
extension ShipmentProvidersViewController {
    /// Registers for all of the related Notifications
    ///
    fileprivate func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Unregisters from the Notification Center
    ///
    fileprivate func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc

    /// Executed whenever `UIResponder.keyboardWillShowNotification` note is posted
    ///
    fileprivate func keyboardWillShow(_ note: Notification) {
        let bottomInset = keyboardHeight(from: note)

        table.contentInset.bottom = bottomInset
        table.scrollIndicatorInsets.bottom = bottomInset
    }

    @objc

    /// Executed whenever `UIResponder.keyboardWillhideNotification` note is posted
    ///
    fileprivate func keyboardWillHide(_ note: Notification) {
        table.contentInset.bottom = .zero
        table.scrollIndicatorInsets.bottom = .zero
    }

    /// Returns the Keyboard Height from a (hopefully) Keyboard Notification.
    ///
    fileprivate func keyboardHeight(from note: Notification) -> CGFloat {
        let wrappedRect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let keyboardRect = wrappedRect?.cgRectValue ?? .zero

        return keyboardRect.height
    }
}

// MARK: - View model configuration and binding
//
extension ShipmentProvidersViewController {
    fileprivate func configureViewModel() {
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
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: StatusListTableViewCell.reuseIdentifier,
                for: indexPath) as? StatusListTableViewCell
        else {
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

        guard let provider = viewModel.provider(at: indexPath),
            let groupName = viewModel.groupName(at: indexPath)
        else {
            return
        }

        delegate?.shipmentProviderList(self, didSelect: provider, groupName: groupName)

        navigationController?.popViewController(animated: true)
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


// MARK: - Error handling
//
extension ShipmentProvidersViewController {
    fileprivate func presentNotice(_ error: Error) {
        let title = NSLocalizedString(
            "Unable to load Shipment Providers",
            comment: "Content of error presented when loading the list of shipment providers failed. It reads: Unable to load Shipment Providers"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(
            title: title,
            message: nil,
            feedbackType: .error,
            actionTitle: actionTitle
        ) { [weak self] in
            self?.fetchGroups()
        }

        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Empty state
//
extension ShipmentProvidersViewController {
    fileprivate func resetUIState(searchTerm: String?) {
        guard let searchTerm = searchTerm,
            searchTerm.isEmpty == false
        else {
            viewModel.clearFilters()
            table.reloadData()
            presentEmptyStateIfNecessary()
            return
        }

        viewModel.filter(by: searchTerm)
        table.reloadData()
        presentEmptyStateIfNecessary(term: searchTerm)
    }

    fileprivate func presentEmptyStateIfNecessary(term: String = "") {
        guard viewModel.isListEmpty else {
            removeEmptyState()
            return
        }

        let emptyState: EmptyListMessageWithActionView = EmptyListMessageWithActionView.instantiateFromNib()
        emptyState.messageText = NSLocalizedString(
            "No results found for \(term)\nAdd a custom provider",
            comment: "Empty state for the list of shipment providers. It reads: 'No results for DHL. Add a custom provider'")
        emptyState.actionText = NSLocalizedString(
            "Custom Provider",
            comment: "Title of button to add a custom tracking provider if filtering the list yields no results."
        )

        emptyState.onAction = { [weak self] in
            self?.addCustomProvider()
        }

        emptyState.attach(to: view)
    }

    fileprivate func removeEmptyState() {
        for subview in view.subviews where subview is EmptyListMessageWithActionView {
            subview.removeFromSuperview()
        }
    }

    fileprivate func addCustomProvider() {
        ServiceLocator.analytics.track(.orderShipmentTrackingCustomProviderSelected)

        let initialCustomProviderName = searchController.searchBar.text
        let addCustomTrackingViewModel = AddCustomTrackingViewModel(
            order: viewModel.order,
            initialName: initialCustomProviderName)
        let addCustomTrackingViewController = ManualTrackingViewController(viewModel: addCustomTrackingViewModel)
        navigationController?.pushViewController(addCustomTrackingViewController, animated: true)
    }
}


// MARK: - Private constants
//
private enum Constants {
    static let rowHeight = CGFloat(48)
}
